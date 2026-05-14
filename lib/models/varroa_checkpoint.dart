class VarroaCheckpoint {
  final int id;
  final int coloniaId;
  final String? coloniaNome;
  final String dataCampionamento;
  final String metodo;
  final String? metodoDisplay;
  final int? apiCampionate;
  final int acariContati;
  final int? giorniMisurazione;
  final double? telainiCovata;
  final double percentualeCalcolata;
  final double? cadutaGiornaliera;
  final double confidenza;
  final String? note;

  const VarroaCheckpoint({
    required this.id,
    required this.coloniaId,
    this.coloniaNome,
    required this.dataCampionamento,
    required this.metodo,
    this.metodoDisplay,
    this.apiCampionate,
    required this.acariContati,
    this.giorniMisurazione,
    this.telainiCovata,
    required this.percentualeCalcolata,
    this.cadutaGiornaliera,
    required this.confidenza,
    this.note,
  });

  factory VarroaCheckpoint.fromJson(Map<String, dynamic> json) {
    return VarroaCheckpoint(
      id:                   json['id'] as int,
      coloniaId:            json['colonia'] as int,
      coloniaNome:          json['colonia_nome'] as String?,
      dataCampionamento:    json['data_campionamento'] as String,
      metodo:               json['metodo'] as String,
      metodoDisplay:        json['metodo_display'] as String?,
      apiCampionate:        json['api_campionate'] as int?,
      acariContati:         json['acari_contati'] as int,
      giorniMisurazione:    json['giorni_misurazione'] as int?,
      telainiCovata:        (json['telaini_covata'] as num?)?.toDouble(),
      percentualeCalcolata: (json['percentuale_calcolata'] as num).toDouble(),
      cadutaGiornaliera:    (json['caduta_giornaliera'] as num?)?.toDouble(),
      confidenza:           (json['confidenza'] as num).toDouble(),
      note:                 json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'colonia':             coloniaId,
    'data_campionamento':  dataCampionamento,
    'metodo':              metodo,
    if (apiCampionate != null) 'api_campionate': apiCampionate,
    'acari_contati':       acariContati,
    if (giorniMisurazione != null) 'giorni_misurazione': giorniMisurazione,
    if (telainiCovata != null) 'telaini_covata': telainiCovata,
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  String get rischioLivello {
    final month = DateTime.parse(dataCampionamento).month;
    double soglia;
    if ([3,4,5,6,7,8].contains(month))      soglia = 3.0;
    else if ([9,10].contains(month))         soglia = 2.5;
    else                                     soglia = 2.0;
    if (percentualeCalcolata >= soglia)      return 'rosso';
    final giallo = soglia - 1.0;
    if (percentualeCalcolata >= giallo)      return 'giallo';
    if (percentualeCalcolata >= giallo * 0.7) return 'arancione';
    return 'verde';
  }
}
