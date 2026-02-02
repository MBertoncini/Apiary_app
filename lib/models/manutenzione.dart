// lib/models/manutenzione.dart
class Manutenzione {
  final int id;
  final int attrezzatura;
  final String? attrezzaturaNome;
  final String tipo; // ordinaria, straordinaria, riparazione, pulizia, revisione, sostituzione_parti
  final String? tipoDisplay;
  final String stato; // programmata, in_corso, completata, annullata
  final String? statoDisplay;
  final DateTime dataProgrammata;
  final DateTime? dataEsecuzione;
  final String descrizione;
  final double? costo;
  final String? eseguitoDa;
  final DateTime? prossimaManutenzione;
  final String? note;
  final int? utente;
  final String? utenteUsername;
  final DateTime? dataCreazione;

  Manutenzione({
    required this.id,
    required this.attrezzatura,
    this.attrezzaturaNome,
    required this.tipo,
    this.tipoDisplay,
    this.stato = 'programmata',
    this.statoDisplay,
    required this.dataProgrammata,
    this.dataEsecuzione,
    required this.descrizione,
    this.costo,
    this.eseguitoDa,
    this.prossimaManutenzione,
    this.note,
    this.utente,
    this.utenteUsername,
    this.dataCreazione,
  });

  factory Manutenzione.fromJson(Map<String, dynamic> json) {
    return Manutenzione(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      attrezzatura: json['attrezzatura'] is String
          ? int.parse(json['attrezzatura'])
          : json['attrezzatura'],
      attrezzaturaNome: json['attrezzatura_nome'],
      tipo: json['tipo'] ?? 'ordinaria',
      tipoDisplay: json['tipo_display'],
      stato: json['stato'] ?? 'programmata',
      statoDisplay: json['stato_display'],
      dataProgrammata: json['data_programmata'] != null
          ? DateTime.parse(json['data_programmata'])
          : DateTime.now(),
      dataEsecuzione: json['data_esecuzione'] != null
          ? DateTime.tryParse(json['data_esecuzione'])
          : null,
      descrizione: json['descrizione'] ?? '',
      costo: json['costo'] != null
          ? double.tryParse(json['costo'].toString())
          : null,
      eseguitoDa: json['eseguito_da'],
      prossimaManutenzione: json['prossima_manutenzione'] != null
          ? DateTime.tryParse(json['prossima_manutenzione'])
          : null,
      note: json['note'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      dataCreazione: json['data_creazione'] != null
          ? DateTime.tryParse(json['data_creazione'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attrezzatura': attrezzatura,
      'tipo': tipo,
      'stato': stato,
      'data_programmata': dataProgrammata.toIso8601String().split('T')[0],
      'data_esecuzione': dataEsecuzione?.toIso8601String().split('T')[0],
      'descrizione': descrizione,
      'costo': costo,
      'eseguito_da': eseguitoDa,
      'prossima_manutenzione': prossimaManutenzione?.toIso8601String().split('T')[0],
      'note': note,
    };
  }

  // Tipi di manutenzione disponibili (from Django TIPO_CHOICES)
  static const List<String> tipiManutenzione = [
    'ordinaria',
    'straordinaria',
    'riparazione',
    'pulizia',
    'revisione',
    'sostituzione_parti',
  ];

  // Stati disponibili (from Django STATO_CHOICES)
  static const List<String> statiManutenzione = [
    'programmata',
    'in_corso',
    'completata',
    'annullata',
  ];

  String getTipoDisplay() {
    if (tipoDisplay != null) return tipoDisplay!;
    switch (tipo) {
      case 'ordinaria':
        return 'Manutenzione Ordinaria';
      case 'straordinaria':
        return 'Manutenzione Straordinaria';
      case 'riparazione':
        return 'Riparazione';
      case 'pulizia':
        return 'Pulizia';
      case 'revisione':
        return 'Revisione';
      case 'sostituzione_parti':
        return 'Sostituzione Parti';
      default:
        return tipo;
    }
  }

  String getStatoDisplay() {
    if (statoDisplay != null) return statoDisplay!;
    switch (stato) {
      case 'programmata':
        return 'Programmata';
      case 'in_corso':
        return 'In Corso';
      case 'completata':
        return 'Completata';
      case 'annullata':
        return 'Annullata';
      default:
        return stato;
    }
  }

  bool isInRitardo() {
    if (stato != 'programmata') return false;
    return dataProgrammata.isBefore(DateTime.now());
  }
}
