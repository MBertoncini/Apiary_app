import '../models/pagamento.dart';

/// Categorie di pagamento usate per visualizzazione/icone nella lista
/// pagamenti. La categorizzazione è euristica e serve solo a lato UI:
/// non viene mai persistita né usata nei calcoli del bilancio.
enum PagamentoCategoria {
  /// Saldo bilancio P2P (destinatario != null).
  saldo,

  /// Spesa o acquisto legato ad attrezzatura/manutenzione.
  attrezzatura,

  /// Pagamento ordinario senza categoria specifica.
  generico,
}

/// Riconosce la categoria di un pagamento.
///
/// La detection è in due fasi:
///
/// 1. **Prefissi canonici**: i pagamenti auto-creati da
///    `AttrezzaturaService` hanno descrizioni hard-coded in italiano
///    (`Acquisto attrezzatura: …`, `Spesa attrezzatura (...)…`,
///    `Manutenzione attrezzatura: …`). Match per prefisso → 100% affidabile.
///
/// 2. **Keyword multilingua**: per descrizioni manuali, cerca parole
///    chiave italiane e inglesi. Match impreciso ma sufficiente per
///    decidere icona/colore.
class PagamentoCategorizer {
  /// Prefissi delle descrizioni auto-generate da AttrezzaturaService.
  /// Tenere allineati con i template hard-coded in `attrezzatura_service.dart`.
  static const _canonicalAttrezzaturaPrefixes = <String>[
    'acquisto attrezzatura:',
    'spesa attrezzatura',
    'manutenzione attrezzatura:',
  ];

  /// Keyword di fallback per pagamenti inseriti manualmente.
  /// Lista whole-word-ish: la match è `contains`, quindi "manutenzioni"
  /// matcha "manutenzione". Ordine non rilevante.
  static const _attrezzaturaKeywords = <String>[
    // Italiano
    'attrezzatura',
    'attrezzature',
    'manutenzione',
    'manutenzioni',
    'riparazione',
    'riparazioni',
    // Inglese
    'equipment',
    'maintenance',
    'repair',
    'tool',
    'tools',
  ];

  static PagamentoCategoria categorize(Pagamento p) {
    if (p.isSaldo) return PagamentoCategoria.saldo;

    final desc = p.descrizione.toLowerCase().trim();
    if (desc.isEmpty) return PagamentoCategoria.generico;

    for (final prefix in _canonicalAttrezzaturaPrefixes) {
      if (desc.startsWith(prefix)) return PagamentoCategoria.attrezzatura;
    }

    for (final kw in _attrezzaturaKeywords) {
      if (desc.contains(kw)) return PagamentoCategoria.attrezzatura;
    }

    return PagamentoCategoria.generico;
  }
}
