import 'dart:convert';

class ControlloArnia {
  final int id;
  final int arnia;
  final int arniaNumero;
  final String apiarioNome;
  final int apiarioId;
  final String data;
  final int utente;
  final String utenteUsername;
  final int telainiScorte;
  final int telainiCovata;
  final bool presenzaRegina;
  final bool sciamatura;
  final String? dataSciamatura;
  final String? noteSciamatura;
  final bool problemiSanitari;
  final String? noteProblemi;
  final String? note;
  final String dataCreazione;
  final bool reginaVista;
  final bool uovaFresche;
  final bool celleReali;
  final int numeroCelleReali;
  final bool reginaSostituita;
  
  ControlloArnia({
    required this.id,
    required this.arnia,
    required this.arniaNumero,
    required this.apiarioNome,
    required this.apiarioId,
    required this.data,
    required this.utente,
    required this.utenteUsername,
    required this.telainiScorte,
    required this.telainiCovata,
    required this.presenzaRegina,
    required this.sciamatura,
    this.dataSciamatura,
    this.noteSciamatura,
    required this.problemiSanitari,
    this.noteProblemi,
    this.note,
    required this.dataCreazione,
    required this.reginaVista,
    required this.uovaFresche,
    required this.celleReali,
    required this.numeroCelleReali,
    required this.reginaSostituita,
  });
  
  factory ControlloArnia.fromJson(Map<String, dynamic> json) {
    return ControlloArnia(
      id: json['id'],
      arnia: json['arnia'],
      arniaNumero: json['arnia_numero'],
      apiarioNome: json['apiario_nome'],
      apiarioId: json['apiario_id'],
      data: json['data'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      telainiScorte: json['telaini_scorte'],
      telainiCovata: json['telaini_covata'],
      presenzaRegina: json['presenza_regina'] ?? false,
      sciamatura: json['sciamatura'] ?? false,
      dataSciamatura: json['data_sciamatura'],
      noteSciamatura: json['note_sciamatura'],
      problemiSanitari: json['problemi_sanitari'] ?? false,
      noteProblemi: json['note_problemi'],
      note: json['note'],
      dataCreazione: json['data_creazione'] ?? '',
      reginaVista: json['regina_vista'] ?? false,
      uovaFresche: json['uova_fresche'] ?? false,
      celleReali: json['celle_reali'] ?? false,
      numeroCelleReali: json['numero_celle_reali'] ?? 0,
      reginaSostituita: json['regina_sostituita'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arnia': arnia,
      'arnia_numero': arniaNumero,
      'apiario_nome': apiarioNome,
      'apiario_id': apiarioId,
      'data': data,
      'utente': utente,
      'utente_username': utenteUsername,
      'telaini_scorte': telainiScorte,
      'telaini_covata': telainiCovata,
      'presenza_regina': presenzaRegina,
      'sciamatura': sciamatura,
      'data_sciamatura': dataSciamatura,
      'note_sciamatura': noteSciamatura,
      'problemi_sanitari': problemiSanitari,
      'note_problemi': noteProblemi,
      'note': note,
      'data_creazione': dataCreazione,
      'regina_vista': reginaVista,
      'uova_fresche': uovaFresche,
      'celle_reali': celleReali,
      'numero_celle_reali': numeroCelleReali,
      'regina_sostituita': reginaSostituita,
    };
  }
}