import 'dart:convert';

class Apiario {
  final int id;
  final String nome;
  final String posizione;
  final double? latitudine;
  final double? longitudine;
  final String? note;
  final bool monitoraggioMeteo;
  final int proprietario;
  final String proprietarioUsername;
  final int? gruppo;
  final bool condivisoConGruppo;
  final String visibilitaMappa;
  
  Apiario({
    required this.id,
    required this.nome,
    required this.posizione,
    this.latitudine,
    this.longitudine,
    this.note,
    required this.monitoraggioMeteo,
    required this.proprietario,
    required this.proprietarioUsername,
    this.gruppo,
    required this.condivisoConGruppo,
    required this.visibilitaMappa,
  });
  
  factory Apiario.fromJson(Map<String, dynamic> json) {
    return Apiario(
      id: json['id'],
      nome: json['nome'],
      posizione: json['posizione'],
      latitudine: json['latitudine'] != null ? double.parse(json['latitudine'].toString()) : null,
      longitudine: json['longitudine'] != null ? double.parse(json['longitudine'].toString()) : null,
      note: json['note'],
      monitoraggioMeteo: json['monitoraggio_meteo'],
      proprietario: json['proprietario'],
      proprietarioUsername: json['proprietario_username'],
      gruppo: json['gruppo'],
      condivisoConGruppo: json['condiviso_con_gruppo'],
      visibilitaMappa: json['visibilita_mappa'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'posizione': posizione,
      'latitudine': latitudine,
      'longitudine': longitudine,
      'note': note,
      'monitoraggio_meteo': monitoraggioMeteo,
      'proprietario': proprietario,
      'proprietario_username': proprietarioUsername,
      'gruppo': gruppo,
      'condiviso_con_gruppo': condivisoConGruppo,
      'visibilita_mappa': visibilitaMappa,
    };
  }
  
  bool hasCoordinates() {
    return latitudine != null && longitudine != null;
  }
}