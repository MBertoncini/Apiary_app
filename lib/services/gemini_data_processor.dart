// lib/services/gemini_data_processor.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_entry.dart';
import '../config/api_keys.dart';
import 'voice_data_processor.dart';

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
  "telaini_totali": <intero o null>,
  "telaini_covata": <intero o null>,
  "telaini_scorte": <intero o null>,
  "forza_famiglia": <"debole"/"normale"/"forte" o null>,
  "sciamatura": <true/false o null>,
  "problemi_sanitari": <true/false o null>,
  "tipo_problema": <stringa o null>,
  "note": <stringa con osservazioni libere o null>
}

Regole:
- Se viene menzionato "arnia N", arnia_numero = N
- "famiglia forte/normale/debole" → forza_famiglia
- "presenza regina" o "regina presente" → presenza_regina = true
- "regina assente" → presenza_regina = false
- "celle reali" → celle_reali = true; se viene dato un numero, numero_celle_reali
- "sciamatura" o "rischio sciamatura" → sciamatura = true
- "problemi sanitari", "varroa", "nosema", "covata calcificata" → problemi_sanitari = true + tipo_problema
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
            '$_geminiBaseUrl/$model:generateContent?key=${ApiKeys.geminiApiKey}');

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
        telainiTotali: _parseInt(json['telaini_totali']),
        telainiCovata: _parseInt(json['telaini_covata']),
        telainiScorte: _parseInt(json['telaini_scorte']),
        forzaFamiglia: json['forza_famiglia'] as String?,
        sciamatura: json['sciamatura'] as bool?,
        problemiSanitari: json['problemi_sanitari'] as bool?,
        tipoProblema: json['tipo_problema'] as String?,
        note: json['note'] as String?,
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
