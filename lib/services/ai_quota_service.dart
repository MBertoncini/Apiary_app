// lib/services/ai_quota_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Funzionalità AI tracciate dalla quota centralizzata.
enum AiFeature { chat, voice, stats }

extension AiFeatureLabel on AiFeature {
  String get apiKey {
    switch (this) {
      case AiFeature.chat:
        return 'chat';
      case AiFeature.voice:
        return 'voice';
      case AiFeature.stats:
        return 'stats';
    }
  }
}

/// Stato di blocco per una feature.
enum AiQuotaBlock {
  /// Feature utilizzabile.
  ok,

  /// Chiamate esaurite per quota tier giornaliera.
  exceeded,

  /// Il pool condiviso di sistema è esaurito (solo stats quando non c'è la
  /// chiave Groq personale).
  systemExhausted,
}

/// Servizio centralizzato di quota AI.
///
/// Unica fonte di verità per limiti, utilizzo, reset e blocchi per chat,
/// voice (Gemini) e stats (Groq / NL query). I singoli service (ChatService,
/// GeminiAudioProcessor, GeminiDataProcessor, StatisticheService) devono:
///
/// 1. Chiamare [canCall] PRIMA di emettere la richiesta.
/// 2. Chiamare [recordOptimisticCall] dopo un 200 OK (se il backend non
///    ritorna già i counter aggiornati) per dare feedback immediato in UI.
/// 3. Chiamare [markExceeded] quando il server risponde 429.
/// 4. Chiamare [refresh] periodicamente e dopo azioni critiche per
///    riallineare ai valori autoritativi del backend.
class AiQuotaService extends ChangeNotifier {
  final ApiService _apiService;

  AiQuotaService(this._apiService);

  Map<String, dynamic>? _quotaData;
  DateTime? _lastFetchAt;
  bool _isLoading = false;
  String? _lastError;

  AiTier _tier = AiTier.free;
  bool _hasPersonalGroqKey = false;

  final Map<AiFeature, int> _optimistic = {
    AiFeature.chat: 0,
    AiFeature.voice: 0,
    AiFeature.stats: 0,
  };

  final Map<AiFeature, DateTime> _markedExceededAt = {};
  Timer? _resetTimer;
  Future<void>? _inFlightRefresh;

  // ── Getters ────────────────────────────────────────────────────────────────

  Map<String, dynamic>? get rawData => _quotaData;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  DateTime? get lastFetchAt => _lastFetchAt;
  AiTier get tier => _tier;
  bool get hasPersonalGroqKey => _hasPersonalGroqKey;

  /// Mappa backend dei limiti per tutti i tier, se disponibile.
  Map<String, dynamic>? get allTierLimits =>
      _quotaData?['all_tier_limits'] as Map<String, dynamic>?;

  /// Chiave attiva riportata dal backend: "personal" se l'utente ha una
  /// chiave Gemini personale, altrimenti "system".
  String get activeKey =>
      (_quotaData?['active_key'] as String?) ?? 'system';

  // ── Configurazione runtime ────────────────────────────────────────────────

  /// Aggiorna il tier corrente (letto da AuthService.currentUser.aiTier).
  /// Va chiamato dopo login e dopo ogni refresh del profilo utente.
  void setTier(AiTier tier) {
    if (_tier == tier) return;
    _tier = tier;
    // Un cambio di tier invalida i mark di superamento (tipicamente
    // un upgrade sblocca immediatamente le feature).
    _markedExceededAt.clear();
    notifyListeners();
  }

  /// Segnala se l'utente ha configurato una chiave Groq personale.
  /// Quando true, la feature [AiFeature.stats] non è bloccata dall'esaurimento
  /// del pool di sistema.
  void setHasPersonalGroqKey(bool value) {
    if (_hasPersonalGroqKey == value) return;
    _hasPersonalGroqKey = value;
    if (value) {
      _markedExceededAt.remove(AiFeature.stats);
    }
    notifyListeners();
  }

  // ── Limiti ────────────────────────────────────────────────────────────────

