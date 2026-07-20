/// Spostamento fisico di una colonia tra apiari (nomadismo).
class NomadismoEvent {
  final int id;
  final int colonia;
  final String? coloniaDisplay;
  final int? apiarioOrigine;
  final String? apiarioOrigineNome;
  final int apiarioDestinazione;
  final String? apiarioDestinazioneNome;
  final String dataSpostamento;
  final String? motivo;
  final String? note;
  final int? utente;
  final String? utenteUsername;
  final String? dataCreazione;

  NomadismoEvent({
    required this.id,
    required this.colonia,
    this.coloniaDisplay,
    this.apiarioOrigine,
    this.apiarioOrigineNome,
    required this.apiarioDestinazione,
    this.apiarioDestinazioneNome,
    required this.dataSpostamento,
    this.motivo,
    this.note,
    this.utente,
    this.utenteUsername,
    this.dataCreazione,
  });

  factory NomadismoEvent.fromJson(Map<String, dynamic> json) {
    return NomadismoEvent(
      id: json['id'] as int,
      colonia: json['colonia'] as int,
      coloniaDisplay: json['colonia_display'] as String?,
      apiarioOrigine: json['apiario_origine'] as int?,
      apiarioOrigineNome: json['apiario_origine_nome'] as String?,
      apiarioDestinazione: json['apiario_destinazione'] as int,
      apiarioDestinazioneNome: json['apiario_destinazione_nome'] as String?,
      dataSpostamento: json['data_spostamento'] as String,
      motivo: json['motivo'] as String?,
      note: json['note'] as String?,
      utente: json['utente'] as int?,
      utenteUsername: json['utente_username'] as String?,
      dataCreazione: json['data_creazione'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colonia': colonia,
      'apiario_origine': apiarioOrigine,
      'apiario_destinazione': apiarioDestinazione,
      'data_spostamento': dataSpostamento,
      'motivo': motivo ?? '',
      'note': note,
    };
  }
}
