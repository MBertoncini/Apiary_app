class DettaglioVendita {
  final int? id;
  final int? vendita;
  final String categoria;
  final String? tipoMiele;
  final int? formatoVasetto;
  final int quantita;
  final double prezzoUnitario;
  final double? subtotale;

  DettaglioVendita({
    this.id,
    this.vendita,
    this.categoria = 'miele',
    this.tipoMiele,
    this.formatoVasetto,
    required this.quantita,
    required this.prezzoUnitario,
    this.subtotale,
  });

  factory DettaglioVendita.fromJson(Map<String, dynamic> json) {
    return DettaglioVendita(
      id:             json['id'],
      vendita:        json['vendita'],
      categoria:      json['categoria'] ?? 'miele',
      tipoMiele:      json['tipo_miele'],
      formatoVasetto: json['formato_vasetto'],
      quantita:       json['quantita'],
      prezzoUnitario: double.tryParse(json['prezzo_unitario']?.toString() ?? '0') ?? 0,
      subtotale:      double.tryParse(json['subtotale']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria':       categoria,
      if (tipoMiele != null && tipoMiele!.isNotEmpty)
        'tipo_miele':    tipoMiele,
      if (formatoVasetto != null)
        'formato_vasetto': formatoVasetto,
      'quantita':        quantita,
      'prezzo_unitario': prezzoUnitario,
    };
  }
}

class Vendita {
  final int id;
  final String data;
  final int? cliente;
  final String? clienteNome;
  final String? acquirenteNome;
  final String canale;
  final String pagamento;
  final int utente;
  final String? utenteUsername;
  final String? note;
  final String? dataRegistrazione;
  final List<DettaglioVendita> dettagli;
  final double? totale;
  final int? gruppoId;
  final String? gruppoNome;

  Vendita({
    required this.id,
    required this.data,
    this.cliente,
    this.clienteNome,
    this.acquirenteNome,
    this.canale = 'privato',
    this.pagamento = 'contanti',
    required this.utente,
    this.utenteUsername,
    this.note,
    this.dataRegistrazione,
    this.dettagli = const [],
    this.totale,
    this.gruppoId,
    this.gruppoNome,
  });

  /// Display name regardless of whether a registered client or free-text name was used.
  String get displayName => clienteNome ?? acquirenteNome ?? 'Acquirente sconosciuto';

  factory Vendita.fromJson(Map<String, dynamic> json) {
    return Vendita(
      id:                json['id'],
      data:              json['data'],
      cliente:           json['cliente'],
      clienteNome:       json['cliente_nome'],
      acquirenteNome:    json['acquirente_nome'],
      canale:            json['canale'] ?? 'privato',
      pagamento:         json['pagamento'] ?? 'contanti',
      utente:            json['utente'],
      utenteUsername:    json['utente_username'],
      note:              json['note'],
      dataRegistrazione: json['data_registrazione'],
      dettagli: json['dettagli'] != null
          ? (json['dettagli'] as List).map((d) => DettaglioVendita.fromJson(d)).toList()
          : [],
      totale: double.tryParse(json['totale']?.toString() ?? ''),
      gruppoId: json['gruppo'],
      gruppoNome: json['gruppo_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data':     data,
      if (cliente != null)         'cliente':         cliente,
      if (acquirenteNome != null)  'acquirente_nome': acquirenteNome,
      'canale':   canale,
      'pagamento': pagamento,
      if (note != null)            'note':            note,
    };
  }
}
