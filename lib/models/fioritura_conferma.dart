class FiorituraConferma {
  final int id;
  final int fioritura;
  final int? utente;
  final String? utenteUsername;
  final String data;
  final int? intensita;
  final String? nota;

  FiorituraConferma({
    required this.id,
    required this.fioritura,
    this.utente,
    this.utenteUsername,
    required this.data,
    this.intensita,
    this.nota,
  });

  factory FiorituraConferma.fromJson(Map<String, dynamic> json) {
    return FiorituraConferma(
      id: json['id'],
      fioritura: json['fioritura'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      data: json['data'],
      intensita: json['intensita'],
      nota: json['nota'],
    );
  }
}
