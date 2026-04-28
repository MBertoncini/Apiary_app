// lib/services/voice_language_rules.dart
//
// Language-specific rules for voice input processing.
//
// Each language provides:
//   - speechLocale: BCP-47 locale for speech_to_text (e.g. 'it_IT', 'en_US')
//   - numberWords: spoken number words → digit strings
//   - negationWords: words that negate a following match
//   - triggerWords / stopWords: batch-mode control words
//   - regex extractors for every VoiceEntry field
//   - Gemini prompt text for the audio processing path
//   - BeeVocabularyCorrector dictionary for STT corrections
//
// To add a new language:
//   1. Create a subclass of VoiceLanguageRules (e.g. VoiceRulesFr)
//   2. Register it in [VoiceLanguageRules.forCode]

import '../models/voice_entry.dart';

// ── Abstract rules ───────────────────────────────────────────────────────────

abstract class VoiceLanguageRules {
  /// BCP-47 locale for speech_to_text engine (e.g. 'it_IT', 'en_US').
  String get speechLocale;

  /// ISO 639-1 language code (e.g. 'it', 'en').
  String get code;

  /// Spoken number words → digit strings (e.g. 'three' → '3').
  Map<String, String> get numberWords;

  /// Words/prefixes that negate a following match.
  List<String> get negationWords;

  /// Words that trigger the next recording in batch mode.
  List<String> get triggerWords;

  /// Words that end the current batch session.
  List<String> get stopWords;

  /// STT vocabulary correction dictionary: misheard → correct.
  Map<String, String> get vocabularyCorrectionDict;

  /// Error message when arnia number is not recognized.
  String get errorArniaNotRecognized;

  // ── Regex extraction methods ─────────────────────────────────────────────

  int? extractArniaNumero(String t);
  bool? extractPresenzaRegina(String t);
  bool? extractReginaVista(String t);
  bool? extractUovaFresche(String t);
  bool? extractCelleReali(String t);
  int? extractNumeroCelleReali(String t);
  int? extractTelaini(String t, List<String> keywords);
  String? extractForzaFamiglia(String t);
  bool? extractSciamatura(String t);
  String? extractTipoProblema(String t);
  bool? extractProblemiSanitari(String t);
  bool? extractReginaColorata(String t);
  String? extractColoreRegina(String t);

  // ── Gemini prompt ────────────────────────────────────────────────────────

  /// Returns the full Gemini prompt for audio processing, with context info
  /// interpolated.
  String geminiPrompt(String contextInfo);

  // ── Shared helpers ─────────────────────────────────────────────────────────

  /// Normalizes text: lowercase + number-word → digit conversion.
  String normalize(String text) => _convertNumbers(text.toLowerCase());

