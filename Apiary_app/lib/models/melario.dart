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
  final String? note;
  
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
    this.note,
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
      note: json['note'],
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
      'note': note,
    };
  }
  
  bool isActive() {
    return stato == 'posizionato';
  }
}