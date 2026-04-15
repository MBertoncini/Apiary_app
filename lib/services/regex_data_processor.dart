// lib/services/regex_data_processor.dart
//
// Estrae dati strutturati da testo STT trascritto usando regex e regole
// deterministiche. Zero dipendenze esterne: funziona completamente offline.
//
// Pipeline:
//   1. Normalizza il testo (lowercase + number-word → digit)
//   2. Estrae ogni campo di VoiceEntry con pattern dedicati
//   3. Controlla la negazione locale per i campi booleani
//   4. Restituisce VoiceEntry (null se manca il numero arnia)
//
// Language-specific patterns are provided by VoiceLanguageRules.

import 'package:flutter/foundation.dart';
import '../models/voice_entry.dart';
import 'voice_data_processor.dart';
import 'voice_language_rules.dart';

class RegexDataProcessor extends ChangeNotifier with VoiceDataProcessor {
  bool _isProcessing = false;
  String? _error;

  int? _contextApiarioId;
  String? _contextApiarioNome;

  VoiceLanguageRules _rules = VoiceRulesIt();

  // isProcessing non è nel mixin VoiceDataProcessor, è un extra locale.
  bool get isProcessing => _isProcessing;
  @override
  String? get error => _error;

  void setContext(int? apiarioId, String? apiarioNome) {
    _contextApiarioId = apiarioId;
    _contextApiarioNome = apiarioNome;
  }

  /// Sets the language rules for voice processing.
  void setLanguage(String languageCode) {
    _rules = VoiceLanguageRules.forCode(languageCode);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  Future<VoiceEntry?> processVoiceInput(String text) async {
    if (text.trim().isEmpty) return null;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final normalized = _rules.normalize(text);
      final entry = _rules.extract(
        normalized, text, _contextApiarioId, _contextApiarioNome,
      );
      if (entry == null) {
        _error = _rules.errorArniaNotRecognized;
      }
      return entry;
    } catch (e) {
      _error = "Errore nell'estrazione: $e";
      debugPrint('[RegexProcessor] error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
