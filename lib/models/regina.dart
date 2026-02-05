class Regina {
  final int? id;
  final int arniaId;
  final String? arniaNumero;  // Numero visibile dell'arnia (dal server)
  final String razza;
  final String origine;
  final String? colore;       // colore_marcatura dal server
  final String dataInserimento; // data_introduzione dal server
  final String? dataNascita;
  final String? dataRimozione;
  final String? note;
  final bool isAttiva;
  final bool marcata;
  final bool fecondata;
  final bool selezionata;
  final String? codiceMarcatura;
  final int? docilita;
  final int? produttivita;
  final int? resistenzaMalattie;
  final int? tendenzaSciamatura;

  Regina({
    this.id,
    required this.arniaId,
    this.arniaNumero,
    required this.razza,
    required this.origine,
    this.colore,
    required this.dataInserimento,
    this.dataNascita,
    this.dataRimozione,
    this.note,
    required this.isAttiva,
    this.marcata = false,
    this.fecondata = false,
    this.selezionata = false,
    this.codiceMarcatura,
    this.docilita,
    this.produttivita,
    this.resistenzaMalattie,
    this.tendenzaSciamatura,
  });

  // Convert a Regina object into a Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arnia_id': arniaId,
      'razza': razza,
      'origine': origine,
      'colore': colore,
      'data_inserimento': dataInserimento,
      'data_rimozione': dataRimozione,
      'note': note,
      'is_attiva': isAttiva ? 1 : 0,
    };
  }

  // Convert from JSON (API REST response)
  factory Regina.fromJson(Map<String, dynamic> json) {
    // Gestisci arniaId che puo' essere int o null
    int parsedArniaId = 0;
    if (json['arnia'] != null) {
      parsedArniaId = json['arnia'] is int ? json['arnia'] : int.tryParse(json['arnia'].toString()) ?? 0;
    } else if (json['arnia_id'] != null) {
      parsedArniaId = json['arnia_id'] is int ? json['arnia_id'] : int.tryParse(json['arnia_id'].toString()) ?? 0;
    }

    return Regina(
      id: json['id'],
      arniaId: parsedArniaId,
      arniaNumero: json['arnia_numero']?.toString(),
      razza: json['razza'] ?? '',
      origine: json['origine'] ?? '',
      colore: json['colore_marcatura'] ?? json['colore'],
      dataInserimento: json['data_introduzione'] ?? json['data_inserimento'] ?? '',
      dataNascita: json['data_nascita'],
      dataRimozione: json['data_rimozione'],
      note: json['note'],
      isAttiva: json['is_attiva'] ?? json['attiva'] ?? false,
      marcata: json['marcata'] ?? false,
      fecondata: json['fecondata'] ?? false,
      selezionata: json['selezionata'] ?? false,
      codiceMarcatura: json['codice_marcatura'],
      docilita: json['docilita'],
      produttivita: json['produttivita'],
      resistenzaMalattie: json['resistenza_malattie'],
      tendenzaSciamatura: json['tendenza_sciamatura'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'arnia': arniaId,
      if (arniaNumero != null) 'arnia_numero': arniaNumero,
      'razza': razza,
      'origine': origine,
      'colore_marcatura': colore,
      'data_introduzione': dataInserimento,
      if (dataNascita != null) 'data_nascita': dataNascita,
      'data_rimozione': dataRimozione,
      'note': note,
      'is_attiva': isAttiva,
      'marcata': marcata,
      'fecondata': fecondata,
      'selezionata': selezionata,
      if (codiceMarcatura != null) 'codice_marcatura': codiceMarcatura,
      if (docilita != null) 'docilita': docilita,
      if (produttivita != null) 'produttivita': produttivita,
      if (resistenzaMalattie != null) 'resistenza_malattie': resistenzaMalattie,
      if (tendenzaSciamatura != null) 'tendenza_sciamatura': tendenzaSciamatura,
    };
  }

  // Convert a Map into a Regina object (SQLite)
  factory Regina.fromMap(Map<String, dynamic> map) {
    return Regina(
      id: map['id'],
      arniaId: map['arnia_id'],
      razza: map['razza'],
      origine: map['origine'],
      colore: map['colore'],
      dataInserimento: map['data_inserimento'],
      dataRimozione: map['data_rimozione'],
      note: map['note'],
      isAttiva: map['is_attiva'] == 1,
    );
  }

  // Create a copy with some fields modified
  Regina copyWith({
    int? id,
    int? arniaId,
    String? arniaNumero,
    String? razza,
    String? origine,
    String? colore,
    String? dataInserimento,
    String? dataNascita,
    String? dataRimozione,
    String? note,
    bool? isAttiva,
    bool? marcata,
    bool? fecondata,
    bool? selezionata,
    String? codiceMarcatura,
    int? docilita,
    int? produttivita,
    int? resistenzaMalattie,
    int? tendenzaSciamatura,
  }) {
    return Regina(
      id: id ?? this.id,
      arniaId: arniaId ?? this.arniaId,
      arniaNumero: arniaNumero ?? this.arniaNumero,
      razza: razza ?? this.razza,
      origine: origine ?? this.origine,
      colore: colore ?? this.colore,
      dataInserimento: dataInserimento ?? this.dataInserimento,
      dataNascita: dataNascita ?? this.dataNascita,
      dataRimozione: dataRimozione ?? this.dataRimozione,
      note: note ?? this.note,
      isAttiva: isAttiva ?? this.isAttiva,
      marcata: marcata ?? this.marcata,
      fecondata: fecondata ?? this.fecondata,
      selezionata: selezionata ?? this.selezionata,
      codiceMarcatura: codiceMarcatura ?? this.codiceMarcatura,
      docilita: docilita ?? this.docilita,
      produttivita: produttivita ?? this.produttivita,
      resistenzaMalattie: resistenzaMalattie ?? this.resistenzaMalattie,
      tendenzaSciamatura: tendenzaSciamatura ?? this.tendenzaSciamatura,
    );
  }
}
