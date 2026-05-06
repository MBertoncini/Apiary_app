class Regina {
  final int? id;
  final int arniaId;
  final int? coloniaId;
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
  final bool sospettaAssente; // segnalata assente in 2+ controlli consecutivi
  final String? codiceMarcatura;
  final int? docilita;
  final int? produttivita;
  final int? resistenzaMalattie;
  final int? tendenzaSciamatura;
  final int? reginaMadreId;

  Regina({
    this.id,
    required this.arniaId,
    this.coloniaId,
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
    this.sospettaAssente = false,
    this.codiceMarcatura,
    this.docilita,
    this.produttivita,
    this.resistenzaMalattie,
    this.tendenzaSciamatura,
    this.reginaMadreId,
  });

  // Convert a Regina object into a Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arnia_id': arniaId,
      'colonia_id': coloniaId,
      'razza': razza,
      'origine': origine,
      'colore': colore,
      'data_inserimento': dataInserimento,
      'data_nascita': dataNascita,
      'data_rimozione': dataRimozione,
      'note': note,
      'is_attiva': isAttiva ? 1 : 0,
      'marcata': marcata ? 1 : 0,
      'fecondata': fecondata ? 1 : 0,
      'selezionata': selezionata ? 1 : 0,
      'sospetta_assente': sospettaAssente ? 1 : 0,
      'codice_marcatura': codiceMarcatura,
      'docilita': docilita,
      'produttivita': produttivita,
      'resistenza_malattie': resistenzaMalattie,
      'tendenza_sciamatura': tendenzaSciamatura,
      'regina_madre_id': reginaMadreId,
    };
  }

  // Convert from JSON (API REST response)
  factory Regina.fromJson(Map<String, dynamic> json) {
    int parsedArniaId = 0;
    if (json['arnia'] != null) {
      parsedArniaId = json['arnia'] is int ? json['arnia'] : int.tryParse(json['arnia'].toString()) ?? 0;
    } else if (json['arnia_id'] != null) {
      parsedArniaId = json['arnia_id'] is int ? json['arnia_id'] : int.tryParse(json['arnia_id'].toString()) ?? 0;
    }

    int? parsedColoniaId;
    final rawColonia = json['colonia'] ?? json['colonia_id'];
    if (rawColonia != null) {
      parsedColoniaId = rawColonia is int ? rawColonia : int.tryParse(rawColonia.toString());
    }

    int? parsedReginaMadreId;
    final rawMadre = json['regina_madre'] ?? json['regina_madre_id'];
    if (rawMadre is int) {
      parsedReginaMadreId = rawMadre;
    } else if (rawMadre is Map && rawMadre['id'] is int) {
      parsedReginaMadreId = rawMadre['id'] as int;
    } else if (rawMadre != null) {
      parsedReginaMadreId = int.tryParse(rawMadre.toString());
    }

    return Regina(
      id: json['id'],
      arniaId: parsedArniaId,
      coloniaId: parsedColoniaId,
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
      sospettaAssente: json['sospetta_assente'] ?? false,
      codiceMarcatura: json['codice_marcatura'],
      docilita: json['docilita'],
      produttivita: json['produttivita'],
      resistenzaMalattie: json['resistenza_malattie'],
      tendenzaSciamatura: json['tendenza_sciamatura'],
      reginaMadreId: parsedReginaMadreId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'arnia': arniaId,
      if (coloniaId != null) 'colonia': coloniaId,
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
      'sospetta_assente': sospettaAssente,
      if (codiceMarcatura != null) 'codice_marcatura': codiceMarcatura,
      if (docilita != null) 'docilita': docilita,
      if (produttivita != null) 'produttivita': produttivita,
      if (resistenzaMalattie != null) 'resistenza_malattie': resistenzaMalattie,
      if (tendenzaSciamatura != null) 'tendenza_sciamatura': tendenzaSciamatura,
      if (reginaMadreId != null) 'regina_madre': reginaMadreId,
    };
  }

  // Convert a Map into a Regina object (SQLite). Null-safe.
  factory Regina.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    int? parseIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return Regina(
      id: parseIntOrNull(map['id']),
      arniaId: parseInt(map['arnia_id']),
      coloniaId: parseIntOrNull(map['colonia_id']),
      razza: (map['razza'] ?? '') as String,
      origine: (map['origine'] ?? '') as String,
      colore: map['colore'] as String?,
      dataInserimento: (map['data_inserimento'] ?? '') as String,
      dataNascita: map['data_nascita'] as String?,
      dataRimozione: map['data_rimozione'] as String?,
      note: map['note'] as String?,
      isAttiva: parseBool(map['is_attiva']),
      marcata: parseBool(map['marcata']),
      fecondata: parseBool(map['fecondata']),
      selezionata: parseBool(map['selezionata']),
      sospettaAssente: parseBool(map['sospetta_assente']),
      codiceMarcatura: map['codice_marcatura'] as String?,
      docilita: parseIntOrNull(map['docilita']),
      produttivita: parseIntOrNull(map['produttivita']),
      resistenzaMalattie: parseIntOrNull(map['resistenza_malattie']),
      tendenzaSciamatura: parseIntOrNull(map['tendenza_sciamatura']),
      reginaMadreId: parseIntOrNull(map['regina_madre_id']),
    );
  }

  // Create a copy with some fields modified
  Regina copyWith({
    int? id,
    int? arniaId,
    int? coloniaId,
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
    bool? sospettaAssente,
    String? codiceMarcatura,
    int? docilita,
    int? produttivita,
    int? resistenzaMalattie,
    int? tendenzaSciamatura,
    int? reginaMadreId,
  }) {
    return Regina(
      id: id ?? this.id,
      arniaId: arniaId ?? this.arniaId,
      coloniaId: coloniaId ?? this.coloniaId,
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
      sospettaAssente: sospettaAssente ?? this.sospettaAssente,
      codiceMarcatura: codiceMarcatura ?? this.codiceMarcatura,
      docilita: docilita ?? this.docilita,
      produttivita: produttivita ?? this.produttivita,
      resistenzaMalattie: resistenzaMalattie ?? this.resistenzaMalattie,
      tendenzaSciamatura: tendenzaSciamatura ?? this.tendenzaSciamatura,
      reginaMadreId: reginaMadreId ?? this.reginaMadreId,
    );
  }
}
