class Invasettamento {
  final int id;
  final String data;
  final int smielatura;
  final String? smielaturaInfo;
  final String tipoMiele;
  final int formatoVasetto;
  final int numeroVasetti;
  final String? lotto;
  final int utente;
  final String? utenteUsername;
  final String? note;
  final String? dataRegistrazione;
  final double? kgTotali;

  Invasettamento({
    required this.id,
    required this.data,
    required this.smielatura,
    this.smielaturaInfo,
    required this.tipoMiele,
    required this.formatoVasetto,
    required this.numeroVasetti,
    this.lotto,
    required this.utente,
    this.utenteUsername,
    this.note,
    this.dataRegistrazione,
    this.kgTotali,
  });

  factory Invasettamento.fromJson(Map<String, dynamic> json) {
    return Invasettamento(
      id: json['id'],
      data: json['data'],
      smielatura: json['smielatura'],
      smielaturaInfo: json['smielatura_info'],
      tipoMiele: json['tipo_miele'],
      formatoVasetto: json['formato_vasetto'],
      numeroVasetti: json['numero_vasetti'],
      lotto: json['lotto'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      note: json['note'],
      dataRegistrazione: json['data_registrazione'],
      kgTotali: double.tryParse(json['kg_totali']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'smielatura': smielatura,
      'tipo_miele': tipoMiele,
      'formato_vasetto': formatoVasetto,
      'numero_vasetti': numeroVasetti,
      'lotto': lotto,
      'note': note,
    };
  }
}
