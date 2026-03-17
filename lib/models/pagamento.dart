// lib/models/pagamento.dart
class Pagamento {
  final int id;
  final int utente;
  final String utenteUsername;
  final int? destinatario;
  final String? destinatarioUsername;
  final double importo;
  final String data;
  final String descrizione;
  final int? gruppo;
  final String? gruppoNome;

  Pagamento({
    required this.id,
    required this.utente,
    required this.utenteUsername,
    this.destinatario,
    this.destinatarioUsername,
    required this.importo,
    required this.data,
    required this.descrizione,
    this.gruppo,
    this.gruppoNome,
  });

  bool get isSaldo => destinatario != null;

  factory Pagamento.fromJson(Map<String, dynamic> json) {
    return Pagamento(
      id: json['id'],
      utente: json['utente'],
      utenteUsername: json['utente_username'] ?? 'Sconosciuto',
      destinatario: json['destinatario'],
      destinatarioUsername: json['destinatario_username'],
      importo: double.tryParse(json['importo'].toString()) ?? 0.0,
      data: json['data'],
      descrizione: json['descrizione'],
      gruppo: json['gruppo'],
      gruppoNome: json['gruppo_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utente': utente,
      'destinatario': destinatario,
      'importo': importo,
      'data': data,
      'descrizione': descrizione,
      'gruppo': gruppo,
    };
  }
}