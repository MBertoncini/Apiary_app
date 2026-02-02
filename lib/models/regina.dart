class Regina {
  final int? id;
  final int arniaId;
  final String razza;
  final String origine;
  final String? colore;
  final String dataInserimento;
  final String? dataRimozione;
  final String? note;
  final bool isAttiva;

  Regina({
    this.id,
    required this.arniaId,
    required this.razza,
    required this.origine,
    this.colore,
    required this.dataInserimento,
    this.dataRimozione,
    this.note,
    required this.isAttiva,
  });

  // Convert a Regina object into a Map
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
    return Regina(
      id: json['id'],
      arniaId: json['arnia'] ?? json['arnia_id'],
      razza: json['razza'] ?? '',
      origine: json['origine'] ?? '',
      colore: json['colore'],
      dataInserimento: json['data_inserimento'] ?? '',
      dataRimozione: json['data_rimozione'],
      note: json['note'],
      isAttiva: json['is_attiva'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'arnia': arniaId,
      'razza': razza,
      'origine': origine,
      'colore': colore,
      'data_inserimento': dataInserimento,
      'data_rimozione': dataRimozione,
      'note': note,
      'is_attiva': isAttiva,
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
    String? razza,
    String? origine,
    String? colore,
    String? dataInserimento,
    String? dataRimozione,
    String? note,
    bool? isAttiva,
  }) {
    return Regina(
      id: id ?? this.id,
      arniaId: arniaId ?? this.arniaId,
      razza: razza ?? this.razza,
      origine: origine ?? this.origine,
      colore: colore ?? this.colore,
      dataInserimento: dataInserimento ?? this.dataInserimento,
      dataRimozione: dataRimozione ?? this.dataRimozione,
      note: note ?? this.note,
      isAttiva: isAttiva ?? this.isAttiva,
    );
  }
}