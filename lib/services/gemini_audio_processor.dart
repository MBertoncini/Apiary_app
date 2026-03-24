// lib/services/gemini_audio_processor.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_entry.dart';
import '../config/api_keys.dart';
import 'ai_quota_local_tracker.dart';

/// Invia un file audio direttamente a Gemini multimodale (inline_data base64).
/// Gemini trascrive e struttura i dati in un unico passaggio, eliminando
/// la dipendenza dal riconoscimento vocale locale.
class GeminiAudioProcessor extends ChangeNotifier {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Stesso fallback del GeminiDataProcessor testo.
  static const List<String> _modelFallbacks = [
    'gemini-2.5-flash',
    'gemini-3-flash-preview',
    'gemini-3.1-flash-lite',
    'gemini-1.5-flash',
  ];

  final _tracker = AiQuotaLocalTracker();

  String? _personalApiKey;
  int? _contextApiarioId;
  String? _contextApiarioNome;

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
    _isProcessing = true;
    _error = null;
    _lastCallWasNetworkError = false;
    _lastCallWasRateLimit = false;
    notifyListeners();

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _error = 'File audio non trovato';
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final contextInfo = _contextApiarioNome != null
          ? 'Contesto sessione: apiario "$_contextApiarioNome" '
              '(ID: $_contextApiarioId). '
              'L\'apicoltore parlerà solo del numero arnia.'
          : 'Nessun apiario selezionato come contesto.';

      const jsonSchema = '''
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
}''';

      final prompt = '''
Sei un assistente per apicoltori. Ascolta questa registrazione audio di un apicoltore
che descrive l'ispezione di un'arnia ed estrai i dati strutturati.

$contextInfo

Rispondi SOLO con un oggetto JSON valido (nessun testo aggiuntivo, nessun markdown):
$jsonSchema

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
- NON calcolare telaini_totali
- "ho colorato la regina" o "marcato la regina" → regina_colorata = true
- Se viene menzionato un colore insieme alla regina → colore_regina
- Le osservazioni non strutturate vanno in note
''';

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

        http.Response response;
        try {
          response = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(const Duration(seconds: 30)); // audio richiede più tempo
        } on SocketException {
          _lastCallWasNetworkError = true;
          _error = 'Nessuna connessione di rete';
          return null;
        } on TimeoutException {
          _lastCallWasNetworkError = true;
          _error = 'Timeout nella comunicazione con Gemini';
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
          _tracker.incrementVoiceCall();
          return _parseResponse(responseText);
        } else if (response.statusCode == 429) {
          final isDisabled = response.body.contains('limit: 0') ||
              response.body.contains('"limit":0');
          debugPrint('[GeminiAudio] 429 on $model (disabled=$isDisabled)');
          if (isDisabled) continue;
          _lastCallWasRateLimit = true;
          _error =
              'Limite richieste Gemini ($model). Attendi un minuto e riprova.';
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
          return null;
        }
      }

      _lastCallWasRateLimit = true;
      _error = 'Nessun modello Gemini disponibile. '
          'Aggiorna il piano su ai.google.dev.';
      return null;
    } catch (e) {
      _error = 'Errore: $e';
      debugPrint('[GeminiAudio] error: $e');
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
}