  String _convertNumbers(String text) {
    final sorted = numberWords.entries.toList()
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

  /// True if a negation word appears within 40 chars before [match].
  bool negated(String text, Match match) {
    final start = (match.start - 40).clamp(0, text.length);
    final before = text.substring(start, match.start);
    return negationWords.any((n) => before.contains(n));
  }

  /// Extracts a full VoiceEntry from normalized text [t] and original [raw].
  VoiceEntry? extract(String t, String raw, int? apiarioId, String? apiarioNome) {
    final arniaNumero = extractArniaNumero(t);
    if (arniaNumero == null) return null;

    final tipoProblema = extractTipoProblema(t);
    final problemiSanitari = tipoProblema != null
        ? true
        : extractProblemiSanitari(t);

    return VoiceEntry(
      apiarioId: apiarioId,
      apiarioNome: apiarioNome,
      arniaNumero: arniaNumero,
      tipoComando: 'controllo',
      data: DateTime.now(),
      presenzaRegina: extractPresenzaRegina(t),
      reginaVista: extractReginaVista(t),
      uovaFresche: extractUovaFresche(t),
      celleReali: extractCelleReali(t),
      numeroCelleReali: extractNumeroCelleReali(t),
      telainiCovata: extractTelaini(t, _covataKeywords),
      telainiScorte: extractTelaini(t, _scorteKeywords),
      telainiDiaframma: extractTelaini(t, _diaframmaKeywords),
      tealiniFoglioCereo: extractTelaini(t, _foglioCereoKeywords),
      telainiNutritore: extractTelaini(t, _nutritoreKeywords),
      forzaFamiglia: extractForzaFamiglia(t),
      sciamatura: extractSciamatura(t),
      problemiSanitari: problemiSanitari,
      tipoProblema: tipoProblema,
      note: raw.trim(),
      reginaColorata: extractReginaColorata(t),
      coloreRegina: extractColoreRegina(t),
    );
  }

  /// Per-language keywords for telaini extraction. Subclasses override these.
  List<String> get _covataKeywords;
  List<String> get _scorteKeywords;
  List<String> get _diaframmaKeywords;
  List<String> get _foglioCereoKeywords;
  List<String> get _nutritoreKeywords;

  // ── Factory ────────────────────────────────────────────────────────────────

  /// Returns the rules for the given ISO 639-1 language [code].
  static VoiceLanguageRules forCode(String code) {
    switch (code) {
      case 'en':
        return VoiceRulesEn();
      default:
        return VoiceRulesIt();
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ITALIAN
// ══════════════════════════════════════════════════════════════════════════════

class VoiceRulesIt extends VoiceLanguageRules {
  @override String get speechLocale => 'it_IT';
  @override String get code => 'it';

  @override
  String get errorArniaNotRecognized =>
      'Numero arnia non riconosciuto. Pronuncia "arnia N" dove N è il numero.';

  // ── Number words ─────────────────────────────────────────────────────────
  @override
  Map<String, String> get numberWords => const {
    'diciassette': '17', 'quattordici': '14', 'diciannove': '19',
    'diciotto': '18', 'tredici': '13', 'quindici': '15',
    'sedici': '16', 'quattro': '4', 'undici': '11',
    'dodici': '12', 'venti': '20', 'cinque': '5',
    'sette': '7', 'zero': '0', 'otto': '8',
    'nove': '9', 'dieci': '10', 'due': '2',
    'sei': '6', 'tre': '3', 'una': '1', 'uno': '1',
  };

  @override
  List<String> get negationWords =>
      const ['non ', 'no ', 'senza ', 'nessun', 'assenz'];

  @override
  List<String> get triggerWords => const [
    'avanti', 'prossima', 'ok', 'okay', 'vai', 'continua',
    'registra', 'pronto', 'sì', 'si', 'inizia', 'next',
  ];

  @override
  List<String> get stopWords => const [
    'stop', 'fine', 'finito', 'basta', 'termina', 'ho finito',
  ];

  @override
  Map<String, String> get vocabularyCorrectionDict => const {
    'arma': 'arnia', 'armia': 'arnia', 'alnia': 'arnia',
    'arni': 'arnie', 'artie': 'arnie', 'annie': 'arnie',
    'appliario': 'apiario', 'appiario': 'apiario',
    'apiamo': 'apiario', 'al piario': 'apiario',
    'terreni': 'telaini', 'terrani': 'telaini',
    'terremoti': 'telaini', 'teloni': 'telaini',
    'telane': 'telaini', 'telain': 'telaini',
    'telaine': 'telaino', 'telaione': 'telaino',
    'codata': 'covata', 'cravata': 'covata', 'cravatta': 'covata',
    'corvata': 'covata', 'cubata': 'covata', 'cavata': 'covata',
    'lobata': 'covata', 'cobata': 'covata',
    'melanio': 'melario', 'melaio': 'melario', 'mellario': 'melario',
    'menari': 'melari', 'melali': 'melari',
    'resina': 'regina', 'retina': 'regina', 'vegina': 'regina',
    'reina': 'regina', 'regime': 'regine', 'resine': 'regine',
    'fucky': 'fuchi', 'fucci': 'fuchi', 'fruchi': 'fuchi', 'foco': 'fuco',
    'varro': 'varroa', 'barro': 'varroa', 'vaiolo': 'varroa',
    'barroa': 'varroa', 'varra': 'varroa', 'variola': 'varroa',
    'nosena': 'nosema', 'nossema': 'nosema',
    'chiamatura': 'sciamatura', 'ciamatura': 'sciamatura',
    'siamatura': 'sciamatura', 'schiamatura': 'sciamatura',
    'sciam atura': 'sciamatura', 'chiame': 'sciame', 'siame': 'sciame',
    'diagramma': 'diaframma', 'diagrammi': 'diaframmi',
    'dia framma': 'diaframma',
    'propolis': 'propoli', 'proprio li': 'propoli',
    'cella reale': 'celle reali', 'celle reale': 'celle reali',
    'cella reali': 'celle reali',
    'nova fresche': 'uova fresche', 'uva fresche': 'uova fresche',
    'nove fresche': 'uova fresche',
    'discorsi': 'di scorte', 'di sgorte': 'di scorte',
    'a ta': 'a tasca', 'a tazza': 'a tasca', 'a task': 'a tasca',
    'kalistrip': 'calistrip', 'callistrip': 'calistrip',
    'calli strip': 'calistrip',
    'ossalisco': 'ossalico', 'oxalico': 'ossalico',
    'smiellatura': 'smielatura', 'smieliatura': 'smielatura',
    'obercoli': 'opercoli',
    'poline': 'polline', 'polling': 'polline',
    'nutritor': 'nutritore', 'nutridor': 'nutritore',
    'inverno mento': 'invernamento', 'inver namento': 'invernamento',
    'siroppo': 'sciroppo', 'sciroppio': 'sciroppo',
    'apistanno': 'apistano', 'api stano': 'apistano',
    'bay varol': 'bayvarol', 'baivarol': 'bayvarol',
    'forte famiglia': 'famiglia forte', 'debole famiglia': 'famiglia debole',
    'normale famiglia': 'famiglia normale',
    'un un': 'un',
  };

  // ── Telaini keywords ─────────────────────────────────────────────────────
  @override List<String> get _covataKeywords => const ['covata'];
  @override List<String> get _scorteKeywords => const ['scorte', 'miele'];
  @override List<String> get _diaframmaKeywords => const ['diaframma', 'diaframmi'];
  @override List<String> get _foglioCereoKeywords => const ['foglio cereo', 'fogli cerei', 'cereo'];
  @override List<String> get _nutritoreKeywords => const ['nutritore'];

  // ── Extractors ───────────────────────────────────────────────────────────

  @override
  int? extractArniaNumero(String t) {
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

  @override
  bool? extractPresenzaRegina(String t) {
    if (RegExp(r'regina\s+assente').hasMatch(t) ||
        RegExp(r'assenz\w+\s+(?:della?\s+)?regina').hasMatch(t) ||
        RegExp(r'regina\s+non\s+(?:present|trovar)').hasMatch(t) ||
        RegExp(r'non\s+(?:trovo|ho\s+trovato)\s+(?:la\s+)?regina').hasMatch(t)) {
      return false;
    }
    if (RegExp(r'regina\s+(?:present|trovar|vista)').hasMatch(t) ||
        RegExp(r'(?:ho\s+visto|ho\s+trovato|trovata|vista)\s+(?:la\s+)?regina').hasMatch(t) ||
        RegExp(r'presenz\w+\s+(?:della?\s+)?regina').hasMatch(t)) {
      return true;
    }
    final m = RegExp(r'\bregina\b').firstMatch(t);
    if (m != null && negated(t, m)) return false;
    return null;
  }

  @override
  bool? extractReginaVista(String t) {
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

  @override
  bool? extractUovaFresche(String t) {
    if (RegExp(r'(?:no|nessun[ae]?|senza)\s+uov[ae]').hasMatch(t) ||
        RegExp(r'uov[ae]\s+assent').hasMatch(t)) {
      return false;
    }
    final m = RegExp(r'uov[ae]\s+fresch').firstMatch(t);
    if (m != null) return !negated(t, m);
    if (RegExp(r'uov[ae]\s+(?:present|trovat|viste?)').hasMatch(t)) return true;
    return null;
  }

  @override
  bool? extractCelleReali(String t) {
    final m = RegExp(r'cell[ae]\s+reali?').firstMatch(t);
    if (m == null) return null;
    return !negated(t, m);
  }

  @override
  int? extractNumeroCelleReali(String t) {
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

  @override
  int? extractTelaini(String t, List<String> keywords) {
    for (final kw in keywords) {
      final esc = RegExp.escape(kw);
      final patterns = [
        RegExp(r'(\d+)\s+telaini?\s+(?:di\s+)?' + esc),
        RegExp(r'telaini?\s+(?:di\s+)?' + esc + r'\s+(\d+)'),
        RegExp(esc + r'\s+(\d+)\s+telaini?'),
        RegExp(r'(\d+)\s+di\s+' + esc),
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

  @override
  String? extractForzaFamiglia(String t) {
    if (RegExp(r'famig\w*\s+(?:molto\s+|abbastanza\s+)?forte').hasMatch(t) ||
        RegExp(r'forza\w*\s+forte').hasMatch(t)) return 'forte';
    if (RegExp(r'famig\w*\s+(?:molto\s+|abbastanza\s+)?debole').hasMatch(t) ||
        RegExp(r'forza\w*\s+debole').hasMatch(t)) return 'debole';
    if (RegExp(r'famig\w*\s+normale').hasMatch(t) ||
        RegExp(r'forza\w*\s+normale').hasMatch(t)) return 'normale';
    return null;
  }

  @override
  bool? extractSciamatura(String t) {
    final m = RegExp(r'sciamatur[ae]|rischio\s+sciam').firstMatch(t);
    if (m == null) return null;
    return !negated(t, m);
  }

  @override
  String? extractTipoProblema(String t) {
    const Map<String, String> problemi = {
      'covata calcificata': 'covata calcificata',
      'covata gessata': 'covata gessata',
      'peste europea': 'peste europea',
      'peste americana': 'peste americana',
      'avvelenamento': 'avvelenamento',
      'saccheggio': 'saccheggio',
      'varroa': 'varroa',
      'nosema': 'nosema',
      'tarma': 'tarma della cera',
    };
    final sorted = problemi.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final e in sorted) {
      if (t.contains(e.key)) return e.value;
    }
    return null;
  }

  @override
  bool? extractProblemiSanitari(String t) {
    final m = RegExp(r'problem[oi]\s+sanitar').firstMatch(t);
    if (m != null) return !negated(t, m);
    return null;
  }

  @override
  bool? extractReginaColorata(String t) {
    if (RegExp(r'(?:ho\s+)?(?:colorat[ao]|marcat[ao])\s+(?:la\s+)?regina').hasMatch(t) ||
        RegExp(r'regina\s+(?:colorat[ao]|marcat[ao])').hasMatch(t)) {
      return true;
    }
    return null;
  }

  @override
  String? extractColoreRegina(String t) {
    final reginaMatch = RegExp(r'\bregina\b').firstMatch(t);
    if (reginaMatch == null) return null;
    final start = (reginaMatch.start - 40).clamp(0, t.length);
    final end = (reginaMatch.end + 40).clamp(0, t.length);
    final ctx = t.substring(start, end);

    const Map<String, String> colori = {
      'bianco': 'bianco', 'bianca': 'bianco',
      'giallo': 'giallo', 'gialla': 'giallo',
      'rosso': 'rosso', 'rossa': 'rosso',
      'verde': 'verde', 'blu': 'blu',
    };
    for (final e in colori.entries) {
      if (RegExp(r'\b' + e.key + r'\b').hasMatch(ctx)) return e.value;
    }
    return null;
  }

  // ── Gemini prompt ────────────────────────────────────────────────────────

  @override
  String geminiPrompt(String contextInfo) => '''
Sei un assistente per apicoltori. Ascolta questa registrazione audio di un apicoltore
e estrai i dati strutturati. L'audio può descrivere un normale controllo,
la creazione di una nuova arnia, un trattamento o altre operazioni.

$contextInfo

Rispondi SOLO con un oggetto JSON valido (nessun testo aggiuntivo, nessun markdown):
$_jsonSchema

Regole:
- Se l'audio descrive una normale ispezione, tipo_comando = "controllo"
- Se l'apicoltore dice "crea una nuova arnia", "nuova arnia", "ho creato un'arnia",
  imposta tipo_comando = "creazione_arnia" e ignora gli altri campi.
- Se viene menzionato un trattamento (es. "trattamento con acido ossalico",
  "ho trattato con Apivar"), imposta tipo_comando = "trattamento" e
  nome_trattamento con il nome del prodotto.
- Se viene menzionata una "sostituzione della scatola" o "cambio cassa",
  imposta sostituzione_scatola = true. Questo può essere parte di un controllo.

Regole per il controllo:
- Se viene menzionato "arnia N", arnia_numero = N
- "famiglia forte/normale/debole" → forza_famiglia (usa sempre i valori italiani: "debole", "normale", "forte")
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
- Se viene menzionato un colore insieme alla regina → colore_regina (usa sempre i valori italiani: "bianco", "giallo", "rosso", "verde", "blu")
- Le osservazioni non strutturate vanno in note
''';
}

// ══════════════════════════════════════════════════════════════════════════════
// ENGLISH
// ══════════════════════════════════════════════════════════════════════════════

class VoiceRulesEn extends VoiceLanguageRules {
  @override String get speechLocale => 'en_US';
  @override String get code => 'en';

  @override
  String get errorArniaNotRecognized =>
      'Hive number not recognized. Say "hive N" where N is the number.';

  // ── Number words ─────────────────────────────────────────────────────────
  @override
  Map<String, String> get numberWords => const {
    'seventeen': '17', 'fourteen': '14', 'nineteen': '19',
    'eighteen': '18', 'thirteen': '13', 'fifteen': '15',
    'sixteen': '16', 'twenty': '20', 'eleven': '11',
    'twelve': '12', 'four': '4', 'five': '5',
    'seven': '7', 'zero': '0', 'eight': '8',
    'nine': '9', 'ten': '10', 'two': '2',
    'six': '6', 'three': '3', 'one': '1',
  };

  @override
  List<String> get negationWords =>
      const ['not ', 'no ', 'without ', 'none', 'absent', "didn't ", "don't ", "can't "];

  @override
  List<String> get triggerWords => const [
    'next', 'ok', 'okay', 'go', 'continue',
    'record', 'ready', 'yes', 'start',
  ];

  @override
  List<String> get stopWords => const [
    'stop', 'done', 'finished', 'enough', 'end', "i'm done",
  ];

  @override
  Map<String, String> get vocabularyCorrectionDict => const {
    // ── Hive / Hives ───────────────────────────────────────────────────────
    'hide': 'hive', 'hype': 'hive', 'hi': 'hive',
    'hives': 'hives',
    // ── Queen ──────────────────────────────────────────────────────────────
    'cream': 'queen', 'clean': 'queen',
    // ── Brood ──────────────────────────────────────────────────────────────
    'brewed': 'brood', 'brude': 'brood', 'bruised': 'brood',
    // ── Frames ─────────────────────────────────────────────────────────────
    'trains': 'frames', 'flames': 'frames',
    // ── Varroa ─────────────────────────────────────────────────────────────
    'baroa': 'varroa', 'varoa': 'varroa', 'faroa': 'varroa',
    // ── Nosema ─────────────────────────────────────────────────────────────
    'no see ma': 'nosema', 'no seema': 'nosema',
    // ── Swarming ───────────────────────────────────────────────────────────
    'storming': 'swarming', 'warming': 'swarming',
    // ── Queen cells ────────────────────────────────────────────────────────
    'clean cells': 'queen cells', 'cream cells': 'queen cells',
    // ── Foundation ─────────────────────────────────────────────────────────
    'funded asian': 'foundation', 'fun nation': 'foundation',
    // ── Feeder ─────────────────────────────────────────────────────────────
    'theater': 'feeder', 'peter': 'feeder',
    // ── Colony strength reorder ────────────────────────────────────────────
    'strong colony': 'colony strong',
    'weak colony': 'colony weak',
    'normal colony': 'colony normal',
  };

  // ── Telaini keywords (English beekeeping terms) ──────────────────────────
  @override List<String> get _covataKeywords => const ['brood'];
  @override List<String> get _scorteKeywords => const ['honey', 'stores'];
  @override List<String> get _diaframmaKeywords => const ['divider', 'follower', 'follower board'];
  @override List<String> get _foglioCereoKeywords => const ['foundation', 'wax foundation', 'wax sheet'];
  @override List<String> get _nutritoreKeywords => const ['feeder'];

  // ── Extractors ───────────────────────────────────────────────────────────

  @override
  int? extractArniaNumero(String t) {
    final patterns = [
      RegExp(r'hives?\s*(?:number\s*|n\.?\s*)?(\d+)'),
      RegExp(r'(?:number|n\.?)\s+hives?\s*(\d+)'),
      RegExp(r'box\s*(?:number\s*)?(\d+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(t);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  @override
  bool? extractPresenzaRegina(String t) {
    // Absence
    if (RegExp(r'queen\s+absent').hasMatch(t) ||
        RegExp(r'absenc\w+\s+(?:of\s+(?:the\s+)?)?queen').hasMatch(t) ||
        RegExp(r'queen\s+not\s+(?:present|found)').hasMatch(t) ||
        RegExp(r"(?:can'?t|cannot|couldn'?t)\s+find\s+(?:the\s+)?queen").hasMatch(t) ||
        RegExp(r"(?:didn'?t|did\s+not)\s+(?:find|see)\s+(?:the\s+)?queen").hasMatch(t) ||
        RegExp(r'no\s+queen').hasMatch(t)) {
      return false;
    }
    // Presence
    if (RegExp(r'queen\s+(?:present|found|seen|spotted)').hasMatch(t) ||
        RegExp(r'(?:i\s+)?(?:saw|found|spotted)\s+(?:the\s+)?queen').hasMatch(t) ||
        RegExp(r'(?:queen\s+is\s+there|queen\s+is\s+present)').hasMatch(t)) {
      return true;
    }
    final m = RegExp(r'\bqueen\b').firstMatch(t);
    if (m != null && negated(t, m)) return false;
    return null;
  }

  @override
  bool? extractReginaVista(String t) {
    if (RegExp(r'queen\s+not\s+(?:seen|spotted|sighted)').hasMatch(t) ||
        RegExp(r"(?:didn'?t|did\s+not)\s+see\s+(?:the\s+)?queen").hasMatch(t)) {
      return false;
    }
    if (RegExp(r'(?:i\s+)?(?:saw|seen|spotted|sighted)\s+(?:the\s+)?queen').hasMatch(t) ||
        RegExp(r'queen\s+(?:seen|spotted|sighted)').hasMatch(t)) {
      return true;
    }
    return null;
  }

  @override
  bool? extractUovaFresche(String t) {
    if (RegExp(r'(?:no|without)\s+(?:fresh\s+)?eggs').hasMatch(t) ||
        RegExp(r'eggs?\s+absent').hasMatch(t)) {
      return false;
    }
    final m = RegExp(r'fresh\s+eggs').firstMatch(t);
    if (m != null) return !negated(t, m);
    if (RegExp(r'eggs?\s+(?:present|found|seen)').hasMatch(t)) return true;
    return null;
  }

  @override
  bool? extractCelleReali(String t) {
    final m = RegExp(r'queen\s+cells?').firstMatch(t);
    if (m == null) return null;
    return !negated(t, m);
  }

  @override
  int? extractNumeroCelleReali(String t) {
    final patterns = [
      RegExp(r'(\d+)\s+queen\s+cells?'),
      RegExp(r'queen\s+cells?\s+(\d+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(t);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  @override
  int? extractTelaini(String t, List<String> keywords) {
    for (final kw in keywords) {
      final esc = RegExp.escape(kw);
      final patterns = [
        // "3 frames of brood" / "3 brood frames"
        RegExp(r'(\d+)\s+frames?\s+(?:of\s+)?' + esc),
        RegExp(r'(\d+)\s+' + esc + r'\s+frames?'),
        RegExp(r'frames?\s+(?:of\s+)?' + esc + r'\s+(\d+)'),
        RegExp(esc + r'\s+(\d+)\s+frames?'),
        RegExp(r'(\d+)\s+(?:of\s+)?' + esc + r'\b'),
        RegExp(r'\b' + esc + r'\s+(\d+)'),
      ];
      for (final p in patterns) {
        final m = p.firstMatch(t);
        if (m != null) return int.tryParse(m.group(1)!);
      }
    }
    return null;
  }

  @override
  String? extractForzaFamiglia(String t) {
    // Returns Italian DB values regardless of input language
    if (RegExp(r'colon\w*\s+(?:very\s+|quite\s+)?strong').hasMatch(t) ||
        RegExp(r'strong\s+colon').hasMatch(t) ||
        RegExp(r'strength\s+strong').hasMatch(t)) return 'forte';
    if (RegExp(r'colon\w*\s+(?:very\s+|quite\s+)?weak').hasMatch(t) ||
        RegExp(r'weak\s+colon').hasMatch(t) ||
        RegExp(r'strength\s+weak').hasMatch(t)) return 'debole';
    if (RegExp(r'colon\w*\s+normal').hasMatch(t) ||
        RegExp(r'normal\s+colon').hasMatch(t) ||
        RegExp(r'strength\s+normal').hasMatch(t)) return 'normale';
    return null;
  }

  @override
  bool? extractSciamatura(String t) {
    final m = RegExp(r'swarm(?:ing|ed)?|risk\s+(?:of\s+)?swarm').firstMatch(t);
    if (m == null) return null;
    return !negated(t, m);
  }

  @override
  String? extractTipoProblema(String t) {
    // Returns Italian DB values regardless of input language
    const Map<String, String> problems = {
      'chalkbrood': 'covata calcificata',
      'chalk brood': 'covata calcificata',
      'stonebrood': 'covata gessata',
      'stone brood': 'covata gessata',
      'european foulbrood': 'peste europea',
      'european foul brood': 'peste europea',
      'american foulbrood': 'peste americana',
      'american foul brood': 'peste americana',
      'poisoning': 'avvelenamento',
      'robbing': 'saccheggio',
      'varroa': 'varroa',
      'nosema': 'nosema',
      'wax moth': 'tarma della cera',
    };
    final sorted = problems.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final e in sorted) {
      if (t.contains(e.key)) return e.value;
    }
    return null;
  }

  @override
  bool? extractProblemiSanitari(String t) {
    final m = RegExp(r'health\s+(?:problem|issue)|(?:disease|sick|infect)').firstMatch(t);
    if (m != null) return !negated(t, m);
    return null;
  }

  @override
  bool? extractReginaColorata(String t) {
    if (RegExp(r'(?:i\s+)?(?:marked|painted|colored|coloured)\s+(?:the\s+)?queen').hasMatch(t) ||
        RegExp(r'queen\s+(?:marked|painted|colored|coloured)').hasMatch(t)) {
      return true;
    }
    return null;
  }

  @override
  String? extractColoreRegina(String t) {
    final queenMatch = RegExp(r'\bqueen\b').firstMatch(t);
    if (queenMatch == null) return null;
    final start = (queenMatch.start - 40).clamp(0, t.length);
    final end = (queenMatch.end + 40).clamp(0, t.length);
    final ctx = t.substring(start, end);

    // Returns Italian DB values
    const Map<String, String> colors = {
      'white': 'bianco',
      'yellow': 'giallo',
      'red': 'rosso',
      'green': 'verde',
      'blue': 'blu',
    };
    for (final e in colors.entries) {
      if (RegExp(r'\b' + e.key + r'\b').hasMatch(ctx)) return e.value;
    }
    return null;
  }

  // ── Gemini prompt ────────────────────────────────────────────────────────

  @override
  String geminiPrompt(String contextInfo) => '''
You are a beekeeping assistant. Listen to this audio recording of a beekeeper
describing a hive inspection and extract structured data. The audio can describe
a normal inspection, the creation of a new hive, a treatment, or other operations.

$contextInfo

Respond ONLY with a valid JSON object (no extra text, no markdown):
$_jsonSchema

Rules:
- If the audio describes a normal inspection, set tipo_comando = "controllo"
- If the beekeeper says "create a new hive", "new hive", "I created a hive",
  set tipo_comando = "creazione_arnia" and ignore other fields.
- If a treatment is mentioned (e.g. "treatment with oxalic acid",
  "I treated with Apivar"), set tipo_comando = "trattamento" and
  nome_trattamento with the product name.
- If "box replacement" or "changed the box" is mentioned,
  set sostituzione_scatola = true. This can be part of a "controllo".

Rules for an inspection ("controllo"):
- If "hive N" or "box N" is mentioned, arnia_numero = N
- "colony strong/normal/weak" → forza_famiglia (ALWAYS use Italian values: "debole", "normale", "forte")
- "queen present" → presenza_regina = true, regina_vista = false
- "queen seen" or "I saw the queen" → presenza_regina = true, regina_vista = true
- "queen absent" or "no queen" → presenza_regina = false, regina_vista = false
- "queen cells" → celle_reali = true; if a number is given, numero_celle_reali
- "swarming" or "risk of swarming" → sciamatura = true
- "health problems", "varroa", "nosema", "chalkbrood" → problemi_sanitari = true + tipo_problema (use Italian: "varroa", "nosema", "covata calcificata", "peste europea", "peste americana", "avvelenamento", "saccheggio", "tarma della cera")
- "divider"/"follower board" → telaini_diaframma (integer)
- "foundation"/"wax sheet" → telaini_foglio_cereo (integer)
- "feeder" → telaini_nutritore (integer)
- DO NOT calculate telaini_totali
- "I marked the queen" or "painted the queen" → regina_colorata = true
- If a color is mentioned with the queen → colore_regina (ALWAYS use Italian values: "bianco", "giallo", "rosso", "verde", "blu")
- Unstructured observations go in note
''';
}

// ── Shared JSON schema (same for all languages) ──────────────────────────────

const String _jsonSchema = '''
{
  "tipo_comando": <"controllo"/"creazione_arnia"/"trattamento" or null>,
  "arnia_numero": <integer or null>,
  "presenza_regina": <true/false or null>,
  "regina_vista": <true/false or null>,
  "uova_fresche": <true/false or null>,
  "celle_reali": <true/false or null>,
  "numero_celle_reali": <integer or null>,
  "telaini_covata": <integer or null>,
  "telaini_scorte": <integer or null>,
  "telaini_diaframma": <integer or null>,
  "telaini_foglio_cereo": <integer or null>,
  "telaini_nutritore": <integer or null>,
  "forza_famiglia": <"debole"/"normale"/"forte" or null>,
  "sciamatura": <true/false or null>,
  "problemi_sanitari": <true/false or null>,
  "tipo_problema": <string or null>,
  "note": <string or null>,
  "regina_colorata": <true/false or null>,
  "colore_regina": <"bianco"/"giallo"/"rosso"/"verde"/"blu" or null>,
  "sostituzione_scatola": <true/false or null>,
  "nome_trattamento": <string or null>
}''';
