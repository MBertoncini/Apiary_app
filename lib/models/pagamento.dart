// lib/models/pagamento.dart
class Pagamento {
  final int id;
  final int utente;
  final String utenteUsername;
  final double importo;
  final String data;
  final String descrizione;
  final int? gruppo;
  final String? gruppoNome;

  Pagamento({
    required this.id,
    required this.utente,
    required this.utenteUsername,
    required this.importo,
    required this.data,
    required this.descrizione,
    this.gruppo,
    this.gruppoNome,
  });

  factory Pagamento.fromJson(Map<String, dynamic> json) {
    return Pagamento(
      id: json['id'],
      utente: json['utente'],
      utenteUsername: json['utente_username'] ?? 'Sconosciuto',
      importo: json['importo'] is int 
          ? (json['importo'] as int).toDouble() 
          : json['importo'],
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
      'importo': importo,
      'data': data,
      'descrizione': descrizione,
      'gruppo': gruppo,
    };
  }
}