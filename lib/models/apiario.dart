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
  // Dati ambientali della postazione. Non entrano in toJson(): la tabella
  // SQLite locale degli apiari non ha queste colonne.
  final double? altitudineM;
  final double? pendenzaGradi;
  final String esposizione;
  final String coperturaSuolo;
  
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
    this.altitudineM,
    this.pendenzaGradi,
    this.esposizione = '',
    this.coperturaSuolo = '',
  });
  
  factory Apiario.fromJson(Map<String, dynamic> json) {
    return Apiario(
      id: json['id'],
      nome: json['nome'],
      posizione: json['posizione'],
      latitudine: json['latitudine'] != null ? double.tryParse(json['latitudine'].toString()) : null,
      longitudine: json['longitudine'] != null ? double.tryParse(json['longitudine'].toString()) : null,
      note: json['note'],
      monitoraggioMeteo: json['monitoraggio_meteo'] ?? false,
      proprietario: json['proprietario'],
      proprietarioUsername: json['proprietario_username'] ?? '',
      gruppo: json['gruppo'],
      condivisoConGruppo: json['condiviso_con_gruppo'] ?? false,
      visibilitaMappa: json['visibilita_mappa'] ?? 'privato',
      altitudineM: json['altitudine_m'] != null ? double.tryParse(json['altitudine_m'].toString()) : null,
      pendenzaGradi: json['pendenza_gradi'] != null ? double.tryParse(json['pendenza_gradi'].toString()) : null,
      esposizione: json['esposizione'] ?? '',
      coperturaSuolo: json['copertura_suolo'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'posizione': posizione,
      'latitudine': latitudine != null ? double.parse(latitudine!.toStringAsFixed(6)) : null,
      'longitudine': longitudine != null ? double.parse(longitudine!.toStringAsFixed(6)) : null,
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