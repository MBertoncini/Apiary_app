// lib/services/bee_vocabulary_corrector.dart
//
// Applies a beekeeping-domain vocabulary correction dictionary to raw STT
// output. The corrector is a singleton: BeeVocabularyCorrector().
//
// [correctText]    → plain corrected String (for Gemini).
// [correctSegments] → List<TextSegment> (for the UI widget with animations).

// ── Data model ────────────────────────────────────────────────────────────────

abstract class TextSegment {
  const TextSegment();
  /// The "right" text this segment contributes to the final string.
  String get displayText;
}

/// Plain text with no correction needed.
class NormalSegment extends TextSegment {
  final String text;
  const NormalSegment(this.text);
  @override
  String get displayText => text;
}

/// A word (or phrase) the STT got wrong, and what it should be.
class CorrectedSegment extends TextSegment {
  final String original;  // what STT said
  final String corrected; // what we want
  const CorrectedSegment({required this.original, required this.corrected});
  @override
  String get displayText => corrected;
}

// ── Corrector ─────────────────────────────────────────────────────────────────

/// Singleton vocabulary corrector for beekeeping STT output.
/// Supports switching dictionaries at runtime via [setDictionary].
class BeeVocabularyCorrector {
  static final BeeVocabularyCorrector _instance = BeeVocabularyCorrector._();
  factory BeeVocabularyCorrector() => _instance;
  BeeVocabularyCorrector._() {
    _rebuildEntries(_dict);
  }

  late List<MapEntry<String, String>> _entries;
  Map<String, String> _activeDict = _dict;

  /// Replaces the correction dictionary (e.g. when the user switches language).
  /// Pass the `vocabularyCorrectionDict` from [VoiceLanguageRules].
  void setDictionary(Map<String, String> dict) {
    if (identical(dict, _activeDict)) return;
    _activeDict = dict;
    _rebuildEntries(dict);
  }

  void _rebuildEntries(Map<String, String> dict) {
    _entries = dict.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
  }

