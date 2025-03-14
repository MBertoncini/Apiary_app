class Fioritura {
  final int id;
  final int? apiario;
  final String? apiarioNome;
  final String pianta;
  final String dataInizio;
  final String? dataFine;
  final double latitudine;
  final double longitudine;
  final int? raggio;
  final String? note;
  final int? creatore;
  final String? creatoreUsername;
  final bool isActive;
  
  Fioritura({
    required this.id,
    this.apiario,
    this.apiarioNome,
    required this.pianta,
    required this.dataInizio,
    this.dataFine,
    required this.latitudine,
    required this.longitudine,
    this.raggio,
    this.note,
    this.creatore,
    this.creatoreUsername,
    required this.isActive,
  });
  
  factory Fioritura.fromJson(Map<String, dynamic> json) {
    return Fioritura(
      id: json['id'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      pianta: json['pianta'],
      dataInizio: json['data_inizio'],
      dataFine: json['data_fine'],
      latitudine: double.parse(json['latitudine'].toString()),
      longitudine: double.parse(json['longitudine'].toString()),
      raggio: json['raggio'],
      note: json['note'],
      creatore: json['creatore'],
      creatoreUsername: json['creatore_username'],
      isActive: json['is_active'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiario': apiario,
      'apiario_nome': apiarioNome,
      'pianta': pianta,
      'data_inizio': dataInizio,
      'data_fine': dataFine,
      'latitudine': latitudine,
      'longitudine': longitudine,
      'raggio': raggio,
      'note': note,
      'creatore': creatore,
      'creatore_username': creatoreUsername,
      'is_active': isActive,
    };
  }
}