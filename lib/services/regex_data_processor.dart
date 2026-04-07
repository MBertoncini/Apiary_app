// lib/services/regex_data_processor.dart
//
// Estrae dati strutturati da testo STT trascritto usando regex e regole
// deterministiche. Zero dipendenze esterne: funziona completamente offline.
//
// Pipeline:
//   1. Normalizza il testo (lowercase)
//   2. Converte parole-numero italiane in cifre ("tre" → "3")
//   3. Estrae ogni campo di VoiceEntry con pattern dedicati
//   4. Controlla la negazione locale per i campi booleani
//   5. Restituisce VoiceEntry (null se manca il numero arnia)

import 'package:flutter/foundation.dart';
import '../models/voice_entry.dart';
import 'voice_data_processor.dart';

class RegexDataProcessor extends ChangeNotifier with VoiceDataProcessor {
  bool _isProcessing = false;
  String? _error;

  int? _contextApiarioId;
  String? _contextApiarioNome;

  // isProcessing non è nel mixin VoiceDataProcessor, è un extra locale.
  bool get isProcessing => _isProcessing;
  @override
  String? get error => _error;

  void setContext(int? apiarioId, String? apiarioNome) {
    _contextApiarioId = apiarioId;
    _contextApiarioNome = apiarioNome;
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
      final normalized = _normalize(text);
      final entry = _extract(normalized, text);
      if (entry == null) {
        _error = 'Numero arnia non riconosciuto. Pronuncia "arnia N" '
            'dove N è il numero.';
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

  // ── Normalizzazione ──────────────────────────────────────────────────────────

  /// Lowercase + conversione parole-numero italiane in cifre.
  String _normalize(String text) => _convertItalianNumbers(text.toLowerCase());

  /// Parole-numero italiane → cifre. Ordinate per lunghezza decrescente
  /// così "diciassette" viene processato prima di "sette".
  static const Map<String, String> _italianNumbers = {
    'diciassette': '17',
    'quattordici': '14',
    'diciannove':  '19',
    'diciotto':    '18',
    'tredici':     '13',
    'quindici':    '15',
    'sedici':      '16',
    'quattro':     '4',
    'undici':      '11',
    'dodici':      '12',
    'venti':       '20',
    'cinque':      '5',
    'sette':       '7',
    'zero':        '0',
    'otto':        '8',
    'nove':        '9',
    'dieci':       '10',
    'due':         '2',
    'sei':         '6',
    'tre':         '3',
    'una':         '1',
    'uno':         '1',
  };

  String _convertItalianNumbers(String text) {
    // Sort longest first to handle "diciassette" before "sette"
    final sorted = _italianNumbers.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    var result = text;
    for (final e in sorted) {
      result = result.replaceAllMapped(
        RegExp(r'\b' + e.key + r'\b'),
        (_) => e.value,
      );
    }
    return result;
  }

  // ── Rilevamento negazione ────────────────────────────────────────────────────

  static const List<String> _negationWords = [
    'non ', 'no ', 'senza ', 'nessun', 'assenz',
  ];

  /// True se una parola di negazione appare entro 40 caratteri PRIMA del match.
  bool _negated(String text, Match match) {
    final start = (match.start - 40).clamp(0, text.length);
    final before = text.substring(start, match.start);
    return _negationWords.any((n) => before.contains(n));
  }

  // ── Estrazione principale ────────────────────────────────────────────────────

  VoiceEntry? _extract(String t, String original) {
    final arniaNumero = _extractArniaNumero(t);
    if (arniaNumero == null) return null;

    final tipoProblema     = _extractTipoProblema(t);
    final problemiSanitari = tipoProblema != null
        ? true
        : _extractProblemiSanitari(t);

    return VoiceEntry(
      apiarioId:          _contextApiarioId,
      apiarioNome:        _contextApiarioNome,
      arniaNumero:        arniaNumero,
      tipoComando:        'controllo',
      data:               DateTime.now(),
      presenzaRegina:     _extractPresenzaRegina(t),
      reginaVista:        _extractReginaVista(t),
      uovaFresche:        _extractUovaFresche(t),
      celleReali:         _extractCelleReali(t),
      numeroCelleReali:   _extractNumeroCelleReali(t),
      telainiCovata:      _extractTelaini(t, ['covata']),
      telainiScorte:      _extractTelaini(t, ['scorte', 'miele']),
      telainiDiaframma:   _extractTelaini(t, ['diaframma', 'diaframmi']),
      tealiniFoglioCereo: _extractTelaini(t, ['foglio cereo', 'fogli cerei', 'cereo']),
      telainiNutritore:   _extractTelaini(t, ['nutritore']),
      forzaFamiglia:      _extractForzaFamiglia(t),
      sciamatura:         _extractSciamatura(t),
      problemiSanitari:   problemiSanitari,
      tipoProblema:       tipoProblema,
      // Il testo originale va sempre nelle note: l'utente può correggere
      // eventuali campi non estratti nella schermata di verifica.
      note:               original.trim(),
      reginaColorata:     _extractReginaColorata(t),
      coloreRegina:       _extractColoreRegina(t),
    );
  }

  // ── Estrattori per campo ─────────────────────────────────────────────────────

  int? _extractArniaNumero(String t) {
    final patterns = [
      RegExp(r'arni[ae]\s*(?:numero\s*|n\.?\s*)?(\d+)'),
      RegExp(r'(?:numero|n\.?)\s+arni[ae]\s*(\d+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(t);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  bool? _extractPresenzaRegina(String t) {
    // Assenza esplicita (controllare prima per evitare falsi "presente")
    if (RegExp(r'regina\s+assente').hasMatch(t) ||
        RegExp(r'assenz\w+\s+(?:della?\s+)?regina').hasMatch(t) ||
        RegExp(r'regina\s+non\s+(?:present|trovar)').hasMatch(t) ||
        RegExp(r'non\s+(?:trovo|ho\s+trovato)\s+(?:la\s+)?regina').hasMatch(t)) {
      return false;
    }
    // Presenza esplicita
    if (RegExp(r'regina\s+(?:present|trovar|vista)').hasMatch(t) ||
        RegExp(r'(?:ho\s+visto|ho\s+trovato|trovata|vista)\s+(?:la\s+)?regina').hasMatch(t) ||
        RegExp(r'presenz\w+\s+(?:della?\s+)?regina').hasMatch(t)) {
      return true;
    }
    // Negazione generica: "no regina" / "senza regina"
    final m = RegExp(r'\bregina\b').firstMatch(t);
    if (m != null && _negated(t, m)) return false;
    return null;
  }

  bool? _extractReginaVista(String t) {
    if (RegExp(r'regina\s+non\s+vista').hasMatch(t) ||
        RegExp(r'non\s+(?:ho\s+)?(?:visto|trovato)\s+(?:la\s+)?regina').hasMatch(t)) {
      return false;
    }
    if (RegExp(r'(?:ho\s+)?(?:visto|vista)\s+(?:la\s+)?regina').hasMatch(t) ||
        RegExp(r'regina\s+vista').hasMatch(t)) {
      return true;
    }
    return null;
  }

  bool? _extractUovaFresche(String t) {
    if (RegExp(r'(?:no|nessun[ae]?|senza)\s+uov[ae]').hasMatch(t) ||
        RegExp(r'uov[ae]\s+assent').hasMatch(t)) {
      return false;
    }
    final m = RegExp(r'uov[ae]\s+fresch').firstMatch(t);
    if (m != null) return !_negated(t, m);
    if (RegExp(r'uov[ae]\s+(?:present|trovat|viste?)').hasMatch(t)) return true;
    return null;
  }

  bool? _extractCelleReali(String t) {
    final m = RegExp(r'cell[ae]\s+reali?').firstMatch(t);
    if (m == null) return null;
    return !_negated(t, m);
  }

  int? _extractNumeroCelleReali(String t) {
    final patterns = [
      RegExp(r'(\d+)\s+cell[ae]\s+reali?'),
      RegExp(r'cell[ae]\s+reali?\s+(\d+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(t);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  /// Estrae il conteggio telaini per i [keywords] forniti.
  ///
  /// Gestisce sia la forma esplicita con "telaini":
  ///   "3 telaini di covata" / "telaini covata 3" / "N di covata"
  /// sia la forma abbreviata senza "telaini" (comune per diaframma /
  /// nutritore / foglio cereo che sono tipicamente unità singole):
  ///   "1 diaframma" / "un nutritore" / "foglio cereo 2"
  int? _extractTelaini(String t, List<String> keywords) {
    for (final kw in keywords) {
      final esc = RegExp.escape(kw);
      final patterns = [
        // Con "telaini" (covata / scorte)
        RegExp(r'(\d+)\s+telaini?\s+(?:di\s+)?' + esc),
        RegExp(r'telaini?\s+(?:di\s+)?' + esc + r'\s+(\d+)'),
        RegExp(esc + r'\s+(\d+)\s+telaini?'),
        RegExp(r'(\d+)\s+di\s+' + esc),
        // Senza "telaini" — "1 diaframma", "diaframma 1", "un nutritore"
        RegExp(r'(\d+)\s+' + esc + r'\b'),
        RegExp(r'\b' + esc + r'\s+(\d+)'),
      ];
      for (final p in patterns) {
        final m = p.firstMatch(t);
        if (m != null) return int.tryParse(m.group(1)!);
      }
    }
    return null;
  }

  String? _extractForzaFamiglia(String t) {
    if (RegExp(r'famig\w*\s+(?:molto\s+|abbastanza\s+)?forte').hasMatch(t) ||
        RegExp(r'forza\w*\s+forte').hasMatch(t)) return 'forte';
    if (RegExp(r'famig\w*\s+(?:molto\s+|abbastanza\s+)?debole').hasMatch(t) ||
        RegExp(r'forza\w*\s+debole').hasMatch(t)) return 'debole';
    if (RegExp(r'famig\w*\s+normale').hasMatch(t) ||
        RegExp(r'forza\w*\s+normale').hasMatch(t)) return 'normale';
    return null;
  }

  bool? _extractSciamatura(String t) {
    final m = RegExp(r'sciamatur[ae]|rischio\s+sciam').firstMatch(t);
    if (m == null) return null;
    return !_negated(t, m);
  }

  String? _extractTipoProblema(String t) {
    // Ordinati per lunghezza decrescente per evitare match parziali
    const Map<String, String> problemi = {
      'covata calcificata': 'covata calcificata',
      'covata gessata':     'covata gessata',
      'peste europea':      'peste europea',
      'peste americana':    'peste americana',
      'avvelenamento':      'avvelenamento',
      'saccheggio':         'saccheggio',
      'varroa':             'varroa',
      'nosema':             'nosema',
      'tarma':              'tarma della cera',
    };
    final sorted = problemi.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final e in sorted) {
      if (t.contains(e.key)) return e.value;
    }
    return null;
  }

  bool? _extractProblemiSanitari(String t) {
    final m = RegExp(r'problem[oi]\s+sanitar').firstMatch(t);
    if (m != null) return !_negated(t, m);
    return null;
  }

  bool? _extractReginaColorata(String t) {
    if (RegExp(r'(?:ho\s+)?(?:colorat[ao]|marcat[ao])\s+(?:la\s+)?regina').hasMatch(t) ||
        RegExp(r'regina\s+(?:colorat[ao]|marcat[ao])').hasMatch(t)) {
      return true;
    }
    return null;
  }

  String? _extractColoreRegina(String t) {
    // Cerca colori solo entro 40 char da "regina"
    final reginaMatch = RegExp(r'\bregina\b').firstMatch(t);
    if (reginaMatch == null) return null;
    final start   = (reginaMatch.start - 40).clamp(0, t.length);
    final end     = (reginaMatch.end   + 40).clamp(0, t.length);
    final context = t.substring(start, end);

    const Map<String, String> colori = {
      'bianco': 'bianco', 'bianca': 'bianco',
      'giallo': 'giallo', 'gialla': 'giallo',
      'rosso':  'rosso',  'rossa':  'rosso',
      'verde':  'verde',
      'blu':    'blu',
    };
    for (final e in colori.entries) {
      if (RegExp(r'\b' + e.key + r'\b').hasMatch(context)) return e.value;
    }
    return null;
  }
}
