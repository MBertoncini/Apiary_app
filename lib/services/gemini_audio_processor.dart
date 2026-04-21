// lib/services/gemini_audio_processor.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_entry.dart';
import '../config/api_keys.dart';
import 'ai_quota_service.dart';
import 'voice_language_rules.dart';
import 'debug_trace.dart';

/// Invia un file audio direttamente a Gemini multimodale (inline_data base64).
/// Gemini trascrive e struttura i dati in un unico passaggio, eliminando
/// la dipendenza dal riconoscimento vocale locale.
class GeminiAudioProcessor extends ChangeNotifier {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const List<String> _modelFallbacks = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-3-flash-preview',
    'gemini-3.1-flash-lite-preview',
  ];

  AiQuotaService? _quotaService;

  String? _personalApiKey;
  int? _contextApiarioId;
  String? _contextApiarioNome;
  VoiceLanguageRules _langRules = VoiceRulesIt();

  bool _isProcessing = false;
  String? _error;
  bool _lastCallWasNetworkError = false;
  bool _lastCallWasRateLimit = false;

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  bool get lastCallWasNetworkError => _lastCallWasNetworkError;
  bool get lastCallWasRateLimit => _lastCallWasRateLimit;

  void setPersonalKey(String? key) {
    _personalApiKey = (key != null && key.isNotEmpty) ? key : null;
  }

  /// Collega il servizio centralizzato di quota AI. Quando presente, le
  /// chiamate sono pre-gated e il contatore voice viene aggiornato
  /// otticamente; su 429 definitivo la feature viene marcata esaurita.
  void attachQuotaService(AiQuotaService? svc) {
    _quotaService = svc;
  }

  void setLanguage(String languageCode) {
    _langRules = VoiceLanguageRules.forCode(languageCode);
  }

  void setContext(int? apiarioId, String? apiarioNome) {
    _contextApiarioId = apiarioId;
    _contextApiarioNome = apiarioNome;
  }

  void clearError() {
    _error = null;
    _lastCallWasNetworkError = false;
    _lastCallWasRateLimit = false;
    notifyListeners();
  }

  /// Processa il file audio [filePath] (AAC) inviandolo a Gemini multimodale.
  /// Restituisce un [VoiceEntry] strutturato, o null in caso di errore.
  Future<VoiceEntry?> processAudioInput(String filePath) async {
    DebugTrace.log('gemini: processAudioInput ENTER ${filePath.split('/').last}');
    final keyInUse = _personalApiKey != null ? 'personal' : 'shared';
    final keyLen = (_personalApiKey ?? ApiKeys.geminiApiKey).length;
    DebugTrace.log('gemini: key=$keyInUse len=$keyLen');

    // Pre-check centralizzato: se la quota voice è esaurita non spediamo.
    final quota = _quotaService;
    if (quota != null && !quota.canCall(AiFeature.voice)) {
      _lastCallWasRateLimit = true;
      _error = 'Quota AI voce esaurita. Riprova dopo il reset giornaliero.';
      DebugTrace.log('gemini: PRECHECK BLOCKED by AiQuotaService');
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _error = null;
    _lastCallWasNetworkError = false;
    _lastCallWasRateLimit = false;
    notifyListeners();

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        DebugTrace.log('gemini: FILE MISSING $filePath');
        _error = 'File audio non trovato';
        return null;
      }

      final fileSize = await file.length();
      DebugTrace.log('gemini: file size=${(fileSize / 1024).toStringAsFixed(1)}KB');
      // Limite conservativo: ~15 MB raw → ~20 MB base64
      const maxBytes = 15 * 1024 * 1024;
      if (fileSize > maxBytes) {
        DebugTrace.log('gemini: FILE TOO LARGE');
        _error = 'Il file audio è troppo grande (${(fileSize / 1048576).toStringAsFixed(1)} MB). '
            'Registrazioni superiori a ~15 minuti non sono supportate.';
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final contextInfo = _contextApiarioNome != null
          ? (_langRules.code == 'en'
              ? 'Session context: apiary "$_contextApiarioNome" '
                  '(ID: $_contextApiarioId). '
                  'The beekeeper will only mention the hive number.'
              : 'Contesto sessione: apiario "$_contextApiarioNome" '
                  '(ID: $_contextApiarioId). '
                  'L\'apicoltore parlerà solo del numero arnia.')
          : (_langRules.code == 'en'
              ? 'No apiary selected as context.'
              : 'Nessun apiario selezionato come contesto.');

      final prompt = _langRules.geminiPrompt(contextInfo);

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': 'audio/aac',
                  'data': base64Audio,
                }
              },
              {'text': prompt},
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0,
          'responseMimeType': 'application/json',
        }
      });

      for (final model in _modelFallbacks) {
        final uri = Uri.parse(
            '$_geminiBaseUrl/$model:generateContent'
            '?key=${_personalApiKey ?? ApiKeys.geminiApiKey}');

        DebugTrace.log('gemini: POST model=$model');
        http.Response response;
        try {
          response = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(const Duration(seconds: 90)); // audio richiede più tempo
          DebugTrace.log('gemini: HTTP status=${response.statusCode} len=${response.body.length}');
        } on SocketException catch (e) {
          DebugTrace.log('gemini: SocketException $e');
          _lastCallWasNetworkError = true;
          _error = 'Nessuna connessione di rete';
          return null;
        } on TimeoutException {
          DebugTrace.log('gemini: TIMEOUT');
          _lastCallWasNetworkError = true;
          _error = 'Timeout nella comunicazione con Gemini (>90s). '
              'Connessione lenta o audio troppo lungo.';
          return null;
        }

        if (response.statusCode == 200) {
          final responseJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          final responseText = responseJson['candidates']?[0]?['content']
              ?['parts']?[0]?['text'] as String?;
          if (responseText == null) {
            _error = 'Risposta Gemini vuota';
            return null;
          }
          debugPrint('[GeminiAudio] Used model: $model');
          _quotaService?.recordOptimisticCall(AiFeature.voice);
          // Telemetria backend per rendere voice_today autoritativo
          // (Gemini è chiamato direttamente dal client, il backend
          // altrimenti non vedrebbe mai queste chiamate).
          unawaited(_quotaService?.recordVoiceCallToBackend(model: model) ??
              Future.value());
          return _parseResponse(responseText);
        } else if (response.statusCode == 429) {
          final body = response.body;
          final isDisabled =
              body.contains('limit: 0') || body.contains('"limit":0');
          // Google distingue due sapori di 429: quota giornaliera esaurita
          // (PerDay/daily) vs rate-limit burst per-minuto. Il primo va
          // trattato come esaurimento fino al reset UTC; il secondo come
          // cool-down breve, per non bloccare l'utente fino a mezzanotte.
          final isDailyQuota = body.contains('PerDay') ||
              body.contains('per day') ||
              body.contains('daily');
          debugPrint('[GeminiAudio] 429 on $model '
              '(disabled=$isDisabled daily=$isDailyQuota)');
          final snippet429 = body.length > 200 ? '${body.substring(0, 200)}…' : body;
          DebugTrace.log('gemini: 429 on $model '
              'disabled=$isDisabled daily=$isDailyQuota body=$snippet429');
          if (isDisabled && model != _modelFallbacks.last) {
            continue;
          }
          _lastCallWasRateLimit = true;
          if (isDailyQuota) {
            _quotaService?.markExceeded(AiFeature.voice);
            _error = 'Quota giornaliera Gemini esaurita. '
                'Riprova dopo il reset giornaliero.';
          } else {
            final cooldown =
                _extractRetryDelay(body) ?? const Duration(seconds: 60);
            _quotaService?.markVoiceBurstCooldown(cooldown);
            _error = 'Limite momentaneo Gemini. '
                'Riprova tra ${cooldown.inSeconds}s.';
          }
          return null;
        } else {
          String reason = '';
          try {
            final err = jsonDecode(response.body) as Map<String, dynamic>;
            reason = err['error']?['message'] as String? ?? '';
          } catch (_) {}
          _error = 'Errore Gemini API ${response.statusCode}'
              '${reason.isNotEmpty ? ': $reason' : ''}';
          debugPrint('[GeminiAudio] ${response.statusCode}: ${response.body}');
          final snippet = response.body.length > 160
              ? '${response.body.substring(0, 160)}…'
              : response.body;
          DebugTrace.log('gemini: ERR ${response.statusCode} body=$snippet');
          // Per modello non trovato (404) o non disponibile (503/502)
          // proviamo il modello successivo; per errori client (400, 401)
          // usciamo subito perché cambiare modello non aiuta.
          final status = response.statusCode;
          if (status == 404 || status == 503 || status == 502) continue;
          return null;
        }
      }

      // Tutti i modelli hanno risposto con errori infrastrutturali
      // (404 deprecato / 502 / 503): NON è quota giornaliera esaurita.
      // Marcarla come tale bloccherebbe il mic fino a mezzanotte UTC
      // anche se il contatore tier è a 0. Trattare come errore transitorio:
      // cool-down breve (previene hammering del provider) + flag network
      // error (processQueue fa break senza cancellare gli item in coda).
      _lastCallWasNetworkError = true;
      _quotaService?.markVoiceBurstCooldown(const Duration(seconds: 60));
      _error = 'Servizio Gemini temporaneamente non disponibile. '
          'Riprova tra poco.';
      return null;
    } catch (e) {
      _error = 'Errore: $e';
      debugPrint('[GeminiAudio] error: $e');
      DebugTrace.log('gemini: EXCEPTION $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  VoiceEntry? _parseResponse(String rawText) {
    try {
      var clean = rawText.trim();
      if (clean.startsWith('```')) {
        clean = clean.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
        clean = clean.replaceFirst(RegExp(r'\n?```$'), '');
      }
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return VoiceEntry(
        apiarioId: _contextApiarioId,
        apiarioNome: _contextApiarioNome,
        arniaNumero: _parseInt(json['arnia_numero']),
        tipoComando: 'controllo',
        data: DateTime.now(),
        presenzaRegina: json['presenza_regina'] as bool?,
        reginaVista: json['regina_vista'] as bool?,
        uovaFresche: json['uova_fresche'] as bool?,
        celleReali: json['celle_reali'] as bool?,
        numeroCelleReali: _parseInt(json['numero_celle_reali']),
        telainiCovata: _parseInt(json['telaini_covata']),
        telainiScorte: _parseInt(json['telaini_scorte']),
        telainiDiaframma: _parseInt(json['telaini_diaframma']),
        tealiniFoglioCereo: _parseInt(json['telaini_foglio_cereo']),
        telainiNutritore: _parseInt(json['telaini_nutritore']),
        forzaFamiglia: json['forza_famiglia'] as String?,
        sciamatura: json['sciamatura'] as bool?,
        problemiSanitari: json['problemi_sanitari'] as bool?,
        tipoProblema: json['tipo_problema'] as String?,
        note: json['note'] as String?,
        reginaColorata: json['regina_colorata'] as bool?,
        coloreRegina: json['colore_regina'] as String?,
      );
    } catch (e) {
      _error = 'Errore nel parsing JSON di Gemini: $e';
      debugPrint('[GeminiAudio] parse error: $e\nRaw: $rawText');
      return null;
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Cerca nel body JSON del 429 un retryDelay stile "42s" o un campo
  /// "retry_after":N. Ritorna null se non trovato.
  Duration? _extractRetryDelay(String body) {
    // Pattern: "retryDelay": "42s"
    final m1 = RegExp(r'"retryDelay"\s*:\s*"(\d+)s"').firstMatch(body);
    if (m1 != null) {
      final s = int.tryParse(m1.group(1)!);
      if (s != null) return Duration(seconds: s);
    }
    // Pattern: "retry_after": 42
    final m2 = RegExp(r'"retry_after"\s*:\s*(\d+)').firstMatch(body);
    if (m2 != null) {
      final s = int.tryParse(m2.group(1)!);
      if (s != null) return Duration(seconds: s);
    }
    return null;
  }
}
