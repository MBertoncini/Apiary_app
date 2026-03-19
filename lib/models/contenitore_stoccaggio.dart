class ContenitoreStoccaggio {
  final int id;
  final String nome;
  final String tipo; // secchio | bidone | fusto | altro
  final String tipoDisplay;
  final double capacitaKg;
  final double kgAttuali;
  final String tipoMiele;
  final int? maturatore;
  final String? matutatoreInfo;
  final String dataRiempimento;
  final String stato; // pieno | parziale | vuoto
  final String statoDisplay;
  final String? note;
  final String? dataRegistrazione;

  ContenitoreStoccaggio({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.tipoDisplay,
    required this.capacitaKg,
    required this.kgAttuali,
    required this.tipoMiele,
    this.maturatore,
    this.matutatoreInfo,
    required this.dataRiempimento,
    required this.stato,
    required this.statoDisplay,
    this.note,
    this.dataRegistrazione,
  });

  factory ContenitoreStoccaggio.fromJson(Map<String, dynamic> json) {
    return ContenitoreStoccaggio(
      id: json['id'],
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? 'secchio',
      tipoDisplay: json['tipo_display'] ?? json['tipo'] ?? 'Secchio',
      capacitaKg: double.tryParse(json['capacita_kg']?.toString() ?? '0') ?? 0,
      kgAttuali: double.tryParse(json['kg_attuali']?.toString() ?? '0') ?? 0,
      tipoMiele: json['tipo_miele'] ?? '',
      maturatore: json['maturatore'],
      matutatoreInfo: json['maturatore_info'],
      dataRiempimento: json['data_riempimento'] ?? '',
      stato: json['stato'] ?? 'pieno',
      statoDisplay: json['stato_display'] ?? json['stato'] ?? 'Pieno',
      note: json['note'],
      dataRegistrazione: json['data_registrazione'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'capacita_kg': capacitaKg,
      'kg_attuali': kgAttuali,
      'tipo_miele': tipoMiele,
      if (maturatore != null) 'maturatore': maturatore,
      'data_riempimento': dataRiempimento,
      'stato': stato,
      if (note != null) 'note': note,
    };
  }

  bool get isVuoto => stato == 'vuoto';
  double get percentualePieno => capacitaKg > 0 ? (kgAttuali / capacitaKg).clamp(0.0, 1.0) : 0;

  /// Quanti vasetti da [formatoG] grammi si possono fare con i kg rimanenti
  int vasettiDisponibili(int formatoG) {
    if (formatoG <= 0) return 0;
    return (kgAttuali * 1000 / formatoG).floor();
  }
}
