class Maturatore {
  final int id;
  final String nome;
  final double capacitaKg;
  final double kgAttuali;
  final String tipoMiele;
  final int? smielatura;
  final String? smielaturaInfo;
  final String dataInizio;
  final int giorniMaturazione;
  final String stato; // in_maturazione | pronto | svuotato
  final String? note;
  final String? dataRegistrazione;
  final String? dataPronta;
  final int giorniRimanenti;

  Maturatore({
    required this.id,
    required this.nome,
    required this.capacitaKg,
    required this.kgAttuali,
    required this.tipoMiele,
    this.smielatura,
    this.smielaturaInfo,
    required this.dataInizio,
    required this.giorniMaturazione,
    required this.stato,
    this.note,
    this.dataRegistrazione,
    this.dataPronta,
    required this.giorniRimanenti,
  });

  factory Maturatore.fromJson(Map<String, dynamic> json) {
    return Maturatore(
      id: json['id'],
      nome: json['nome'] ?? '',
      capacitaKg: double.tryParse(json['capacita_kg']?.toString() ?? '0') ?? 0,
      kgAttuali: double.tryParse(json['kg_attuali']?.toString() ?? '0') ?? 0,
      tipoMiele: json['tipo_miele'] ?? '',
      smielatura: json['smielatura'],
      smielaturaInfo: json['smielatura_info'],
      dataInizio: json['data_inizio'] ?? '',
      giorniMaturazione: json['giorni_maturazione'] ?? 21,
      stato: json['stato'] ?? 'in_maturazione',
      note: json['note'],
      dataRegistrazione: json['data_registrazione'],
      dataPronta: json['data_pronta'],
      giorniRimanenti: json['giorni_rimanenti'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'capacita_kg': capacitaKg,
      'kg_attuali': kgAttuali,
      'tipo_miele': tipoMiele,
      if (smielatura != null) 'smielatura': smielatura,
      'data_inizio': dataInizio,
      'giorni_maturazione': giorniMaturazione,
      'stato': stato,
      if (note != null) 'note': note,
    };
  }

  bool get isPronto => stato == 'pronto';
  bool get isInMaturazione => stato == 'in_maturazione';
  bool get isSvuotato => stato == 'svuotato';
  double get percentualePieno => capacitaKg > 0 ? (kgAttuali / capacitaKg).clamp(0.0, 1.0) : 0;
}
