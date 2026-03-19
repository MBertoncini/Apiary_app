class Fioritura {
  final int id;
  final int? apiario;
  final String? apiarioNome;
  final String pianta;
  final String? piantaTipo;
  final String dataInizio;
  final String? dataFine;
  final double latitudine;
  final double longitudine;
  final int? raggio;
  final String? note;
  final int? creatore;
  final String? creatoreUsername;
  final bool isActive;
  final bool pubblica;
  final int? intensita;
  final int nConferme;
  final double? intensitaMedia;
  final bool confermaDaMe;

  Fioritura({
    required this.id,
    this.apiario,
    this.apiarioNome,
    required this.pianta,
    this.piantaTipo,
    required this.dataInizio,
    this.dataFine,
    required this.latitudine,
    required this.longitudine,
    this.raggio,
    this.note,
    this.creatore,
    this.creatoreUsername,
    required this.isActive,
    this.pubblica = false,
    this.intensita,
    this.nConferme = 0,
    this.intensitaMedia,
    this.confermaDaMe = false,
  });

  factory Fioritura.fromJson(Map<String, dynamic> json) {
    return Fioritura(
      id: json['id'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      pianta: json['pianta'],
      piantaTipo: json['pianta_tipo'],
      dataInizio: json['data_inizio'],
      dataFine: json['data_fine'],
      latitudine: double.tryParse(json['latitudine'].toString()) ?? 0.0,
      longitudine: double.tryParse(json['longitudine'].toString()) ?? 0.0,
      raggio: json['raggio'],
      note: json['note'],
      creatore: json['creatore'],
      creatoreUsername: json['creatore_username'],
      isActive: json['is_active'] ?? false,
      pubblica: json['pubblica'] ?? false,
      intensita: json['intensita'],
      nConferme: json['n_conferme'] ?? 0,
      intensitaMedia: json['intensita_media'] != null
          ? double.tryParse(json['intensita_media'].toString())
          : null,
      confermaDaMe: json['confermato_da_me'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiario': apiario,
      'apiario_nome': apiarioNome,
      'pianta': pianta,
      'pianta_tipo': piantaTipo,
      'data_inizio': dataInizio,
      'data_fine': dataFine,
      'latitudine': latitudine,
      'longitudine': longitudine,
      'raggio': raggio,
      'note': note,
      'creatore': creatore,
      'creatore_username': creatoreUsername,
      'is_active': isActive,
      'pubblica': pubblica,
      'intensita': intensita,
      'n_conferme': nConferme,
      'intensita_media': intensitaMedia,
      'confermato_da_me': confermaDaMe,
    };
  }

  static const Map<String, String> piantaTipoLabel = {
    'spontanea': 'Spontanea',
    'coltivata': 'Coltivata',
    'alberata': 'Alberata',
    'arborea': 'Arborea',
    'arbustiva': 'Arbustiva',
  };

  static const List<String> intensitaLabel = [
    '', 'Scarsa', 'Discreta', 'Buona', 'Ottima', 'Eccezionale'
  ];
}