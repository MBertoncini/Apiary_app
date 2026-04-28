// lib/models/pagamento.dart
class Pagamento {
  final int id;
  final int utente;
  final String utenteUsername;
  final int? destinatario;
  final String? destinatarioUsername;
  final double importo;
  final String data;
  final String descrizione;
  final int? gruppo;
  final String? gruppoNome;

  Pagamento({
    required this.id,
    required this.utente,
    required this.utenteUsername,
    this.destinatario,
    this.destinatarioUsername,
    required this.importo,
    required this.data,
    required this.descrizione,
    this.gruppo,
    this.gruppoNome,
  });

  bool get isSaldo => destinatario != null;

  factory Pagamento.fromJson(Map<String, dynamic> json) {
    // Campi critici: senza id, utente, data o importo non possiamo
    // mostrare il pagamento né farlo entrare nel bilancio. Fail-fast con
    // FormatException così il loop di parse della cache lo skippa.
    final id = json['id'];
    final utente = json['utente'];
    final data = json['data'];
    final importoRaw = json['importo'];
    if (id is! int) {
      throw FormatException('Pagamento.fromJson: id mancante o invalido', json);
    }
    if (utente is! int) {
      throw FormatException('Pagamento.fromJson: utente mancante o invalido', json);
    }
    if (data is! String || data.isEmpty) {
      throw FormatException('Pagamento.fromJson: data mancante', json);
    }
    if (importoRaw == null) {
      throw FormatException('Pagamento.fromJson: importo nullo', json);
    }
    final importo = double.tryParse(importoRaw.toString());
    if (importo == null) {
      throw FormatException('Pagamento.fromJson: importo non parsabile ($importoRaw)', json);
    }

    return Pagamento(
      id: id,
      utente: utente,
      utenteUsername: json['utente_username'] ?? 'Sconosciuto',
      destinatario: json['destinatario'],
      destinatarioUsername: json['destinatario_username'],
      importo: importo,
      data: data,
      descrizione: (json['descrizione'] as String?) ?? '',
      gruppo: json['gruppo'],
      gruppoNome: json['gruppo_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utente': utente,
      'utente_username': utenteUsername,
      'destinatario': destinatario,
      'destinatario_username': destinatarioUsername,
      'importo': importo,
      'data': data,
      'descrizione': descrizione,
      'gruppo': gruppo,
      'gruppo_nome': gruppoNome,
    };
  }
}