// lib/models/voice_entry.dart
import 'package:intl/intl.dart';

/// Model representing structured data extracted from voice input
class VoiceEntry {
  final int? apiarioId;
  final String? apiarioNome;
  final int? arniaId;
  final int? arniaNumero;
  final String? tipoComando;
  final DateTime? data;
  final bool? presenzaRegina;
  final bool? reginaVista;
  final bool? uovaFresche;
  final bool? celleReali;
  final int? numeroCelleReali;
  final int? telainiTotali;
  final int? telainiCovata;
  final int? telainiScorte;
  final String? forzaFamiglia;
  final bool? sciamatura;
  final bool? problemiSanitari;
  final String? tipoProblema;
  final String? note;
  
  // Constructor
  VoiceEntry({
    this.apiarioId,
    this.apiarioNome,
    this.arniaId,
    this.arniaNumero,
    this.tipoComando,
    this.data,
    this.presenzaRegina,
    this.reginaVista,
    this.uovaFresche,
    this.celleReali,
    this.numeroCelleReali,
    this.telainiTotali,
    this.telainiCovata,
    this.telainiScorte,
    this.forzaFamiglia,
    this.sciamatura,
    this.problemiSanitari,
    this.tipoProblema,
    this.note,
  });
  
  // Create a copy with modified fields
  VoiceEntry copyWith({
    int? apiarioId,
    String? apiarioNome,
    int? arniaId,
    int? arniaNumero,
    String? tipoComando,
    DateTime? data,
    bool? presenzaRegina,
    bool? reginaVista,
    bool? uovaFresche,
    bool? celleReali,
    int? numeroCelleReali,
    int? telainiTotali,
    int? telainiCovata,
    int? telainiScorte,
    String? forzaFamiglia,
    bool? sciamatura,
    bool? problemiSanitari,
    String? tipoProblema,
    String? note,
  }) {
    return VoiceEntry(
      apiarioId: apiarioId ?? this.apiarioId,
      apiarioNome: apiarioNome ?? this.apiarioNome,
      arniaId: arniaId ?? this.arniaId,
      arniaNumero: arniaNumero ?? this.arniaNumero,
      tipoComando: tipoComando ?? this.tipoComando,
      data: data ?? this.data,
      presenzaRegina: presenzaRegina ?? this.presenzaRegina,
      reginaVista: reginaVista ?? this.reginaVista,
      uovaFresche: uovaFresche ?? this.uovaFresche,
      celleReali: celleReali ?? this.celleReali,
      numeroCelleReali: numeroCelleReali ?? this.numeroCelleReali,
      telainiTotali: telainiTotali ?? this.telainiTotali,
      telainiCovata: telainiCovata ?? this.telainiCovata,
      telainiScorte: telainiScorte ?? this.telainiScorte,
      forzaFamiglia: forzaFamiglia ?? this.forzaFamiglia,
      sciamatura: sciamatura ?? this.sciamatura,
      problemiSanitari: problemiSanitari ?? this.problemiSanitari,
      tipoProblema: tipoProblema ?? this.tipoProblema,
      note: note ?? this.note,
    );
  }
  
