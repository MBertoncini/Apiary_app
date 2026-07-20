/// Somministrazione di nutrimento a una colonia.
/// Importante come confounder nel modello produzione miele.
class Alimentazione {
  static const List<String> tipiValidi = [
    'sciroppo_1_1',
    'sciroppo_2_1',
    'candito',
    'candito_proteico',
    'polline',
    'miele',
    'altro',
  ];

  static const List<String> scopiValidi = [
    'stimolante',
    'sostentamento',
    'invernale',
    'emergenza',
    'introduzione',
    'altro',
  ];

  final int id;
  final int colonia;
  final String? coloniaDisplay;
  final String data;
  final String tipo;
  final String? tipoDisplay;
  final String? scopo;
  final String? scopoDisplay;
  final double quantitaKg;
  final String? note;
  final int? utente;
  final String? utenteUsername;
  final String? dataCreazione;

  Alimentazione({
    required this.id,
    required this.colonia,
    this.coloniaDisplay,
    required this.data,
    required this.tipo,
    this.tipoDisplay,
    this.scopo,
    this.scopoDisplay,
    required this.quantitaKg,
    this.note,
    this.utente,
    this.utenteUsername,
    this.dataCreazione,
  });

  factory Alimentazione.fromJson(Map<String, dynamic> json) {
    return Alimentazione(
      id: json['id'] as int,
      colonia: json['colonia'] as int,
      coloniaDisplay: json['colonia_display'] as String?,
      data: json['data'] as String,
      tipo: json['tipo'] as String? ?? 'sciroppo_1_1',
      tipoDisplay: json['tipo_display'] as String?,
      scopo: json['scopo'] as String?,
      scopoDisplay: json['scopo_display'] as String?,
      quantitaKg:
          double.tryParse(json['quantita_kg']?.toString() ?? '') ?? 0.0,
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
      'data': data,
      'tipo': tipo,
      'scopo': scopo ?? '',
      'quantita_kg': quantitaKg,
      'note': note,
    };
  }
}
