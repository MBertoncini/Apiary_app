// lib/models/attrezzatura.dart
import '../l10n/app_strings.dart';

class Attrezzatura {
  final int id;
  final String nome;
  final int? categoria;
  final String? categoriaNome;
  final String? descrizione;
  final String? marca;
  final String? modello;
  final String? numeroSerie;
  final int? proprietario;
  final String? proprietarioUsername;
  final int? gruppo;
  final String? gruppoNome;
  final bool condivisoConGruppo;
  final String? stato; // disponibile, in_uso, manutenzione, dismesso, prestato
  final String? condizione; // nuovo, ottimo, buono, discreto, usurato, da_riparare
  final int? apiario;
  final String? apiarioNome;
  final String? posizione;
  final double? prezzoAcquisto;
  final DateTime? dataAcquisto;
  final String? fornitore;
  final DateTime? garanziaFinoA;
  final int vitaUtileAnni;
  final int quantita;
  final String? unitaMisura;
  final String? note;
  final String? immagine;
  final DateTime? dataCreazione;
  final DateTime? dataModifica;

  Attrezzatura({
    required this.id,
    required this.nome,
    this.categoria,
    this.categoriaNome,
    this.descrizione,
    this.marca,
    this.modello,
    this.numeroSerie,
    this.proprietario,
    this.proprietarioUsername,
    this.gruppo,
    this.gruppoNome,
    this.condivisoConGruppo = false,
    this.stato,
    this.condizione,
    this.apiario,
    this.apiarioNome,
    this.posizione,
    this.prezzoAcquisto,
    this.dataAcquisto,
    this.fornitore,
    this.garanziaFinoA,
    this.vitaUtileAnni = 5,
    this.quantita = 1,
    this.unitaMisura,
    this.note,
    this.immagine,
    this.dataCreazione,
    this.dataModifica,
  });

  factory Attrezzatura.fromJson(Map<String, dynamic> json) {
    return Attrezzatura(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      nome: json['nome'] ?? '',
      categoria: json['categoria'],
      categoriaNome: json['categoria_nome'],
      descrizione: json['descrizione'],
      marca: json['marca'],
      modello: json['modello'],
      numeroSerie: json['numero_serie'],
      proprietario: json['proprietario'],
      proprietarioUsername: json['proprietario_username'],
      gruppo: json['gruppo'],
      gruppoNome: json['gruppo_nome'],
      condivisoConGruppo: json['condiviso_con_gruppo'] ?? false,
      stato: json['stato'],
      condizione: json['condizione'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      posizione: json['posizione'],
      prezzoAcquisto: json['prezzo_acquisto'] != null
          ? double.tryParse(json['prezzo_acquisto'].toString())
          : null,
      dataAcquisto: json['data_acquisto'] != null
          ? DateTime.tryParse(json['data_acquisto'])
          : null,
      fornitore: json['fornitore'],
      garanziaFinoA: json['garanzia_fino_a'] != null
          ? DateTime.tryParse(json['garanzia_fino_a'])
          : null,
      vitaUtileAnni: json['vita_utile_anni'] ?? 5,
      quantita: json['quantita'] ?? 1,
      unitaMisura: json['unita_misura'],
      note: json['note'],
      immagine: json['immagine'],
      dataCreazione: json['data_creazione'] != null
          ? DateTime.tryParse(json['data_creazione'])
          : null,
      dataModifica: json['data_modifica'] != null
          ? DateTime.tryParse(json['data_modifica'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'categoria_nome': categoriaNome,
      'descrizione': descrizione,
      'marca': marca,
      'modello': modello,
      'numero_serie': numeroSerie,
      'proprietario': proprietario,
      'proprietario_username': proprietarioUsername,
      'gruppo': gruppo,
      'gruppo_nome': gruppoNome,
      'condiviso_con_gruppo': condivisoConGruppo,
      'stato': stato,
      'condizione': condizione,
      'apiario': apiario,
      'apiario_nome': apiarioNome,
      'posizione': posizione,
      'prezzo_acquisto': prezzoAcquisto,
      'data_acquisto': dataAcquisto?.toIso8601String().split('T')[0],
      'fornitore': fornitore,
      'garanzia_fino_a': garanziaFinoA?.toIso8601String().split('T')[0],
      'vita_utile_anni': vitaUtileAnni,
      'quantita': quantita,
      'unita_misura': unitaMisura,
      'note': note,
      'immagine': immagine,
      'data_creazione': dataCreazione?.toIso8601String(),
      'data_modifica': dataModifica?.toIso8601String(),
    };
  }

  // Stati disponibili (from Django STATO_CHOICES)
  static const List<String> statiDisponibili = [
    'disponibile',
    'in_uso',
    'manutenzione',
    'dismesso',
    'prestato',
  ];

  String getStatoDisplay([AppStrings? s]) {
    if (s != null) {
      switch (stato) {
        case 'disponibile':  return s.attrezzaturaStatoDisponibile;
        case 'in_uso':       return s.attrezzaturaStatoInUso;
        case 'manutenzione': return s.attrezzaturaStatoManutenzione;
        case 'dismesso':     return s.attrezzaturaStatoDismesso;
        case 'prestato':     return s.attrezzaturaStatoPrestato;
        default:             return stato ?? s.attrezzaturaStatoNonSpecificato;
      }
    }
    switch (stato) {
      case 'disponibile':  return 'Disponibile';
      case 'in_uso':       return 'In Uso';
      case 'manutenzione': return 'In Manutenzione';
      case 'dismesso':     return 'Dismesso';
      case 'prestato':     return 'Prestato';
      default:             return stato ?? 'Non specificato';
    }
  }

  // Condizioni disponibili (from Django CONDIZIONE_CHOICES)
  static const List<String> condizioniDisponibili = [
    'nuovo',
    'ottimo',
    'buono',
    'discreto',
    'usurato',
    'da_riparare',
  ];

  String getCondizioneDisplay([AppStrings? s]) {
    if (s != null) {
      switch (condizione) {
        case 'nuovo':      return s.attrezzaturaCondizioneNuovo;
        case 'ottimo':     return s.attrezzaturaCondizioneOttimo;
        case 'buono':      return s.attrezzaturaCondizioneBuono;
        case 'discreto':   return s.attrezzaturaCondizioneDiscreto;
        case 'usurato':    return s.attrezzaturaCondizioneUsurato;
        case 'da_riparare': return s.attrezzaturaCondizioneDaRiparare;
        default:           return condizione ?? s.attrezzaturaCondizioneNonSpecificato;
      }
    }
    switch (condizione) {
      case 'nuovo':      return 'Nuovo';
      case 'ottimo':     return 'Ottimo';
      case 'buono':      return 'Buono';
      case 'discreto':   return 'Discreto';
      case 'usurato':    return 'Usurato';
      case 'da_riparare': return 'Da Riparare';
      default:           return condizione ?? 'Non specificato';
    }
  }
}