  // Factory method to create VoiceEntry from JSON
  factory VoiceEntry.fromJson(Map<String, dynamic> json) {
    // Parse date string if provided
    DateTime? parseDate() {
      if (json['data'] != null) {
        try {
          // Try different date formats
          List<String> formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'dd-MM-yyyy'];
          for (var format in formats) {
            try {
              return DateFormat(format).parse(json['data']);
            } catch (_) {
              // Try next format
            }
          }
          
          // If all formats fail, return today
          return DateTime.now();
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return VoiceEntry(
      apiarioId: json['apiario_id'],
      apiarioNome: json['apiario_nome'],
      arniaId: json['arnia_id'],
      arniaNumero: json['arnia_numero'],
      tipoComando: json['tipo_comando'],
      data: parseDate(),
      presenzaRegina: json['presenza_regina'],
      reginaVista: json['regina_vista'],
      uovaFresche: json['uova_fresche'],
      celleReali: json['celle_reali'],
      numeroCelleReali: json['numero_celle_reali'],
      telainiTotali: json['telaini_totali'],
      telainiCovata: json['telaini_covata'],
      telainiScorte: json['telaini_scorte'],
      forzaFamiglia: json['forza_famiglia'],
      sciamatura: json['sciamatura'],
      problemiSanitari: json['problemi_sanitari'],
      tipoProblema: json['tipo_problema'],
      note: json['note'],
    );
  }
  
  // Convert VoiceEntry to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    // Only include non-null fields
    if (apiarioId != null) data['apiario_id'] = apiarioId;
    if (apiarioNome != null) data['apiario_nome'] = apiarioNome;
    if (arniaId != null) data['arnia_id'] = arniaId;
    if (arniaNumero != null) data['arnia_numero'] = arniaNumero;
    if (tipoComando != null) data['tipo_comando'] = tipoComando;
    if (data != null) data['data'] = DateFormat('yyyy-MM-dd').format(this.data!);
    if (presenzaRegina != null) data['presenza_regina'] = presenzaRegina;
    if (reginaVista != null) data['regina_vista'] = reginaVista;
    if (uovaFresche != null) data['uova_fresche'] = uovaFresche;
    if (celleReali != null) data['celle_reali'] = celleReali;
    if (numeroCelleReali != null) data['numero_celle_reali'] = numeroCelleReali;
    if (telainiTotali != null) data['telaini_totali'] = telainiTotali;
    if (telainiCovata != null) data['telaini_covata'] = telainiCovata;
    if (telainiScorte != null) data['telaini_scorte'] = telainiScorte;
    if (forzaFamiglia != null) data['forza_famiglia'] = forzaFamiglia;
    if (sciamatura != null) data['sciamatura'] = sciamatura;
    if (problemiSanitari != null) data['problemi_sanitari'] = problemiSanitari;
    if (tipoProblema != null) data['tipo_problema'] = tipoProblema;
    if (note != null) data['note'] = note;
    
    return data;
  }
  
  // Convert to database-ready map for "controllo" type
  Map<String, dynamic> toControlloData() {
    return {
      'apiario_id': apiarioId,
      'arnia_id': arniaId,
      'data': DateFormat('yyyy-MM-dd').format(data ?? DateTime.now()),
      'presenza_regina': presenzaRegina ?? false,
      'regina_vista': reginaVista ?? false,
      'uova_fresche': uovaFresche ?? false,
      'celle_reali': celleReali ?? false,
      'numero_celle_reali': numeroCelleReali ?? 0,
      'telaini_totali': telainiTotali ?? 0,
      'telaini_covata': telainiCovata ?? 0,
      'telaini_scorte': telainiScorte ?? 0,
      'sciamatura': sciamatura ?? false,
      'problemi_sanitari': problemiSanitari ?? false,
      'note': note ?? '',
    };
  }
  
  // Human-readable representation of the entry
  String toReadableString() {
    List<String> parts = [];
    
    // Location info
    if (apiarioNome != null && arniaNumero != null) {
      parts.add('Apiario: $apiarioNome, Arnia: $arniaNumero');
    } else if (apiarioNome != null) {
      parts.add('Apiario: $apiarioNome');
    } else if (arniaNumero != null) {
      parts.add('Arnia: $arniaNumero');
    }
    
    // Command type
    if (tipoComando != null) {
      parts.add('Tipo: $tipoComando');
    }
    
    // Date
    if (data != null) {
      parts.add('Data: ${DateFormat('dd/MM/yyyy').format(data!)}');
    }
    
    // Queen status
    List<String> reginaInfo = [];
    if (presenzaRegina != null) reginaInfo.add(presenzaRegina! ? 'presente' : 'assente');
    if (reginaVista != null) reginaInfo.add(reginaVista! ? 'vista' : 'non vista');
    if (uovaFresche != null) reginaInfo.add(uovaFresche! ? 'uova fresche' : 'no uova fresche');
    if (celleReali != null) reginaInfo.add(celleReali! ? 'celle reali' : 'no celle reali');
    if (numeroCelleReali != null) reginaInfo.add('$numeroCelleReali celle reali');
    
    if (reginaInfo.isNotEmpty) {
      parts.add('Regina: ${reginaInfo.join(', ')}');
    }
    
    // Frames info
    List<String> telainiInfo = [];
    if (telainiTotali != null) telainiInfo.add('$telainiTotali totali');
    if (telainiCovata != null) telainiInfo.add('$telainiCovata covata');
    if (telainiScorte != null) telainiInfo.add('$telainiScorte scorte');
    
    if (telainiInfo.isNotEmpty) {
      parts.add('Telaini: ${telainiInfo.join(', ')}');
    }
    
    // Colony strength
    if (forzaFamiglia != null) {
      parts.add('Forza famiglia: $forzaFamiglia');
    }
    
    // Problems
    List<String> problemiInfo = [];
    if (sciamatura != null && sciamatura!) problemiInfo.add('rischio sciamatura');
    if (problemiSanitari != null && problemiSanitari!) {
      problemiInfo.add('problemi sanitari');
      if (tipoProblema != null) problemiInfo.add(tipoProblema!);
    }
    
    if (problemiInfo.isNotEmpty) {
      parts.add('Problemi: ${problemiInfo.join(', ')}');
    }
    
    // Notes
    if (note != null && note!.isNotEmpty) {
      parts.add('Note: $note');
    }
    
    return parts.join('\n');
  }
  
  // Check if this is a valid entry that has required fields
  bool isValid() {
    // Minimum requirements: apiario and arnia identification
    return (apiarioId != null || apiarioNome != null) && 
           (arniaId != null || arniaNumero != null);
  }
}

/// Class to manage a batch of voice entries
class VoiceEntryBatch {
  List<VoiceEntry> entries = [];
  
  void add(VoiceEntry entry) {
    entries.add(entry);
  }
  
  void remove(int index) {
    if (index >= 0 && index < entries.length) {
      entries.removeAt(index);
    }
  }
  
  void update(int index, VoiceEntry newEntry) {
    if (index >= 0 && index < entries.length) {
      entries[index] = newEntry;
    }
  }
  
  void clear() {
    entries.clear();
  }
  
  bool get isEmpty => entries.isEmpty;
  
  int get length => entries.length;
  
  List<Map<String, dynamic>> toJsonList() {
    return entries.map((e) => e.toJson()).toList();
  }
}