  // ── Dictionary ─────────────────────────────────────────────────────────────
  // Keys: lowercase, as the STT might say them.
  // Values: correct Italian beekeeping term.
  // Multi-word keys are supported (e.g. 'a ta' → 'a tasca').
  static const Map<String, String> _dict = {

    // ── Arnia / Arnie ─────────────────────────────────────────────────────────
    'arma':             'arnia',
    'armia':            'arnia',
    'alnia':            'arnia',
    'arni':             'arnie',
    'artie':            'arnie',
    'annie':            'arnie',

    // ── Apiario ───────────────────────────────────────────────────────────────
    'appliario':        'apiario',
    'appiario':         'apiario',
    'apiamo':           'apiario',
    'al piario':        'apiario',

    // ── Telaini / Telaino ─────────────────────────────────────────────────────
    'terreni':          'telaini',
    'terrani':          'telaini',
    'terremoti':        'telaini',
    'teloni':           'telaini',
    'telane':           'telaini',
    'telain':           'telaini',
    'telaine':          'telaino',
    'telaione':         'telaino',

    // ── Covata ────────────────────────────────────────────────────────────────
    'codata':           'covata',
    'cravata':          'covata',
    'cravatta':         'covata',
    'corvata':          'covata',
    'cubata':           'covata',
    'cavata':           'covata',
    'lobata':           'covata',
    'cobata':           'covata',
    'covate':           'covate',   // correct plural — kept for logging guard

    // ── Melario / Melari ──────────────────────────────────────────────────────
    'melanio':          'melario',
    'melaio':           'melario',
    'mellario':         'melario',
    'menari':           'melari',
    'melali':           'melari',
    'melario':          'melario',  // already correct — no-op (filtered below)

    // ── Regina / Regine ───────────────────────────────────────────────────────
    'resina':           'regina',
    'retina':           'regina',
    'vegina':           'regina',
    'reina':            'regina',
    'regime':           'regine',
    'resine':           'regine',

    // ── Fuchi / Fuco ──────────────────────────────────────────────────────────
    'fucky':            'fuchi',
    'fucci':            'fuchi',
    'fruchi':           'fuchi',
    'foco':             'fuco',

    // ── Varroa ────────────────────────────────────────────────────────────────
    'varro':            'varroa',
    'barro':            'varroa',
    'vaiolo':           'varroa',
    'barroa':           'varroa',
    'varra':            'varroa',
    'variola':          'varroa',

    // ── Nosema ────────────────────────────────────────────────────────────────
    'nosena':           'nosema',
    'nossema':          'nosema',

    // ── Sciamatura / Sciame ───────────────────────────────────────────────────
    'chiamatura':       'sciamatura',
    'ciamatura':        'sciamatura',
    'siamatura':        'sciamatura',
    'schiamatura':      'sciamatura',
    'sciam atura':      'sciamatura',   // multi-word
    'chiame':           'sciame',
    'siame':            'sciame',

    // ── Diaframma / Diaframmi ─────────────────────────────────────────────────
    'diagramma':        'diaframma',
    'diagrammi':        'diaframmi',
    'dia framma':       'diaframma',   // multi-word

    // ── Propoli ───────────────────────────────────────────────────────────────
    'propolis':         'propoli',
    'proprio li':       'propoli',     // multi-word

    // ── Celle reali ───────────────────────────────────────────────────────────
    'cella reale':      'celle reali', // multi-word
    'celle reale':      'celle reali', // multi-word
    'cella reali':      'celle reali', // multi-word

    // ── Uova fresche ──────────────────────────────────────────────────────────
    'nova fresche':     'uova fresche', // multi-word
    'uva fresche':      'uova fresche', // multi-word
    'nove fresche':     'uova fresche', // multi-word

    // ── Scorte ────────────────────────────────────────────────────────────────
    'discorsi':         'di scorte',
    'di sgorte':        'di scorte',   // multi-word

    // ── A tasca ───────────────────────────────────────────────────────────────
    'a ta':             'a tasca',     // multi-word
    'a tazza':          'a tasca',     // multi-word
    'a task':           'a tasca',     // multi-word

    // ── Calistrip ─────────────────────────────────────────────────────────────
    'kalistrip':        'calistrip',
    'callistrip':       'calistrip',
    'calli strip':      'calistrip',   // multi-word

    // ── Acido ossalico ────────────────────────────────────────────────────────
    'ossalisco':        'ossalico',
    'oxalico':          'ossalico',

    // ── Smielatura ────────────────────────────────────────────────────────────
    'smiellatura':      'smielatura',
    'smieliatura':      'smielatura',

    // ── Opercoli ──────────────────────────────────────────────────────────────
    'obercoli':         'opercoli',

    // ── Polline ───────────────────────────────────────────────────────────────
    'poline':           'polline',
    'polling':          'polline',

    // ── Nutritore ─────────────────────────────────────────────────────────────
    'nutritor':         'nutritore',
    'nutridor':         'nutritore',

    // ── Invernamento ──────────────────────────────────────────────────────────
    'inverno mento':    'invernamento', // multi-word
    'inver namento':    'invernamento', // multi-word

    // ── Sciroppo ──────────────────────────────────────────────────────────────
    'siroppo':          'sciroppo',
    'sciroppio':        'sciroppo',

    // ── Apistano ──────────────────────────────────────────────────────────────
    'apistanno':        'apistano',
    'api stano':        'apistano',    // multi-word

    // ── Bayvarol ──────────────────────────────────────────────────────────────
    'bay varol':        'bayvarol',    // multi-word
    'baivarol':         'bayvarol',

    // ── Ordine parole forza famiglia ─────────────────────────────────────────
    'forte famiglia':   'famiglia forte',   // multi-word
    'debole famiglia':  'famiglia debole',  // multi-word
    'normale famiglia': 'famiglia normale', // multi-word

    // ── Duplicati fonetici ────────────────────────────────────────────────────
    'un un':            'un',              // multi-word
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the corrected plain string, suitable for sending to Gemini.
  String correctText(String text) =>
      correctSegments(text).map((s) => s.displayText).join('');

  /// Returns [text] split into [TextSegment]s with corrections applied.
  /// Use this for the UI so corrections can be highlighted with animations.
  List<TextSegment> correctSegments(String text) {
    if (text.trim().isEmpty) return [NormalSegment(text)];

    final lower = text.toLowerCase();

    // Collect non-overlapping matches (longest-key-first guarantees priority).
    final matched =
        <({int start, int end, String original, String corrected})>[];

    for (final e in _entries) {
      final escaped = RegExp.escape(e.key);
      // Word-boundary anchors: \b works correctly at space/letter boundaries,
      // including the internal spaces of multi-word keys.
      final pattern =
          RegExp(r'\b' + escaped + r'\b', caseSensitive: false);

      for (final m in pattern.allMatches(lower)) {
        final overlaps =
            matched.any((r) => m.start < r.end && m.end > r.start);
        if (!overlaps) {
          final orig = text.substring(m.start, m.end);
          matched.add((
            start: m.start,
            end: m.end,
            original: orig,
            corrected: _matchCase(orig, e.value),
          ));
        }
      }
    }

    if (matched.isEmpty) return [NormalSegment(text)];

    matched.sort((a, b) => a.start.compareTo(b.start));

    final segs = <TextSegment>[];
    int pos = 0;

    for (final m in matched) {
      if (pos < m.start) segs.add(NormalSegment(text.substring(pos, m.start)));

      // Emit CorrectedSegment only when the text actually changes.
      if (m.original.toLowerCase() != m.corrected.toLowerCase()) {
        segs.add(
            CorrectedSegment(original: m.original, corrected: m.corrected));
      } else {
        segs.add(NormalSegment(m.original));
      }
      pos = m.end;
    }

    if (pos < text.length) segs.add(NormalSegment(text.substring(pos)));

    return segs;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// If the original starts with an uppercase letter, capitalise the corrected
  /// form too (e.g. "Terreni" → "Telaini").
  static String _matchCase(String original, String corrected) {
    if (original.isEmpty || corrected.isEmpty) return corrected;
    if (original[0] != original[0].toLowerCase()) {
      return corrected[0].toUpperCase() + corrected.substring(1);
    }
    return corrected;
  }
}
