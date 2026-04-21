// lib/services/ai_quota_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // SharedPreferences keys. `_spGroqKey` è allineato a [AiQuotaLocalTracker]
  // per leggere la chiave Groq persistita senza duplicare il tracker.
  static const _spGroqKey = 'groq_api_key';
  static const _spPendingVoiceKey = 'ai_quota_pending_voice_calls';

  final ApiService _apiService;

  AiQuotaService(this._apiService) {
    // Carica lo stato persistito (chiave Groq, retry queue voice) in
    // background. Il costruttore non attende: i getter ritornano i default
    // fino al completamento del load.
    unawaited(_loadPersistedState());
  }

  Map<String, dynamic>? _quotaData;
  DateTime? _lastFetchAt;
  bool _isLoading = false;
  String? _lastError;

  AiTier _tier = AiTier.free;
  bool _hasPersonalGroqKey = false;
  bool _hasPersonalGeminiKey = false;

  final Map<AiFeature, int> _optimistic = {
    AiFeature.chat: 0,
    AiFeature.voice: 0,
    AiFeature.stats: 0,
  };

  final Map<AiFeature, DateTime> _markedExceededAt = {};

  /// Chiamate voice che hanno avuto 200 OK da Gemini ma la cui telemetria
  /// al backend (`/ai/record-voice-call/`) è fallita. Persistite in
  /// SharedPreferences per sopravvivere a refresh e riavvii dell'app, e
  /// rigiocate al prossimo [refresh]. Finché non sono state sincronizzate
  /// il loro conteggio si somma a [usedFor] in modo che non scompaiano
  /// dal contatore.
  final List<Map<String, dynamic>> _pendingVoiceCalls = [];

  /// Cool-down breve per rate-limit burst del provider (per-minute), che
  /// **non** va marcato come quota giornaliera esaurita.
  DateTime? _voiceBurstCooldownUntil;

  Timer? _resetTimer;
  Future<void>? _inFlightRefresh;

  // ── Getters ────────────────────────────────────────────────────────────────

  Map<String, dynamic>? get rawData => _quotaData;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  DateTime? get lastFetchAt => _lastFetchAt;
  AiTier get tier => _tier;
  bool get hasPersonalGroqKey => _hasPersonalGroqKey;
  bool get hasPersonalGeminiKey => _hasPersonalGeminiKey;

  /// Numero di chiamate voice registrate localmente ma non ancora
  /// sincronizzate col backend. Esposto per UI diagnostica.
  int get pendingVoiceCallCount => _pendingVoiceCalls.length;

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

  /// Segnala se l'utente ha configurato una chiave Gemini personale.
  /// Quando true, la feature [AiFeature.voice] non viene bloccata dal tier
  /// limit locale (l'utente paga direttamente Google per le sue chiamate).
  void setHasPersonalGeminiKey(bool value) {
    if (_hasPersonalGeminiKey == value) return;
    _hasPersonalGeminiKey = value;
    if (value) {
      // Con chiave personale l'utente non è più soggetto al tier limit
      // locale: rimuovi eventuali mark derivati da `_maybeMarkOnLimit`.
      // Se Google risponderà con 429 reale, il mark verrà riscritto dal
      // prossimo tentativo di chiamata.
      _markedExceededAt.remove(AiFeature.voice);
    }
    notifyListeners();
  }

  // ── Limiti ────────────────────────────────────────────────────────────────

  /// Limite giornaliero per una feature, risolto dal backend con fallback
  /// all'enum [AiTier]. Per [AiFeature.stats] senza chiave Groq personale
  /// usa il `daily_limit` del pool di sistema (Groq condiviso), altrimenti
  /// 0 (illimitato — chiamate dirette a Groq con la chiave dell'utente).
  int limitFor(AiFeature feature) {
    final limits = _tier.resolvedLimits(allTierLimits);
    switch (feature) {
      case AiFeature.chat:
        return limits.chat;
      case AiFeature.voice:
        return limits.voice;
      case AiFeature.stats:
        if (_hasPersonalGroqKey) return 0;
        return _intFrom(_quotaData?['daily_limit']);
    }
  }

  /// Limite totale combinato chat+voice (visualizzato nel riepilogo).
  int get totalLimit => _tier.resolvedLimits(allTierLimits).total;

  // ── Utilizzo ──────────────────────────────────────────────────────────────

  /// Utilizzo per feature = utilizzo backend + incremento ottimistico locale
  /// + eventuali chiamate voice persistite nella retry queue (solo voice).
  ///
  /// Per [AiFeature.stats] senza chiave Groq personale il contatore
  /// autoritativo è `system.requests_today` (pool condiviso), non
  /// `usage.stats_today` (che non viene popolato dal backend in quel caso).
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
          if (_hasPersonalGroqKey) {
            backend = _intFrom(usage['stats_today']);
          } else {
            final system = _quotaData?['system'] as Map?;
            backend = system != null
                ? _intFrom(system['requests_today'])
                : _intFrom(usage['stats_today']);
          }
          break;
      }
    }
    final pending =
        feature == AiFeature.voice ? _pendingVoiceCalls.length : 0;
    return backend + (_optimistic[feature] ?? 0) + pending;
  }

  int get totalUsed {
    final usage = _quotaData?['usage'] as Map?;
    final backend =
        usage != null ? _intFrom(usage['total_today']) : 0;
    return backend +
        (_optimistic[AiFeature.chat] ?? 0) +
        (_optimistic[AiFeature.voice] ?? 0) +
        _pendingVoiceCalls.length;
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

    // Cool-down burst rate-limit (solo voice): blocco temporaneo, non
    // rappresenta esaurimento del tier — si esaurisce da solo.
    if (feature == AiFeature.voice) {
      final cd = _voiceBurstCooldownUntil;
      if (cd != null && DateTime.now().isBefore(cd)) {
        return AiQuotaBlock.exceeded;
      }
    }

    if (_markedExceededAt.containsKey(feature)) {
      return AiQuotaBlock.exceeded;
    }

    // Chiave Gemini personale → l'utente paga Google direttamente e non è
    // vincolato al tier limit locale. Eventuali 429 Google sono gestiti
    // via [markExceeded] / burst cooldown sopra.
    if (feature == AiFeature.voice && _hasPersonalGeminiKey) {
      return AiQuotaBlock.ok;
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

  /// Istante fino a cui la voice è in cool-down da rate-limit burst.
  /// Null se non c'è un cool-down attivo.
  DateTime? get voiceBurstCooldownUntil => _voiceBurstCooldownUntil;

  /// Registra un cool-down breve per la voice feature (tipicamente 30–60s
  /// derivati da `retryDelay` del 429 Gemini per-minute). Non marca la
  /// quota come esaurita, il banner UI torna verde automaticamente.
  void markVoiceBurstCooldown(Duration d) {
    final target = DateTime.now().add(d);
    final current = _voiceBurstCooldownUntil;
    // Prendi il più tardi tra il cool-down esistente e il nuovo, per non
    // accorciare accidentalmente un limite già attivo.
    if (current == null || target.isAfter(current)) {
      _voiceBurstCooldownUntil = target;
      notifyListeners();
    }
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
    // Se abbiamo raggiunto il limite, marca subito come esaurito. Il mark
    // sopravvive al prossimo refresh() (che azzera l'overlay ottimistico),
    // garantendo il blocco anche se il backend non ha ancora registrato
    // tutte le chiamate appena fatte.
    _maybeMarkOnLimit(feature);
    notifyListeners();
  }

  /// Se l'utilizzo corrente ha raggiunto/superato il limite, imposta il mark
  /// di esaurimento. Scade naturalmente al prossimo reset giornaliero.
  void _maybeMarkOnLimit(AiFeature feature) {
    final limit = limitFor(feature);
    if (limit > 0 && usedFor(feature) >= limit) {
      _markedExceededAt[feature] ??= DateTime.now().toUtc();
    }
  }

  /// Notifica al backend che è stata effettuata una chiamata voice (Gemini
  /// viene invocato direttamente dal client, quindi il backend non la vede
  /// altrimenti). Fire-and-forget: non attendibile per bloccare l'UI — quello
  /// lo fa già [recordOptimisticCall] — ma rende `voice_today` autoritativo
  /// così che il counter sopravviva a navigazioni e refresh.
  ///
  /// Se il backend risponde con i contatori aggiornati, sincronizza
  /// `_quotaData` e azzera l'overlay ottimistico della feature voice.
  /// Se risponde 429 (tier esaurito), marca la feature come esaurita.
  Future<void> recordVoiceCallToBackend({String? model}) async {
    try {
      final payload = <String, dynamic>{};
      if (model != null) payload['model'] = model;
      final data = await _apiService.post(
        ApiConstants.aiRecordVoiceCallUrl,
        payload,
      );
      if (data is Map && data.isNotEmpty) {
        final usageMap = data['usage'];
        final int? newCount = _intFromMaybe(data['voice_today']) ??
            (usageMap is Map ? _intFromMaybe(usageMap['voice_today']) : null);
        if (newCount != null) {
          final currentUsage = Map<String, dynamic>.from(
              (_quotaData?['usage'] as Map?) ?? const <String, dynamic>{});
          // Monotonico: chiamate concorrenti possono rispondere fuori
          // ordine, tenere sempre il valore più alto.
          final currentVoice = _intFrom(currentUsage['voice_today']);
          final mergedVoice =
              newCount > currentVoice ? newCount : currentVoice;
          currentUsage['voice_today'] = mergedVoice;
          // Bump monotonico di total_today: usa il valore esplicito dal
          // backend se presente, altrimenti applica il delta voice. Senza
          // questo, [totalUsed] scenderebbe di 1 a ogni decremento
          // dell'overlay ottimistico (bug: total_today resta fermo finché
          // non arriva un refresh esplicito del profilo quota).
          final currentTotal = _intFrom(currentUsage['total_today']);
          final int? backendTotal =
              _intFromMaybe(data['total_today']) ??
                  (usageMap is Map
                      ? _intFromMaybe(usageMap['total_today'])
                      : null);
          final voiceDelta = mergedVoice - currentVoice;
          final bumpedTotal = currentTotal + (voiceDelta > 0 ? voiceDelta : 0);
          final nextTotal = backendTotal != null && backendTotal > bumpedTotal
              ? backendTotal
              : bumpedTotal;
          currentUsage['total_today'] = nextTotal;
          _quotaData ??= <String, dynamic>{};
          _quotaData!['usage'] = currentUsage;
          // Una chiamata è stata confermata dal backend: scala di uno
          // l'overlay ottimistico (anziché azzerarlo), così altre chiamate
          // in volo nel frattempo restano contabilizzate finché non
          // ricevono anche loro la propria risposta.
          final currentOpt = _optimistic[AiFeature.voice] ?? 0;
          _optimistic[AiFeature.voice] =
              currentOpt > 0 ? currentOpt - 1 : 0;
          _maybeMarkOnLimit(AiFeature.voice);
          notifyListeners();
        }
      }
    } on QuotaExceededException {
      // Backend conferma esaurito: blocca immediatamente.
      markExceeded(AiFeature.voice);
    } catch (e) {
      // Errore di rete o backend non raggiungibile: la chiamata Gemini è
      // già andata a buon fine e va contabilizzata, quindi la spostiamo
      // nella retry queue persistente. Al prossimo refresh verrà rigiocata
      // e il counter sincronizzato col backend.
      debugPrint('[AiQuotaService] recordVoiceCallToBackend error: $e');
      markVoiceCallUnsynced(model: model);
    }
  }

  /// Registra una chiamata voice confermata da Gemini (200 OK) ma la cui
  /// telemetria al backend è fallita. Scala l'overlay ottimistico (la
  /// chiamata resta contabilizzata tramite la pending queue, così il
  /// totale visualizzato non scende) e la persiste per replay al
  /// prossimo refresh, sopravvivendo a navigazioni e restart dell'app.
  void markVoiceCallUnsynced({String? model}) {
    _pendingVoiceCalls.add({
      'model': model,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
    final currentOpt = _optimistic[AiFeature.voice] ?? 0;
    _optimistic[AiFeature.voice] = currentOpt > 0 ? currentOpt - 1 : 0;
    _maybeMarkOnLimit(AiFeature.voice);
    unawaited(_savePendingVoice());
    notifyListeners();
  }

  static int? _intFromMaybe(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
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
      // Prima rigioca le chiamate voice pendenti: così il GET successivo
      // vede il counter autoritativo già sincronizzato e gli eventuali 429
      // in coda vengono convertiti in mark di esaurimento.
      await _flushPendingVoice();
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

  // ── Persistenza stato / retry queue ───────────────────────────────────────

  /// Carica da SharedPreferences lo stato che deve sopravvivere al boot:
  /// - flag "ha chiave Groq personale" (letto dalla stessa key usata dai
  ///   servizi stats, nessuna scrittura qui)
  /// - coda di telemetria voice non ancora sincronizzata col backend
  Future<void> _loadPersistedState() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final groq = sp.getString(_spGroqKey);
      if (groq != null && groq.isNotEmpty) {
        _hasPersonalGroqKey = true;
      }
      final raw = sp.getString(_spPendingVoiceKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                _pendingVoiceCalls
                    .add(Map<String, dynamic>.from(item));
              }
            }
          }
        } catch (e) {
          debugPrint('[AiQuotaService] pending voice parse error: $e');
        }
      }
      if (_hasPersonalGroqKey || _pendingVoiceCalls.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AiQuotaService] load persisted state error: $e');
    }
  }

  Future<void> _savePendingVoice() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (_pendingVoiceCalls.isEmpty) {
        await sp.remove(_spPendingVoiceKey);
      } else {
        await sp.setString(
            _spPendingVoiceKey, jsonEncode(_pendingVoiceCalls));
      }
    } catch (e) {
      debugPrint('[AiQuotaService] save pending voice error: $e');
    }
  }

  /// Rigioca le chiamate voice pendenti contro il backend. Le 429 vengono
  /// scartate (il backend rifiuta di contabilizzarle e la feature viene
  /// marcata esaurita), mentre errori transitori lasciano la call in coda
  /// per un nuovo tentativo al prossimo refresh.
  Future<void> _flushPendingVoice() async {
    if (_pendingVoiceCalls.isEmpty) return;
    final snapshot =
        List<Map<String, dynamic>>.from(_pendingVoiceCalls);
    _pendingVoiceCalls.clear();
    final failed = <Map<String, dynamic>>[];
    bool hit429 = false;
    for (final call in snapshot) {
      try {
        final payload = <String, dynamic>{};
        final model = call['model'];
        if (model is String && model.isNotEmpty) {
          payload['model'] = model;
        }
        await _apiService.post(ApiConstants.aiRecordVoiceCallUrl, payload);
      } on QuotaExceededException {
        hit429 = true;
      } catch (e) {
        failed.add(call);
      }
    }
    _pendingVoiceCalls.addAll(failed);
    await _savePendingVoice();
    if (hit429) {
      markExceeded(AiFeature.voice);
    }
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
