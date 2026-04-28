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
    final id = json['id'];
    final utente = json['utente'];
    if (id is! int) {
      throw FormatException('QuotaUtente.fromJson: id mancante o invalido', json);
    }
    if (utente is! int) {
      throw FormatException('QuotaUtente.fromJson: utente mancante o invalido', json);
    }
    final percRaw = json['percentuale'];
    final percentuale = percRaw == null ? null : double.tryParse(percRaw.toString());
    if (percentuale == null) {
      throw FormatException('QuotaUtente.fromJson: percentuale invalida ($percRaw)', json);
    }

    return QuotaUtente(
      id: id,
      utente: utente,
      utenteUsername: json['utente_username'] ?? 'Sconosciuto',
      percentuale: percentuale,
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