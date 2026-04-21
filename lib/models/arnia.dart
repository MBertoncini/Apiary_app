import 'colonia.dart';

class Arnia {
  final int id;
  final int apiario;
  final String apiarioNome;
  final int numero;
  final String colore;
  final String coloreHex;
  final String tipoArnia;
  final String dataInstallazione;
  final String? note;
  final bool attiva;
  final int? attrezzatura;
  /// Colonia attualmente attiva in questa arnia (null se vuota).
  /// Popolata da una chiamata separata a /arnie/{id}/colonia_attiva/.
  final Colonia? coloniaAttiva;

  Arnia({
    required this.id,
    required this.apiario,
    required this.apiarioNome,
    required this.numero,
    required this.colore,
    required this.coloreHex,
    this.tipoArnia = 'dadant',
    required this.dataInstallazione,
    this.note,
    required this.attiva,
    this.attrezzatura,
    this.coloniaAttiva,
  });

  factory Arnia.fromJson(Map<String, dynamic> json) {
    return Arnia(
      id: json['id'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      numero: json['numero'],
      colore: json['colore'],
      coloreHex: json['colore_hex'],
      tipoArnia: json['tipo_arnia'] as String? ?? 'dadant',
      dataInstallazione: json['data_installazione'],
      note: json['note'],
      attiva: json['attiva'] ?? true,
      attrezzatura: json['attrezzatura'],
      // coloniaAttiva non arriva nel payload base dell'arnia
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiario': apiario,
      'apiario_nome': apiarioNome,
      'numero': numero,
      'colore': colore,
      'colore_hex': coloreHex,
      'tipo_arnia': tipoArnia,
      'data_installazione': dataInstallazione,
      'note': note,
      'attiva': attiva,
      'attrezzatura': attrezzatura,
    };
  }

  Arnia copyWith({Colonia? coloniaAttiva, int? attrezzatura}) {
    return Arnia(
      id: id,
      apiario: apiario,
      apiarioNome: apiarioNome,
      numero: numero,
      colore: colore,
      coloreHex: coloreHex,
      tipoArnia: tipoArnia,
      dataInstallazione: dataInstallazione,
      note: note,
      attiva: attiva,
      attrezzatura: attrezzatura ?? this.attrezzatura,
      coloniaAttiva: coloniaAttiva ?? this.coloniaAttiva,
    );
  }
}