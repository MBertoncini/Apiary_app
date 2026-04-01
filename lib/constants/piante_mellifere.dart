class PiantaMellifera {
  final String chiave;
  final String nome;
  final String? nomeAlternativo;
  final String? nomeScientifico;
  final List<int> mesiFioritura; // 1=Gen … 12=Dic
  final String? piantaTipo; // valore compatibile con Fioritura.piantaTipoLabel
  final String? osmTagValue; // per integrazione OSM futura

  const PiantaMellifera({
    required this.chiave,
    required this.nome,
    this.nomeAlternativo,
    this.nomeScientifico,
    this.mesiFioritura = const [],
    this.piantaTipo,
    this.osmTagValue,
  });

  /// Etichetta di ricerca (include nome alternativo se presente)
  String get labelCompleta =>
      nomeAlternativo != null ? '$nome / $nomeAlternativo' : nome;

  /// Mesi di fioritura formattati (es. "Apr–Mag")
  String get periodoFormatted {
    const nomi = [
      '', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    if (mesiFioritura.isEmpty) return '';
    if (mesiFioritura.length == 1) return nomi[mesiFioritura.first];
    return '${nomi[mesiFioritura.first]}–${nomi[mesiFioritura.last]}';
  }

  static PiantaMellifera? daChiave(String chiave) {
    try {
      return tutte.firstWhere((p) => p.chiave == chiave);
    } catch (_) {
      return null;
    }
  }

  static PiantaMellifera? daNome(String nome) {
    final q = nome.toLowerCase().trim();
    try {
      return tutte.firstWhere(
        (p) =>
            p.nome.toLowerCase() == q ||
            (p.nomeAlternativo?.toLowerCase() == q),
      );
    } catch (_) {
      return null;
    }
  }

  static List<PiantaMellifera> cerca(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return tutte;
    return tutte
        .where((p) =>
            p.nome.toLowerCase().contains(q) ||
            (p.nomeAlternativo?.toLowerCase().contains(q) ?? false) ||
            (p.nomeScientifico?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  static const List<PiantaMellifera> tutte = [
    // ── Alberi ───────────────────────────────────────────────────────────────
    PiantaMellifera(
      chiave: 'robinia',
      nome: 'Acacia',
      nomeAlternativo: 'Robinia',
      nomeScientifico: 'Robinia pseudoacacia',
      mesiFioritura: [4, 5],
      piantaTipo: 'arborea',
      osmTagValue: 'robinia_pseudoacacia',
    ),
    PiantaMellifera(
      chiave: 'castagno',
      nome: 'Castagno',
      nomeScientifico: 'Castanea sativa',
      mesiFioritura: [6, 7],
      piantaTipo: 'arborea',
      osmTagValue: 'chestnut',
    ),
    PiantaMellifera(
      chiave: 'tiglio',
      nome: 'Tiglio',
      nomeScientifico: 'Tilia spp.',
      mesiFioritura: [6, 7],
      piantaTipo: 'arborea',
      osmTagValue: 'lime',
    ),
    PiantaMellifera(
      chiave: 'eucalipto',
      nome: 'Eucalipto',
      nomeScientifico: 'Eucalyptus spp.',
      mesiFioritura: [11, 12, 1, 2],
      piantaTipo: 'arborea',
      osmTagValue: 'eucalyptus',
    ),
    PiantaMellifera(
      chiave: 'agrumi',
      nome: 'Agrumi',
      nomeScientifico: 'Citrus spp.',
      mesiFioritura: [3, 4, 5],
      piantaTipo: 'arborea',
      osmTagValue: 'citrus',
    ),
    PiantaMellifera(
      chiave: 'ailanto',
      nome: 'Ailanto',
      nomeScientifico: 'Ailanthus altissima',
      mesiFioritura: [5, 6],
      piantaTipo: 'arborea',
    ),
    PiantaMellifera(
      chiave: 'ciliegio',
      nome: 'Ciliegio',
      nomeScientifico: 'Prunus avium',
      mesiFioritura: [3, 4],
      piantaTipo: 'arborea',
    ),
    PiantaMellifera(
      chiave: 'pesco',
      nome: 'Pesco',
      nomeScientifico: 'Prunus persica',
      mesiFioritura: [3, 4],
      piantaTipo: 'arborea',
    ),
    PiantaMellifera(
      chiave: 'melo',
      nome: 'Melo',
      nomeScientifico: 'Malus domestica',
      mesiFioritura: [4, 5],
      piantaTipo: 'arborea',
    ),
    // ── Arbusti ──────────────────────────────────────────────────────────────
    PiantaMellifera(
      chiave: 'rododendro',
      nome: 'Rododendro',
      nomeScientifico: 'Rhododendron spp.',
      mesiFioritura: [6, 7],
      piantaTipo: 'arbustiva',
    ),
    PiantaMellifera(
      chiave: 'lavanda',
      nome: 'Lavanda',
      nomeScientifico: 'Lavandula spp.',
      mesiFioritura: [6, 7, 8],
      piantaTipo: 'arbustiva',
    ),
    PiantaMellifera(
      chiave: 'erica',
      nome: 'Erica',
      nomeAlternativo: 'Calluna',
      nomeScientifico: 'Calluna vulgaris',
      mesiFioritura: [8, 9, 10],
      piantaTipo: 'arbustiva',
    ),
    PiantaMellifera(
      chiave: 'marruca',
      nome: 'Marruca',
      nomeAlternativo: 'Paliuro',
      nomeScientifico: 'Paliurus spina-christi',
      mesiFioritura: [5, 6, 7],
      piantaTipo: 'arbustiva',
    ),
    PiantaMellifera(
      chiave: 'rosmarino',
      nome: 'Rosmarino',
      nomeScientifico: 'Salvia rosmarinus',
      mesiFioritura: [2, 3, 4],
      piantaTipo: 'arbustiva',
    ),
    // ── Erbacee coltivate ────────────────────────────────────────────────────
    PiantaMellifera(
      chiave: 'girasole',
      nome: 'Girasole',
      nomeScientifico: 'Helianthus annuus',
      mesiFioritura: [7, 8, 9],
      piantaTipo: 'coltivata',
      osmTagValue: 'sunflower',
    ),
    PiantaMellifera(
      chiave: 'erba_medica',
      nome: 'Erba medica',
      nomeAlternativo: 'Alfalfa',
      nomeScientifico: 'Medicago sativa',
      mesiFioritura: [5, 6, 7, 8],
      piantaTipo: 'coltivata',
    ),
    PiantaMellifera(
      chiave: 'sulla',
      nome: 'Sulla',
      nomeScientifico: 'Hedysarum coronarium',
      mesiFioritura: [4, 5],
      piantaTipo: 'coltivata',
    ),
    PiantaMellifera(
      chiave: 'facelia',
      nome: 'Facelia',
      nomeScientifico: 'Phacelia tanacetifolia',
      mesiFioritura: [4, 5, 6],
      piantaTipo: 'coltivata',
    ),
    PiantaMellifera(
      chiave: 'borragine',
      nome: 'Borragine',
      nomeScientifico: 'Borago officinalis',
      mesiFioritura: [5, 6, 7, 8],
      piantaTipo: 'coltivata',
    ),
    PiantaMellifera(
      chiave: 'coriandolo',
      nome: 'Coriandolo',
      nomeScientifico: 'Coriandrum sativum',
      mesiFioritura: [5, 6],
      piantaTipo: 'coltivata',
    ),
    // ── Erbacee spontanee ────────────────────────────────────────────────────
    PiantaMellifera(
      chiave: 'trifoglio',
      nome: 'Trifoglio',
      nomeScientifico: 'Trifolium spp.',
      mesiFioritura: [5, 6, 7],
      piantaTipo: 'spontanea',
    ),
    PiantaMellifera(
      chiave: 'meliloto',
      nome: 'Meliloto',
      nomeScientifico: 'Melilotus spp.',
      mesiFioritura: [5, 6, 7, 8],
      piantaTipo: 'spontanea',
    ),
    PiantaMellifera(
      chiave: 'tarassaco',
      nome: 'Tarassaco',
      nomeAlternativo: 'Dente di leone',
      nomeScientifico: 'Taraxacum officinale',
      mesiFioritura: [3, 4, 5],
      piantaTipo: 'spontanea',
    ),
    PiantaMellifera(
      chiave: 'timo',
      nome: 'Timo',
      nomeScientifico: 'Thymus spp.',
      mesiFioritura: [5, 6, 7],
      piantaTipo: 'spontanea',
    ),
    PiantaMellifera(
      chiave: 'origano',
      nome: 'Origano',
      nomeScientifico: 'Origanum vulgare',
      mesiFioritura: [6, 7, 8],
      piantaTipo: 'spontanea',
    ),
    // ── Melate ───────────────────────────────────────────────────────────────
    PiantaMellifera(
      chiave: 'melata_abete',
      nome: 'Melata di abete',
      nomeScientifico: 'Abies spp.',
      mesiFioritura: [6, 7, 8],
      piantaTipo: 'arborea',
    ),
    PiantaMellifera(
      chiave: 'melata_quercia',
      nome: 'Melata di quercia',
      nomeScientifico: 'Quercus spp.',
      mesiFioritura: [6, 7, 8],
      piantaTipo: 'arborea',
    ),
    // ── Generico ─────────────────────────────────────────────────────────────
    PiantaMellifera(
      chiave: 'millefiori',
      nome: 'Millefiori',
      mesiFioritura: [4, 5, 6, 7, 8],
      piantaTipo: 'spontanea',
    ),
  ];
}