  /// Limite giornaliero per una feature, risolto dal backend con fallback
  /// all'enum [AiTier]. Ritorna 0 se la feature non ha un limite per tier
  /// (caso attuale di [AiFeature.stats]).
  int limitFor(AiFeature feature) {
    final limits = _tier.resolvedLimits(allTierLimits);
    switch (feature) {
      case AiFeature.chat:
        return limits.chat;
      case AiFeature.voice:
        return limits.voice;
      case AiFeature.stats:
        // Nessun limite per-tier definito dal backend: gestito via system pool.
        return 0;
    }
  }

  /// Limite totale combinato chat+voice (visualizzato nel riepilogo).
  int get totalLimit => _tier.resolvedLimits(allTierLimits).total;

  // ── Utilizzo ──────────────────────────────────────────────────────────────

  /// Utilizzo per feature = utilizzo backend + incremento ottimistico locale.
  int usedFor(AiFeature feature) {
    final usage = _quotaData?['usage'] as Map?;
    int backend = 0;
    if (usage != null) {
      switch (feature) {
        case AiFeature.chat:
          backend = _intFrom(usage['chat_today']);
          break;
        case AiFeature.voice:
          backend = _intFrom(usage['voice_today']);
          break;
        case AiFeature.stats:
          backend = _intFrom(usage['stats_today']);
          break;
      }
    }
    return backend + (_optimistic[feature] ?? 0);
  }

  int get totalUsed {
    final usage = _quotaData?['usage'] as Map?;
    final backend =
        usage != null ? _intFrom(usage['total_today']) : 0;
    return backend +
        (_optimistic[AiFeature.chat] ?? 0) +
        (_optimistic[AiFeature.voice] ?? 0);
  }

  int remainingFor(AiFeature feature) {
    final limit = limitFor(feature);
    if (limit <= 0) return -1; // illimitato/non applicabile
    return (limit - usedFor(feature)).clamp(0, limit);
  }

  // ── Gating ────────────────────────────────────────────────────────────────

  /// Ritorna lo stato di blocco per una feature.
  AiQuotaBlock blockStatus(AiFeature feature) {
    // Scade automaticamente il mark se abbiamo superato il reset_at.
    _pruneExceededIfReset(feature);

    if (_markedExceededAt.containsKey(feature)) {
      return AiQuotaBlock.exceeded;
    }

    final limit = limitFor(feature);
    if (limit > 0 && usedFor(feature) >= limit) {
      return AiQuotaBlock.exceeded;
    }

    if (feature == AiFeature.stats && !_hasPersonalGroqKey) {
      final system = _quotaData?['system'] as Map?;
      if (system != null) {
        final requestsToday = _intFrom(system['requests_today']);
        final dailyLimit = _intFrom(_quotaData?['daily_limit']);
        if (dailyLimit > 0 && requestsToday >= dailyLimit) {
          return AiQuotaBlock.systemExhausted;
        }
      }
    }

    return AiQuotaBlock.ok;
  }

  /// True se la feature è attualmente chiamabile.
  bool canCall(AiFeature feature) => blockStatus(feature) == AiQuotaBlock.ok;

  bool get isAnyExceeded =>
      AiFeature.values.any((f) => blockStatus(f) != AiQuotaBlock.ok);

  Set<AiFeature> get exceededFeatures => AiFeature.values
      .where((f) => blockStatus(f) != AiQuotaBlock.ok)
      .toSet();

  // ── Eventi chiamate ───────────────────────────────────────────────────────

  /// Incremento ottimistico locale dopo un 200 OK, in attesa del prossimo
  /// refresh autoritativo dal backend.
  void recordOptimisticCall(AiFeature feature) {
    _optimistic[feature] = (_optimistic[feature] ?? 0) + 1;
    // Se superiamo il limite il gate si attiva automaticamente via [usedFor].
    notifyListeners();
  }

  /// Marca la feature come bloccata fino al prossimo reset_at.
  /// Da chiamare quando il server risponde 429 o il provider AI upstream
  /// restituisce rate limit esaurito su tutti i modelli.
  void markExceeded(AiFeature feature) {
    _markedExceededAt[feature] = DateTime.now().toUtc();
    notifyListeners();
  }

