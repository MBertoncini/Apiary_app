class Melario {
  final int id;
  final int? colonia;
  final int? coloniaId;
  final int? arnia;
  final int? arniaNumero;
  final int? apiarioId;
  final String? apiarioNome;
  final int numeroTelaini;
  final int posizione;
  final String dataPosizionamento;
  final String? dataRimozione;
  final String stato;
  final String tipoMelario;
  final String statoFavi;
  final bool escludiRegina;
  final double? pesoStimato;
  final String? note;
  final String? apiarioGruppoNome;
  /// Numero progressivo per-utente (1..N nell'ordine di creazione).
  /// Da preferire all'`id` per il display in UI. NULL per record legacy
  /// non ancora migrati.
  final int? numeroProgressivo;

  Melario({
    required this.id,
    this.colonia,
    this.coloniaId,
    this.arnia,
    this.arniaNumero,
    this.apiarioId,
    this.apiarioNome,
    required this.numeroTelaini,
    required this.posizione,
    required this.dataPosizionamento,
    this.dataRimozione,
    required this.stato,
    this.tipoMelario = 'standard',
    this.statoFavi = 'costruiti',
    this.escludiRegina = true,
    this.pesoStimato,
    this.note,
    this.apiarioGruppoNome,
    this.numeroProgressivo,
  });

  /// Numero da mostrare in UI: `numeroProgressivo` se disponibile, altrimenti
  /// fallback al `id` globale (per record pre-migrazione 0046).
  int get numeroDisplay => numeroProgressivo ?? id;

  factory Melario.fromJson(Map<String, dynamic> json) {
    return Melario(
      id: json['id'],
      colonia: json['colonia'],
      coloniaId: json['colonia_id'],
      arnia: json['arnia_id'] ?? json['arnia'],
      arniaNumero: json['arnia_numero'],
      apiarioId: json['apiario_id'],
      apiarioNome: json['apiario_nome'],
      numeroTelaini: json['numero_telaini'],
      posizione: json['posizione'],
      dataPosizionamento: json['data_posizionamento'],
      dataRimozione: json['data_rimozione'],
      stato: json['stato'],
      tipoMelario: json['tipo_melario'] ?? 'standard',
      statoFavi: json['stato_favi'] ?? 'costruiti',
      escludiRegina: json['escludi_regina'] ?? true,
      pesoStimato: double.tryParse(json['peso_stimato']?.toString() ?? ''),
      note: json['note'],
      apiarioGruppoNome: json['apiario_gruppo_nome'],
      numeroProgressivo: json['numero_progressivo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colonia': colonia ?? coloniaId,
      'apiario_id': apiarioId,
      'apiario_nome': apiarioNome,
      'numero_telaini': numeroTelaini,
      'posizione': posizione,
      'data_posizionamento': dataPosizionamento,
      'data_rimozione': dataRimozione,
      'stato': stato,
      'tipo_melario': tipoMelario,
      'stato_favi': statoFavi,
      'escludi_regina': escludiRegina,
      'peso_stimato': pesoStimato,
      'note': note,
      'numero_progressivo': numeroProgressivo,
    };
  }

  Melario copyWith({
    int? id,
    int? colonia,
    int? coloniaId,
    int? arnia,
    int? arniaNumero,
    int? apiarioId,
    String? apiarioNome,
    int? numeroTelaini,
    int? posizione,
    String? dataPosizionamento,
    String? dataRimozione,
    String? stato,
    String? tipoMelario,
    String? statoFavi,
    bool? escludiRegina,
    double? pesoStimato,
    String? note,
    String? apiarioGruppoNome,
    int? numeroProgressivo,
  }) {
    return Melario(
      id: id ?? this.id,
      colonia: colonia ?? this.colonia,
      coloniaId: coloniaId ?? this.coloniaId,
      arnia: arnia ?? this.arnia,
      arniaNumero: arniaNumero ?? this.arniaNumero,
      apiarioId: apiarioId ?? this.apiarioId,
      apiarioNome: apiarioNome ?? this.apiarioNome,
      numeroTelaini: numeroTelaini ?? this.numeroTelaini,
      posizione: posizione ?? this.posizione,
      dataPosizionamento: dataPosizionamento ?? this.dataPosizionamento,
      dataRimozione: dataRimozione ?? this.dataRimozione,
      stato: stato ?? this.stato,
      tipoMelario: tipoMelario ?? this.tipoMelario,
      statoFavi: statoFavi ?? this.statoFavi,
      escludiRegina: escludiRegina ?? this.escludiRegina,
      pesoStimato: pesoStimato ?? this.pesoStimato,
      note: note ?? this.note,
      apiarioGruppoNome: apiarioGruppoNome ?? this.apiarioGruppoNome,
      numeroProgressivo: numeroProgressivo ?? this.numeroProgressivo,
    );
  }
}
