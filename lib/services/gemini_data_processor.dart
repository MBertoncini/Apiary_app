// lib/services/gemini_data_processor.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_entry.dart';
import '../config/api_keys.dart';
import 'voice_data_processor.dart';
import 'ai_quota_service.dart';

class GeminiDataProcessor extends ChangeNotifier with VoiceDataProcessor {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Models in priority order — first available wins.
  // gemini-2.0-flash has limit: 0 on the free tier (disabled).
  static const List<String> _modelFallbacks = [
    'gemini-2.5-flash',        // 5 RPM free tier, stable
    'gemini-3-flash-preview',  // 5 RPM free tier
    'gemini-3.1-flash-lite',   // fastest/cheapest 3.x
    'gemini-1.5-flash',        // last resort, very stable
  ];

  AiQuotaService? _quotaService;

  // Chiave personale (sovrascrive ApiKeys.geminiApiKey se impostata)
  String? _personalApiKey;

  void setPersonalKey(String? key) {
    _personalApiKey = (key != null && key.isNotEmpty) ? key : null;
  }

  /// Collega il servizio centralizzato di quota AI per gating voice.
  void attachQuotaService(AiQuotaService? svc) {
    _quotaService = svc;
  }

  // Contesto sessione
  int? _contextApiarioId;
  String? _contextApiarioNome;

  // Stato
  bool _isProcessing = false;
  String? _error;
  bool _lastCallWasNetworkError = false;
  bool _lastCallWasRateLimit = false;

  // Getters
  bool get isProcessing => _isProcessing;
  @override
  String? get error => _error;
  bool get lastCallWasNetworkError => _lastCallWasNetworkError;
  bool get lastCallWasRateLimit => _lastCallWasRateLimit;

  void setContext(int? apiarioId, String? apiarioNome) {
    _contextApiarioId = apiarioId;
    _contextApiarioNome = apiarioNome;
  }