  /// Rimuove manualmente il blocco (es. dopo refresh manuale da UI).
  void clearExceeded(AiFeature feature) {
    if (_markedExceededAt.remove(feature) != null) {
      notifyListeners();
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  /// Istante di reset della feature (UTC). Tutte le feature condividono il
  /// reset giornaliero a mezzanotte UTC lato backend (`personal.reset_at`);
  /// stats usa `system.reset_at` quando serve il pool condiviso.
  DateTime? resetAtFor(AiFeature feature) {
    final String? raw;
    if (feature == AiFeature.stats && !_hasPersonalGroqKey) {
      raw = (_quotaData?['system'] as Map?)?['reset_at'] as String?;
    } else {
      raw = (_quotaData?['personal'] as Map?)?['reset_at'] as String?;
    }
    final parsed = _parseUtcIso(raw);
    if (parsed != null) return parsed;
    // Fallback: prossima mezzanotte UTC.
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day)
        .add(const Duration(days: 1));
  }

  Duration? timeUntilReset(AiFeature feature) {
    final r = resetAtFor(feature);
    if (r == null) return null;
    final d = r.difference(DateTime.now().toUtc());
    return d.isNegative ? Duration.zero : d;
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  /// Ricarica i dati di quota dal backend. Se una chiamata è già in volo
  /// ritorna quella stessa future (dedup).
  Future<void> refresh() {
    final inflight = _inFlightRefresh;
    if (inflight != null) return inflight;
    final f = _doRefresh();
    _inFlightRefresh = f;
    f.whenComplete(() => _inFlightRefresh = null);
    return f;
  }

  Future<void> _doRefresh() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final data = await _apiService.get(ApiConstants.aiQuotaUrl);
      _quotaData = data as Map<String, dynamic>;
      _lastFetchAt = DateTime.now();
      // Il backend ora contiene i valori reali: azzera l'overlay ottimistico.
      _optimistic.updateAll((_, __) => 0);
      _pruneExceededIfReset(AiFeature.chat);
      _pruneExceededIfReset(AiFeature.voice);
      _pruneExceededIfReset(AiFeature.stats);
      _scheduleResetTimer();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh best-effort se i dati sono più vecchi di [maxAge].
  Future<void> refreshIfStale({
    Duration maxAge = const Duration(minutes: 2),
  }) {
    final last = _lastFetchAt;
    if (last != null && DateTime.now().difference(last) < maxAge) {
      return Future.value();
    }
    return refresh();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _pruneExceededIfReset(AiFeature feature) {
    final marked = _markedExceededAt[feature];
    if (marked == null) return;
    final reset = resetAtFor(feature);
    if (reset == null) return;
    if (DateTime.now().toUtc().isAfter(reset)) {
      _markedExceededAt.remove(feature);
    }
  }

  void _scheduleResetTimer() {
    _resetTimer?.cancel();
    DateTime? earliest;
    for (final f in AiFeature.values) {
      final r = resetAtFor(f);
      if (r == null) continue;
      if (earliest == null || r.isBefore(earliest)) earliest = r;
    }
    if (earliest == null) return;
    final delay = earliest.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) return;
    // +5s di margine per garantire che il backend abbia già eseguito il reset.
    _resetTimer = Timer(delay + const Duration(seconds: 5), () {
      refresh();
    });
  }

  static int _intFrom(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseUtcIso(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized =
        raw.endsWith('Z') || raw.contains('+') ? raw : '${raw}Z';
    return DateTime.tryParse(normalized)?.toUtc();
  }

  // ── Upgrade / activation ──────────────────────────────────────────────────

  /// Invia una richiesta di upgrade tier al backend (lascia invariata la
  /// firma storica esposta tramite ChatService).
  Future<Map<String, dynamic>> requestUpgrade(String requestedTier) async {
    final data = await _apiService.post(
      ApiConstants.aiRequestUpgradeUrl,
      {'requested_tier': requestedTier},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Attiva un codice tester/promo per sbloccare un tier superiore.
  Future<Map<String, dynamic>> activateCode(String code) async {
    final data = await _apiService.post(
      ApiConstants.aiActivateCodeUrl,
      {'code': code.trim()},
    );
    final result = Map<String, dynamic>.from(data as Map);
    // Dopo l'attivazione i limiti possono essere cambiati: ricarica.
    await refresh();
    return result;
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}
