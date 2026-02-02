// lib/models/spesa_attrezzatura.dart
class SpesaAttrezzatura {
  final int id;
  final int? attrezzatura;
  final String? attrezzaturaNome;
  final int? gruppo;
  final String? gruppoNome;
  final String tipo; // acquisto, manutenzione, riparazione, accessori, consumabili, altro
  final String? tipoDisplay;
  final String descrizione;
  final double importo;
  final DateTime data;
  final String? fornitore;
  final String? numeroFattura;
  final int? utente;
  final String? utenteUsername;
  final String? note;
  final DateTime? dataCreazione;

  SpesaAttrezzatura({
    required this.id,
    this.attrezzatura,
    this.attrezzaturaNome,
    this.gruppo,
    this.gruppoNome,
    required this.tipo,
    this.tipoDisplay,
    required this.descrizione,
    required this.importo,
    required this.data,
    this.fornitore,
    this.numeroFattura,
    this.utente,
    this.utenteUsername,
    this.note,
    this.dataCreazione,
  });

  factory SpesaAttrezzatura.fromJson(Map<String, dynamic> json) {
    return SpesaAttrezzatura(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      attrezzatura: json['attrezzatura'],
      attrezzaturaNome: json['attrezzatura_nome'],
      gruppo: json['gruppo'],
      gruppoNome: json['gruppo_nome'],
      tipo: json['tipo'] ?? 'altro',
      tipoDisplay: json['tipo_display'],
      descrizione: json['descrizione'] ?? '',
      importo: double.tryParse(json['importo'].toString()) ?? 0.0,
      data: json['data'] != null
          ? DateTime.parse(json['data'])
          : DateTime.now(),
      fornitore: json['fornitore'],
      numeroFattura: json['numero_fattura'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      note: json['note'],
      dataCreazione: json['data_creazione'] != null
          ? DateTime.tryParse(json['data_creazione'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attrezzatura': attrezzatura,
      'gruppo': gruppo,
      'tipo': tipo,
      'descrizione': descrizione,
      'importo': importo,
      'data': data.toIso8601String().split('T')[0],
      'fornitore': fornitore,
      'numero_fattura': numeroFattura,
      'note': note,
    };
  }

  // Tipi di spesa disponibili (from Django TIPO_SPESA_CHOICES)
  static const List<String> tipiSpesa = [
    'acquisto',
    'manutenzione',
    'riparazione',
    'accessori',
    'consumabili',
    'altro',
  ];

  String getTipoDisplay() {
    if (tipoDisplay != null) return tipoDisplay!;
    switch (tipo) {
      case 'acquisto':
        return 'Acquisto';
      case 'manutenzione':
        return 'Manutenzione';
      case 'riparazione':
        return 'Riparazione';
      case 'accessori':
        return 'Accessori';
      case 'consumabili':
        return 'Consumabili';
      case 'altro':
        return 'Altro';
      default:
        return tipo;
    }
  }
}
