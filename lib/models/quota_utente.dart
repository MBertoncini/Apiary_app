// lib/models/quota_utente.dart
class QuotaUtente {
  final int id;
  final int utente;
  final String utenteUsername;
  final double percentuale;
  final int? gruppo;
  final String? gruppoNome;

  QuotaUtente({
    required this.id,
    required this.utente,
    required this.utenteUsername,
    required this.percentuale,
    this.gruppo,
    this.gruppoNome,
  });

  factory QuotaUtente.fromJson(Map<String, dynamic> json) {
    return QuotaUtente(
      id: json['id'],
      utente: json['utente'],
      utenteUsername: json['utente_username'] ?? 'Sconosciuto',
      percentuale: json['percentuale'] is int 
          ? (json['percentuale'] as int).toDouble() 
          : json['percentuale'],
      gruppo: json['gruppo'],
      gruppoNome: json['gruppo_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utente': utente,
      'percentuale': percentuale,
      'gruppo': gruppo,
    };
  }
}