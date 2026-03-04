class Melario {
  final int id;
  final int arnia;
  final int arniaNumero;
  final int apiarioId;
  final String apiarioNome;
  final int numeroTelaini;
  final int posizione;
  final String dataPosizionamento;
  final String? dataRimozione;
  final String stato;
  final String tipoMelario;
  final String statoFavi;
  final bool escludiRegina;
  final double? pesoStimato;
  final String? note;
  final String? apiarioGruppoNome;

  Melario({
    required this.id,
    required this.arnia,
    required this.arniaNumero,
    required this.apiarioId,
    required this.apiarioNome,
    required this.numeroTelaini,
    required this.posizione,
    required this.dataPosizionamento,
    this.dataRimozione,
    required this.stato,
    this.tipoMelario = 'standard',
    this.statoFavi = 'costruiti',
    this.escludiRegina = true,
    this.pesoStimato,
    this.note,
    this.apiarioGruppoNome,
  });

  factory Melario.fromJson(Map<String, dynamic> json) {
    return Melario(
      id: json['id'],
      arnia: json['arnia'],
      arniaNumero: json['arnia_numero'],
      apiarioId: json['apiario_id'],
      apiarioNome: json['apiario_nome'],
      numeroTelaini: json['numero_telaini'],
      posizione: json['posizione'],
      dataPosizionamento: json['data_posizionamento'],
      dataRimozione: json['data_rimozione'],
      stato: json['stato'],
      tipoMelario: json['tipo_melario'] ?? 'standard',
      statoFavi: json['stato_favi'] ?? 'costruiti',
      escludiRegina: json['escludi_regina'] ?? true,
      pesoStimato: double.tryParse(json['peso_stimato']?.toString() ?? ''),
      note: json['note'],
      apiarioGruppoNome: json['apiario_gruppo_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arnia': arnia,
      'arnia_numero': arniaNumero,
      'apiario_id': apiarioId,
      'apiario_nome': apiarioNome,
      'numero_telaini': numeroTelaini,
      'posizione': posizione,
      'data_posizionamento': dataPosizionamento,
      'data_rimozione': dataRimozione,
      'stato': stato,
      'tipo_melario': tipoMelario,
      'stato_favi': statoFavi,
      'escludi_regina': escludiRegina,
      'peso_stimato': pesoStimato,
      'note': note,
    };
  }
  
  bool isActive() {
    return stato == 'posizionato';
  }
}