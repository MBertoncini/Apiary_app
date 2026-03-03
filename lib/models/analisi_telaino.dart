class AnalisiTelaino {
  final int? id;
  final int arnia;
  final int? arniaNumero;
  final int numeroTelaino;
  final String facciata;
  final String? data;
  final int conteggioApi;
  final int conteggioRegine;
  final int conteggioFuchi;
  final int conteggioCelleReali;
  final double confidenceMedia;
  final String? note;
  final String? immagine;
  final int? utente;
  final String? utenteUsername;
  final String? dataRegistrazione;

  AnalisiTelaino({
    this.id,
    required this.arnia,
    this.arniaNumero,
    required this.numeroTelaino,
    required this.facciata,
    this.data,
    this.conteggioApi = 0,
    this.conteggioRegine = 0,
    this.conteggioFuchi = 0,
    this.conteggioCelleReali = 0,
    this.confidenceMedia = 0.0,
    this.note,
    this.immagine,
    this.utente,
    this.utenteUsername,
    this.dataRegistrazione,
  });

  factory AnalisiTelaino.fromJson(Map<String, dynamic> json) {
    return AnalisiTelaino(
      id: json['id'],
      arnia: json['arnia'],
      arniaNumero: json['arnia_numero'],
      numeroTelaino: json['numero_telaino'],
      facciata: json['facciata'],
      data: json['data'],
      conteggioApi: json['conteggio_api'] ?? 0,
      conteggioRegine: json['conteggio_regine'] ?? 0,
      conteggioFuchi: json['conteggio_fuchi'] ?? 0,
      conteggioCelleReali: json['conteggio_celle_reali'] ?? 0,
      confidenceMedia: (json['confidence_media'] ?? 0.0).toDouble(),
      note: json['note'],
      immagine: json['immagine'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      dataRegistrazione: json['data_registrazione'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'arnia': arnia,
      'numero_telaino': numeroTelaino,
      'facciata': facciata,
      'conteggio_api': conteggioApi,
      'conteggio_regine': conteggioRegine,
      'conteggio_fuchi': conteggioFuchi,
      'conteggio_celle_reali': conteggioCelleReali,
      'confidence_media': confidenceMedia,
      if (note != null) 'note': note,
    };
  }
}
