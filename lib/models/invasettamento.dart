class Invasettamento {
  final int id;
  final String data;
  final int? smielatura;
  final String? smielaturaInfo;
  final int? contenitore;
  final String? contenitoreInfo;
  final String tipoMiele;
  final int formatoVasetto;
  final int numeroVasetti;
  final String? lotto;
  final int utente;
  final String? utenteUsername;
  final String? note;
  final String? dataRegistrazione;
  final double? kgTotali;
  final String? apiarioGruppoNome;

  Invasettamento({
    required this.id,
    required this.data,
    this.smielatura,
    this.smielaturaInfo,
    this.contenitore,
    this.contenitoreInfo,
    required this.tipoMiele,
    required this.formatoVasetto,
    required this.numeroVasetti,
    this.lotto,
    required this.utente,
    this.utenteUsername,
    this.note,
    this.dataRegistrazione,
    this.kgTotali,
    this.apiarioGruppoNome,
  });

  factory Invasettamento.fromJson(Map<String, dynamic> json) {
    return Invasettamento(
      id: json['id'],
      data: json['data'],
      smielatura: json['smielatura'],
      smielaturaInfo: json['smielatura_info'],
      contenitore: json['contenitore'],
      contenitoreInfo: json['contenitore_info'],
      tipoMiele: json['tipo_miele'],
      formatoVasetto: json['formato_vasetto'],
      numeroVasetti: json['numero_vasetti'],
      lotto: json['lotto'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      note: json['note'],
      dataRegistrazione: json['data_registrazione'],
      kgTotali: double.tryParse(json['kg_totali']?.toString() ?? ''),
      apiarioGruppoNome: json['apiario_gruppo_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      if (smielatura != null) 'smielatura': smielatura,
      if (contenitore != null) 'contenitore': contenitore,
      'tipo_miele': tipoMiele,
      'formato_vasetto': formatoVasetto,
      'numero_vasetti': numeroVasetti,
      if (lotto != null) 'lotto': lotto,
      if (note != null) 'note': note,
    };
  }
}
