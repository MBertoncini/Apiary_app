class PreferenzaMaturazione {
  final int? id;
  final String tipoMiele;
  final int giorniMaturazione;

  PreferenzaMaturazione({
    this.id,
    required this.tipoMiele,
    required this.giorniMaturazione,
  });

  factory PreferenzaMaturazione.fromJson(Map<String, dynamic> json) {
    return PreferenzaMaturazione(
      id: json['id'],
      tipoMiele: json['tipo_miele'] ?? '',
      giorniMaturazione: json['giorni_maturazione'] ?? 21,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_miele': tipoMiele,
      'giorni_maturazione': giorniMaturazione,
    };
  }

  static const Map<String, int> defaults = {
    'acacia': 14,
    'millefiori': 21,
    'castagno': 28,
    'girasole': 14,
    'tiglio': 21,
    'eucalipto': 21,
    'rododendro': 21,
  };

  static int defaultForTipo(String tipo) {
    final lower = tipo.toLowerCase().trim();
    for (final entry in defaults.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 21;
  }
}
