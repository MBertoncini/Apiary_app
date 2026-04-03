/// Rappresenta una colonia di api con il proprio ciclo di vita.
/// Una colonia vive in un'Arnia (box completo) o in un Nucleo (box piccolo);
/// il contenitore può cambiare, ma la storia biologica rimane sulla colonia.
class Colonia {
  final int id;
  final int apiario;
  final String apiarioNome;
  final int? arnia;        // id Arnia (null se in nucleo o senza contenitore)
  final int? nucleo;       // id Nucleo (null se in arnia o senza contenitore)
  final String contenitore;       // 'arnia' | 'nucleo' | null
  final int? contenitoreNumero;   // numero del box fisico
  final String dataInizio;
  final String? dataFine;
  final String stato;
  final bool isAttiva;
  final String? motivoFine;
  final String? noteFine;
  final String? note;
  final int? coloniaOrigineId;
  final int? coloniaSuccessoreId;
  final String? dataCreazione;
  // Dettaglio (presente solo nel DetailSerializer)
  final int? nControlli;
  final Map<String, dynamic>? reginaAttiva;

  Colonia({
    required this.id,
    required this.apiario,
    required this.apiarioNome,
    this.arnia,
    this.nucleo,
    required this.contenitore,
    this.contenitoreNumero,
    required this.dataInizio,
    this.dataFine,
    required this.stato,
    required this.isAttiva,
    this.motivoFine,
    this.noteFine,
    this.note,
    this.coloniaOrigineId,
    this.coloniaSuccessoreId,
    this.dataCreazione,
    this.nControlli,
    this.reginaAttiva,
  });

  factory Colonia.fromJson(Map<String, dynamic> json) {
    return Colonia(
      id:                  json['id'] as int,
      apiario:             json['apiario'] as int,
      apiarioNome:         json['apiario_nome'] as String? ?? '',
      arnia:               json['arnia'] as int?,
      nucleo:              json['nucleo'] as int?,
      contenitore:         json['contenitore'] as String? ?? '',
      contenitoreNumero:   json['contenitore_numero'] as int?,
      dataInizio:          json['data_inizio'] as String,
      dataFine:            json['data_fine'] as String?,
      stato:               json['stato'] as String,
      isAttiva:            json['is_attiva'] as bool? ?? false,
      motivoFine:          json['motivo_fine'] as String?,
      noteFine:            json['note_fine'] as String?,
      note:                json['note'] as String?,
      coloniaOrigineId:    json['colonia_origine'] as int?,
      coloniaSuccessoreId: json['colonia_successore'] as int?,
      dataCreazione:       json['data_creazione'] as String?,
      nControlli:          json['n_controlli'] as int?,
      reginaAttiva:        json['regina_attiva'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':                  id,
      'apiario':             apiario,
      'apiario_nome':        apiarioNome,
      'arnia':               arnia,
      'nucleo':              nucleo,
      'contenitore':         contenitore,
      'contenitore_numero':  contenitoreNumero,
      'data_inizio':         dataInizio,
      'data_fine':           dataFine,
      'stato':               stato,
      'is_attiva':           isAttiva,
      'motivo_fine':         motivoFine,
      'note_fine':           noteFine,
      'note':                note,
      'colonia_origine':     coloniaOrigineId,
      'colonia_successore':  coloniaSuccessoreId,
      'data_creazione':      dataCreazione,
      'n_controlli':         nControlli,
      'regina_attiva':       reginaAttiva,
    };
  }

  Colonia copyWith({
    String? stato,
    String? dataFine,
    String? motivoFine,
    String? noteFine,
    String? note,
    int? arnia,
    int? nucleo,
    bool? isAttiva,
    int? coloniaSuccessoreId,
  }) {
    return Colonia(
      id:                  id,
      apiario:             apiario,
      apiarioNome:         apiarioNome,
      arnia:               arnia ?? this.arnia,
      nucleo:              nucleo ?? this.nucleo,
      contenitore:         contenitore,
      contenitoreNumero:   contenitoreNumero,
      dataInizio:          dataInizio,
      dataFine:            dataFine ?? this.dataFine,
      stato:               stato ?? this.stato,
      isAttiva:            isAttiva ?? this.isAttiva,
      motivoFine:          motivoFine ?? this.motivoFine,
      noteFine:            noteFine ?? this.noteFine,
      note:                note ?? this.note,
      coloniaOrigineId:    coloniaOrigineId,
      coloniaSuccessoreId: coloniaSuccessoreId ?? this.coloniaSuccessoreId,
      dataCreazione:       dataCreazione,
      nControlli:          nControlli,
      reginaAttiva:        reginaAttiva,
    );
  }

  /// Label leggibile per il contenitore fisico
  String get contenitoreLabel {
    if (contenitore == 'arnia' && contenitoreNumero != null) {
      return 'Arnia $contenitoreNumero';
    }
    if (contenitore == 'nucleo' && contenitoreNumero != null) {
      return 'Nucleo $contenitoreNumero';
    }
    return 'Senza contenitore';
  }

  /// Label dello stato in italiano
  static const Map<String, String> _statoLabels = {
    'attiva':    'Attiva',
    'inattiva':  'Inattiva',
    'morta':     'Morta',
    'venduta':   'Ceduta/Venduta',
    'sciamata':  'Sciamata',
    'unita':     'Unita ad altra',
    'nucleo':    'Ridotta a nucleo',
    'eliminata': 'Eliminata',
  };

  String get statoLabel => _statoLabels[stato] ?? stato;
}
