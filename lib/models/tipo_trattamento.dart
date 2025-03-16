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