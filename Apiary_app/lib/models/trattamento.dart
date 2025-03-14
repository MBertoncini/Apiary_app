class TrattamentoSanitario {
  final int id;
  final int apiario;
  final String apiarioNome;
  final int tipoTrattamento;
  final String tipoTrattamentoNome;
  final String dataInizio;
  final String? dataFine;
  final String? dataFineSospensione;
  final String stato;
  final int utente;
  final String utenteUsername;
  final List<int>? arnie;
  final String? note;
  final bool bloccoCovataAttivo;
  final String? dataInizioBlocco;
  final String? dataFineBlocco;
  final String? metodoBlocco;
  final String? noteBlocco;
  
  TrattamentoSanitario({
    required this.id,
    required this.apiario,
    required this.apiarioNome,
    required this.tipoTrattamento,
    required this.tipoTrattamentoNome,
    required this.dataInizio,
    this.dataFine,
    this.dataFineSospensione,
    required this.stato,
    required this.utente,
    required this.utenteUsername,
    this.arnie,
    this.note,
    required this.bloccoCovataAttivo,
    this.dataInizioBlocco,
    this.dataFineBlocco,
    this.metodoBlocco,
    this.noteBlocco,
  });
  
  factory TrattamentoSanitario.fromJson(Map<String, dynamic> json) {
    List<int>? arnieList;
    if (json['arnie'] != null) {
      arnieList = List<int>.from(json['arnie']);
    }
    
    return TrattamentoSanitario(
      id: json['id'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      tipoTrattamento: json['tipo_trattamento'],
      tipoTrattamentoNome: json['tipo_trattamento_nome'],
      dataInizio: json['data_inizio'],
      dataFine: json['data_fine'],
      dataFineSospensione: json['data_fine_sospensione'],
      stato: json['stato'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      arnie: arnieList,
      note: json['note'],
      bloccoCovataAttivo: json['blocco_covata_attivo'],
      dataInizioBlocco: json['data_inizio_blocco'],
      dataFineBlocco: json['data_fine_blocco'],
      metodoBlocco: json['metodo_blocco'],
      noteBlocco: json['note_blocco'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiario': apiario,
      'apiario_nome': apiarioNome,
      'tipo_trattamento': tipoTrattamento,
      'tipo_trattamento_nome': tipoTrattamentoNome,
      'data_inizio': dataInizio,
      'data_fine': dataFine,
      'data_fine_sospensione': dataFineSospensione,
      'stato': stato,
      'utente': utente,
      'utente_username': utenteUsername,
      'arnie': arnie,
      'note': note,
      'blocco_covata_attivo': bloccoCovataAttivo,
      'data_inizio_blocco': dataInizioBlocco,
      'data_fine_blocco': dataFineBlocco,
      'metodo_blocco': metodoBlocco,
      'note_blocco': noteBlocco,
    };
  }
  
  bool isActive() {
    return stato == 'programmato' || stato == 'in_corso';
  }
}

/// models/tipo_trattamento.dart - Modello per i tipi di trattamento
class TipoTrattamento {
  final int id;
  final String nome;
  final String principioAttivo;
  final String? descrizione;
  final String? istruzioni;
  final int tempoSospensione;
  final bool richiedeBloccoCovata;
  final int giorniBloccoCovata;
  final String? notaBloccoCovata;
  
  TipoTrattamento({
    required this.id,
    required this.nome,
    required this.principioAttivo,
    this.descrizione,
    this.istruzioni,
    required this.tempoSospensione,
    required this.richiedeBloccoCovata,
    required this.giorniBloccoCovata,
    this.notaBloccoCovata,
  });
  
  factory TipoTrattamento.fromJson(Map<String, dynamic> json) {
    return TipoTrattamento(
      id: json['id'],
      nome: json['nome'],
      principioAttivo: json['principio_attivo'],
      descrizione: json['descrizione'],
      istruzioni: json['istruzioni'],
      tempoSospensione: json['tempo_sospensione'],
      richiedeBloccoCovata: json['richiede_blocco_covata'],
      giorniBloccoCovata: json['giorni_blocco_covata'],
      notaBloccoCovata: json['nota_blocco_covata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'principio_attivo': principioAttivo,
      'descrizione': descrizione,
      'istruzioni': istruzioni,
      'tempo_sospensione': tempoSospensione,
      'richiede_blocco_covata': richiedeBloccoCovata,
      'giorni_blocco_covata': giorniBloccoCovata,
      'nota_blocco_covata': notaBloccoCovata,
    };
  }
}