  @override
  Future<VoiceEntry?> processVoiceInput(String text) async {
    if (text.isEmpty) return null;

    // Pre-check quota voice centralizzata.
    final quota = _quotaService;
    if (quota != null && !quota.canCall(AiFeature.voice)) {
      _lastCallWasRateLimit = true;
      _error = 'Quota AI voce esaurita. Riprova dopo il reset giornaliero.';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _error = null;
    _lastCallWasNetworkError = false;
    _lastCallWasRateLimit = false;
    notifyListeners();

    final contextInfo = _contextApiarioNome != null
        ? 'Contesto sessione: apiario "$_contextApiarioNome" (ID: $_contextApiarioId). '
            'L\'utente parlerà solo del numero arnia, non ripeterà il nome dell\'apiario.'
        : 'Nessun apiario selezionato come contesto sessione.';

    final prompt = '''
Sei un assistente per apicoltori. Estrai dati strutturati da una trascrizione vocale.

$contextInfo

Trascrizione: "$text"

Rispondi SOLO con un oggetto JSON valido (nessun testo aggiuntivo, nessun markdown) con questi campi:
{
  "arnia_numero": <intero o null>,
  "presenza_regina": <true/false o null>,
  "regina_vista": <true/false o null>,
  "uova_fresche": <true/false o null>,
  "celle_reali": <true/false o null>,
  "numero_celle_reali": <intero o null>,
  "telaini_covata": <intero o null>,
  "telaini_scorte": <intero o null>,
  "telaini_diaframma": <intero o null>,
  "telaini_foglio_cereo": <intero o null>,
  "telaini_nutritore": <intero o null>,
  "forza_famiglia": <"debole"/"normale"/"forte" o null>,
  "sciamatura": <true/false o null>,
  "problemi_sanitari": <true/false o null>,
  "tipo_problema": <stringa o null>,
  "note": <stringa con osservazioni libere o null>,
  "regina_colorata": <true/false o null>,
  "colore_regina": <"bianco"/"giallo"/"rosso"/"verde"/"blu" o null>
}

Regole:
- Se viene menzionato "arnia N", arnia_numero = N
- "famiglia forte/normale/debole" → forza_famiglia
- "presenza regina" o "regina presente" → presenza_regina = true, regina_vista = false
- "regina vista" o "ho visto la regina" → presenza_regina = true, regina_vista = true
- "regina assente" → presenza_regina = false, regina_vista = false
- "celle reali" → celle_reali = true; se viene dato un numero, numero_celle_reali
- "sciamatura" o "rischio sciamatura" → sciamatura = true
- "problemi sanitari", "varroa", "nosema", "covata calcificata" → problemi_sanitari = true + tipo_problema
- "diaframma" → telaini_diaframma (numero intero)
- "foglio cereo" o "fogli cerei" → telaini_foglio_cereo (numero intero)
- "nutritore" → telaini_nutritore (numero intero)
- NON calcolare telaini_totali: viene calcolato automaticamente come somma delle parti
- "ho colorato la regina" o "regina colorata" o "marcato la regina" → regina_colorata = true
- Se viene menzionato un colore (bianco/giallo/rosso/verde/blu) insieme alla regina → colore_regina
- Le osservazioni non strutturate vanno in note
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0,
        'responseMimeType': 'application/json',
      }
    });

    try {
      for (final model in _modelFallbacks) {
        final uri = Uri.parse(
            '$_geminiBaseUrl/$model:generateContent?key=${_personalApiKey ?? ApiKeys.geminiApiKey}');

        http.Response response;
        try {
          response = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(const Duration(seconds: 15));
        } on SocketException catch (e) {
          _lastCallWasNetworkError = true;
          _error = 'Nessuna connessione di rete';
          debugPrint('SocketException: $e');
          return null;
        } on TimeoutException catch (e) {
          _lastCallWasNetworkError = true;
          _error = 'Timeout nella comunicazione con Gemini';
          debugPrint('TimeoutException: $e');
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
          debugPrint('[Gemini] Used model: $model');
          _quotaService?.recordOptimisticCall(AiFeature.voice);
          return _parseGeminiResponse(responseText);
        } else if (response.statusCode == 429) {
          // Check if this model has limit: 0 (permanently disabled on this plan)
          bool isDisabled = response.body.contains('limit: 0') ||
              response.body.contains('"limit":0');
          debugPrint(
              '[Gemini] 429 on $model (disabled=$isDisabled): ${response.body}');
          if (isDisabled) {
            // Try next model in fallback list
            continue;
          }
          // Genuine rate limit — stop trying
          _lastCallWasRateLimit = true;
          _quotaService?.markExceeded(AiFeature.voice);
          _error =
              'Limite richieste Gemini ($model). Attendi un minuto e riprova.';
          return null;
        } else {
          String geminiReason = '';
          try {
            final errJson =
                jsonDecode(response.body) as Map<String, dynamic>;
            geminiReason = errJson['error']?['message'] as String? ?? '';
          } catch (_) {}
          _error = 'Errore Gemini API ${response.statusCode}'
              '${geminiReason.isNotEmpty ? ': $geminiReason' : ''}';
          debugPrint(
              'Gemini ${response.statusCode} body: ${response.body}');
          return null;
        }
      }

      // All models exhausted
      _lastCallWasRateLimit = true;
      _quotaService?.markExceeded(AiFeature.voice);
      _error = 'Nessun modello Gemini disponibile sul piano gratuito. '
          'Aggiorna il piano su ai.google.dev.';
      return null;
    } catch (e) {
      _error = 'Errore: $e';
      debugPrint('GeminiDataProcessor error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  VoiceEntry? _parseGeminiResponse(String rawText) {
    try {
      // Strip possible markdown code fences
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
      debugPrint('Parse error: $e\nRaw: $rawText');
      return null;
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  void clearError() {
    _error = null;
    _lastCallWasNetworkError = false;
    _lastCallWasRateLimit = false;
    notifyListeners();
  }
}
