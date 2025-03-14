class Smielatura {
  final int id;
  final String data;
  final int apiario;
  final String apiarioNome;
  final List<int> melari;
  final int melariCount;
  final double quantitaMiele;
  final String tipoMiele;
  final int utente;
  final String utenteUsername;
  final String? note;
  final String dataRegistrazione;
  
  Smielatura({
    required this.id,
    required this.data,
    required this.apiario,
    required this.apiarioNome,
    required this.melari,
    required this.melariCount,
    required this.quantitaMiele,
    required this.tipoMiele,
    required this.utente,
    required this.utenteUsername,
    this.note,
    required this.dataRegistrazione,
  });
  
  factory Smielatura.fromJson(Map<String, dynamic> json) {
    return Smielatura(
      id: json['id'],
      data: json['data'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      melari: List<int>.from(json['melari']),
      melariCount: json['melari_count'],
      quantitaMiele: double.parse(json['quantita_miele'].toString()),
      tipoMiele: json['tipo_miele'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      note: json['note'],
      dataRegistrazione: json['data_registrazione'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'apiario': apiario,
      'apiario_nome': apiarioNome,
      'melari': melari,
      'melari_count': melariCount,
      'quantita_miele': quantitaMiele,
      'tipo_miele': tipoMiele,
      'utente': utente,
      'utente_username': utenteUsername,
      'note': note,
      'data_registrazione': dataRegistrazione,
    };
  }
}