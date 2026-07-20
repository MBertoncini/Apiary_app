class Smielatura {
  final int id;
  final String data;
  final int apiario;
  final String apiarioNome;
  final List<int> melari;
  final int melariCount;
  /// IDs delle fioriture associate al raccolto (utili per modelli ML).
  final List<int> fioriture;
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
    this.fioriture = const [],
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
      melari: json['melari'] != null ? List<int>.from(json['melari']) : [],
      melariCount: json['melari_count'] ?? 0,
      fioriture: json['fioriture'] != null
          ? List<int>.from(json['fioriture'])
          : const [],
      quantitaMiele: double.tryParse(json['quantita_miele'].toString()) ?? 0.0,
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
      'fioriture': fioriture,
      'quantita_miele': quantitaMiele,
      'tipo_miele': tipoMiele,
      'utente': utente,
      'utente_username': utenteUsername,
      'note': note,
      'data_registrazione': dataRegistrazione,
    };
  }
}