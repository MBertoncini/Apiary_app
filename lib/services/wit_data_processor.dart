// lib/services/wit_data_processor.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_entry.dart';
import 'voice_data_processor.dart'; // Add this import

class WitDataProcessor extends ChangeNotifier with VoiceDataProcessor {
  // Constants
  static const String _witApiUrl = 'https://api.wit.ai/message';
  static const String _witApiToken = '2NJ4OP6FZXEWAJ56GC7PET2KOKXIXJZM'; // Stesso token usato per Speech
  
  // Stato
  bool _isProcessing = false;
  String? _error;
  
  // Getters
  bool get isProcessing => _isProcessing;
  @override
  String? get error => _error;
  
  // Processa testo trascritto per estrarre informazioni strutturate
  @override
  Future<VoiceEntry?> processVoiceInput(String text) async {
    if (text.isEmpty) return null;
    
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      // Prepara URL con query per l'interpretazione del testo
      final uri = Uri.parse('$_witApiUrl').replace(
        queryParameters: {
          'q': text,
          'v': '20230215', // Versione API
        },
      );
      
      // Invia richiesta
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $_witApiToken',
        'Accept': 'application/json',
      });
      
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        
        // Trasforma risposta Wit.ai in un oggetto VoiceEntry
        return _extractVoiceEntry(responseJson, text);
      } else {
        throw Exception('Errore API Wit.ai: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Errore nell\'elaborazione: $_error');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Estrai informazioni strutturate da risposta Wit.ai
  VoiceEntry? _extractVoiceEntry(Map<String, dynamic> witResponse, String originalText) {
    try {
      final text = witResponse['text'] as String? ?? originalText;
      final entities = witResponse['entities'] as Map<String, dynamic>? ?? {};
      final traits = witResponse['traits'] as Map<String, dynamic>? ?? {};
      
      debugPrint('Entities estratte: $entities');
      
      // Estrai informazioni comuni
      String? apiarioNome;
      int? arniaNumero;
      bool? presenzaRegina;
      bool? reginaVista;
      bool? uovaFresche;
      bool? celleReali;
      int? telainiTotali;
      int? telainiCovata;
      int? telainiScorte;
      String? forzaFamiglia;
      bool? sciamatura;
      bool? problemiSanitari;
      String? tipoProblema;
      String? tipoComando;
      
      // Estrai nome apiario
      if (entities.containsKey('apiario_nome:apiario_nome')) {
        final values = entities['apiario_nome:apiario_nome'] as List<dynamic>;
        if (values.isNotEmpty) {
          apiarioNome = values.first['value'] as String?;
        }
      }
      
      // Estrai numero arnia
      if (entities.containsKey('arnia_numero:arnia_numero')) {
        final values = entities['arnia_numero:arnia_numero'] as List<dynamic>;
        if (values.isNotEmpty) {
          arniaNumero = int.tryParse(values.first['value'].toString());
        }
      }
      
      // Estrai info regina
      if (text.toLowerCase().contains('regina presente') || 
          text.toLowerCase().contains('presenza regina')) {
        presenzaRegina = true;
      } else if (text.toLowerCase().contains('regina assente') || 
                text.toLowerCase().contains('assenza regina')) {
        presenzaRegina = false;
      }
      
      if (text.toLowerCase().contains('regina vista')) {
        reginaVista = true;
      } else if (text.toLowerCase().contains('regina non vista')) {
        reginaVista = false;
      }
      
      if (text.toLowerCase().contains('uova fresche')) {
        uovaFresche = true;
      }
      
      if (text.toLowerCase().contains('celle reali')) {
        celleReali = true;
      }
      
      // Estrai informazioni su telaini
      // Ricerca pattern come "X telaini" o "X telaini di covata/scorte"
      final telainiRegex = RegExp(r'(\d+)\s+telaini(?:\s+di\s+(\w+))?');
      final matches = telainiRegex.allMatches(text.toLowerCase());
      
      for (final match in matches) {
        final count = int.tryParse(match.group(1) ?? '');
        final type = match.group(2);
        
        if (count != null) {
          if (type == null) {
            telainiTotali = count;
          } else if (type == 'covata') {
            telainiCovata = count;
          } else if (type == 'scorte' || type == 'miele') {
            telainiScorte = count;
          }
        }
      }
      
      // Estrai forza famiglia
      if (text.toLowerCase().contains('famiglia forte')) {
        forzaFamiglia = 'forte';
      } else if (text.toLowerCase().contains('famiglia debole')) {
        forzaFamiglia = 'debole';
      } else if (text.toLowerCase().contains('famiglia normale')) {
        forzaFamiglia = 'normale';
      }
      
      // Estrai info su problemi
      if (text.toLowerCase().contains('sciamatura')) {
        sciamatura = true;
      }
      
      if (text.toLowerCase().contains('problema sanitario') || 
          text.toLowerCase().contains('problemi sanitari')) {
        problemiSanitari = true;
      }
      
      // Estrai tipo di problema
      final problemiPattern = RegExp(
        r'(varroa|nosema|covata calcificata|peste europea|tarma|saccheggio)',
        caseSensitive: false
      );
      final problemiMatch = problemiPattern.firstMatch(text.toLowerCase());
      
      if (problemiMatch != null) {
        tipoProblema = problemiMatch.group(0);
        problemiSanitari = true;
      }
      
      // Determina il tipo di comando
      if (text.toLowerCase().contains('controllo') || 
          text.toLowerCase().contains('ispezione')) {
        tipoComando = 'controllo';
      } else if (text.toLowerCase().contains('trattamento')) {
        tipoComando = 'trattamento';
      } else {
        tipoComando = 'controllo'; // Default
      }
      
      // Crea VoiceEntry con le informazioni estratte
      return VoiceEntry(
        apiarioNome: apiarioNome,
        arniaNumero: arniaNumero,
        tipoComando: tipoComando,
        data: DateTime.now(),
        presenzaRegina: presenzaRegina,
        reginaVista: reginaVista,
        uovaFresche: uovaFresche,
        celleReali: celleReali,
        telainiTotali: telainiTotali,
        telainiCovata: telainiCovata,
        telainiScorte: telainiScorte,
        forzaFamiglia: forzaFamiglia,
        sciamatura: sciamatura,
        problemiSanitari: problemiSanitari,
        tipoProblema: tipoProblema,
        note: text,
      );
    } catch (e) {
      debugPrint('Errore nell\'estrazione dei dati: $e');
      return null;
    }
  }
  
  // Cancella errore corrente
  void clearError() {
    _error = null;
    notifyListeners();
  }
}