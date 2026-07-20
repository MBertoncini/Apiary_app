/// Pesata di un melario in un evento (posizionamento, intermedia, rimozione,
/// pre-smielatura). Storicizzata per colonia/fioritura, base del dataset ML
/// produzione miele per-colonia.
class PesataMelario {
  static const String tipoPosizionamento = 'posizionamento';
  static const String tipoIntermedia = 'intermedia';
  static const String tipoRimozione = 'rimozione';
  static const String tipoSmielatura = 'smielatura';

  static const List<String> tipiValidi = [
    tipoPosizionamento,
    tipoIntermedia,
    tipoRimozione,
    tipoSmielatura,
  ];

  final int id;
  final int melario;
  final int? melarioDisplay;
  final int? colonia;
  final String? coloniaDisplay;
  final int? fioritura;
  final String? fiorituraPianta;
  final int? smielatura;
  final String data;
  final String tipo;
  final String? tipoDisplay;
  final double pesoLordoKg;
  final double? taraKg;
  final double? pesoNettoKg;
  final String? note;
  final int? utente;
  final String? utenteUsername;
  final String? dataCreazione;

  PesataMelario({
    required this.id,
    required this.melario,
    this.melarioDisplay,
    this.colonia,
    this.coloniaDisplay,
    this.fioritura,
    this.fiorituraPianta,
    this.smielatura,
    required this.data,
    required this.tipo,
    this.tipoDisplay,
    required this.pesoLordoKg,
    this.taraKg,
    this.pesoNettoKg,
    this.note,
    this.utente,
    this.utenteUsername,
    this.dataCreazione,
  });

  factory PesataMelario.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return PesataMelario(
      id: json['id'] as int,
      melario: json['melario'] as int,
      melarioDisplay: json['melario_display'] is int
          ? json['melario_display'] as int
          : int.tryParse(json['melario_display']?.toString() ?? ''),
      colonia: json['colonia'] as int?,
      coloniaDisplay: json['colonia_display'] as String?,
      fioritura: json['fioritura'] as int?,
      fiorituraPianta: json['fioritura_pianta'] as String?,
      smielatura: json['smielatura'] as int?,
      data: json['data'] as String,
      tipo: json['tipo'] as String? ?? tipoRimozione,
      tipoDisplay: json['tipo_display'] as String?,
      pesoLordoKg: _d(json['peso_lordo_kg']) ?? 0.0,
      taraKg: _d(json['tara_kg']),
      pesoNettoKg: _d(json['peso_netto_kg']),
      note: json['note'] as String?,
      utente: json['utente'] as int?,
      utenteUsername: json['utente_username'] as String?,
      dataCreazione: json['data_creazione'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'melario': melario,
      'colonia': colonia,
      'fioritura': fioritura,
      'smielatura': smielatura,
      'data': data,
      'tipo': tipo,
      'peso_lordo_kg': pesoLordoKg,
      'tara_kg': taraKg,
      'note': note,
    };
  }
}
