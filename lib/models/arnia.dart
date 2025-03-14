import 'dart:convert';

class Arnia {
  final int id;
  final int apiario;
  final String apiarioNome;
  final int numero;
  final String colore;
  final String coloreHex;
  final String dataInstallazione;
  final String? note;
  final bool attiva;
  
  Arnia({
    required this.id,
    required this.apiario,
    required this.apiarioNome,
    required this.numero,
    required this.colore,
    required this.coloreHex,
    required this.dataInstallazione,
    this.note,
    required this.attiva,
  });
  
  factory Arnia.fromJson(Map<String, dynamic> json) {
    return Arnia(
      id: json['id'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      numero: json['numero'],
      colore: json['colore'],
      coloreHex: json['colore_hex'],
      dataInstallazione: json['data_installazione'],
      note: json['note'],
      attiva: json['attiva'],
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
      'data_installazione': dataInstallazione,
      'note': note,
      'attiva': attiva,
    };
  }
}