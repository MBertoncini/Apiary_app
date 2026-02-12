class DettaglioVendita {
  final int? id;
  final int? vendita;
  final String tipoMiele;
  final int formatoVasetto;
  final int quantita;
  final double prezzoUnitario;
  final double? subtotale;

  DettaglioVendita({
    this.id,
    this.vendita,
    required this.tipoMiele,
    required this.formatoVasetto,
    required this.quantita,
    required this.prezzoUnitario,
    this.subtotale,
  });

  factory DettaglioVendita.fromJson(Map<String, dynamic> json) {
    return DettaglioVendita(
      id: json['id'],
      vendita: json['vendita'],
      tipoMiele: json['tipo_miele'],
      formatoVasetto: json['formato_vasetto'],
      quantita: json['quantita'],
      prezzoUnitario: double.tryParse(json['prezzo_unitario']?.toString() ?? '0') ?? 0,
      subtotale: double.tryParse(json['subtotale']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_miele': tipoMiele,
      'formato_vasetto': formatoVasetto,
      'quantita': quantita,
      'prezzo_unitario': prezzoUnitario,
    };
  }
}

class Vendita {
  final int id;
  final String data;
  final int cliente;
  final String? clienteNome;
  final int utente;
  final String? utenteUsername;
  final String? note;
  final String? dataRegistrazione;
  final List<DettaglioVendita> dettagli;
  final double? totale;

  Vendita({
    required this.id,
    required this.data,
    required this.cliente,
    this.clienteNome,
    required this.utente,
    this.utenteUsername,
    this.note,
    this.dataRegistrazione,
    this.dettagli = const [],
    this.totale,
  });

  factory Vendita.fromJson(Map<String, dynamic> json) {
    return Vendita(
      id: json['id'],
      data: json['data'],
      cliente: json['cliente'],
      clienteNome: json['cliente_nome'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      note: json['note'],
      dataRegistrazione: json['data_registrazione'],
      dettagli: json['dettagli'] != null
          ? (json['dettagli'] as List).map((d) => DettaglioVendita.fromJson(d)).toList()
          : [],
      totale: double.tryParse(json['totale']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'cliente': cliente,
      'note': note,
    };
  }
}
