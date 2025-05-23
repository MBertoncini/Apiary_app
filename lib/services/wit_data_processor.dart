// lib/services/wit_data_processor.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_entry.dart';
import 'voice_data_processor.dart';

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
          'v': '20250331', // Versione API aggiornata
        },
      );
      
      // Log per debug
      debugPrint('Sending text to Wit.ai: "$text"');
      
      // Invia richiesta
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $_witApiToken',
        'Accept': 'application/json',
      }).timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('La richiesta a Wit.ai è scaduta');
      });
      
      if (response.statusCode == 200) {
        try {
          final responseJson = jsonDecode(response.body);
          
          // Log per debug
          debugPrint('Wit.ai response keys: ${responseJson.keys.toList().join(', ')}');
          
          // Trasforma risposta Wit.ai in un oggetto VoiceEntry
          return _extractVoiceEntry(responseJson, text);
        } catch (e) {
          _error = 'Errore nel parsing della risposta: $e';
          debugPrint('JSON decoding error: $_error');
          debugPrint('Response body excerpt: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
          return null;
        }
      } else {
        _error = 'Errore API Wit.ai: ${response.statusCode}';
        debugPrint('$_error - ${response.body}');
        return null;
      }
    } catch (e) {
      _error = 'Errore nella comunicazione: $e';
      debugPrint('Network error: $_error');
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
      final intents = witResponse['intents'] as List<dynamic>? ?? [];
      
      debugPrint('Entities estratte: $entities');
      debugPrint('Intents estratti: $intents');
      
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
      
      // Estrai nome apiario (manteniamo la compatibilità con il vecchio formato)
      if (entities.containsKey('apiario_nome:apiario_nome')) {
        final values = entities['apiario_nome:apiario_nome'] as List<dynamic>;
        if (values.isNotEmpty) {
          apiarioNome = values.first['value'] as String?;
        }
      }
      
      // Estrai numero arnia - adattato per gestire 'wit$number:arnia'
      if (entities.containsKey('wit\$number:arnia')) {
        final values = entities['wit\$number:arnia'] as List<dynamic>;
        if (values.isNotEmpty) {
          // Prendi il primo valore per il numero dell'arnia
          arniaNumero = (values.first['value'] is num) 
              ? (values.first['value'] as num).toInt() 
              : int.tryParse(values.first['value'].toString());
        }
      } else if (entities.containsKey('arnia_numero:arnia_numero')) {
        // Manteniamo la compatibilità con il vecchio formato
        final values = entities['arnia_numero:arnia_numero'] as List<dynamic>;
        if (values.isNotEmpty) {
          arniaNumero = int.tryParse(values.first['value'].toString());
        }
      }
      
      // Estrai info regina - usando l'entità 'regina_stato:regina_stato' se disponibile
      if (entities.containsKey('regina_stato:regina_stato')) {
        final values = entities['regina_stato:regina_stato'] as List<dynamic>;
        if (values.isNotEmpty) {
          final stato = values.first['value'] as String?;
          if (stato?.toLowerCase() == 'presente') {
            presenzaRegina = true;
          } else if (stato?.toLowerCase() == 'assente') {
            presenzaRegina = false;
          }
        }
      } else {
        // Fallback al metodo precedente analizzando il testo
        if (text.toLowerCase().contains('regina presente') || 
            text.toLowerCase().contains('presenza regina')) {
          presenzaRegina = true;
        } else if (text.toLowerCase().contains('regina assente') || 
                  text.toLowerCase().contains('assenza regina')) {
          presenzaRegina = false;
        }
      }
      
      // Estrai info telaini scorte da 'wit$number:telaini_scorte'
      if (entities.containsKey('wit\$number:telaini_scorte')) {
        final values = entities['wit\$number:telaini_scorte'] as List<dynamic>;
        if (values.isNotEmpty) {
          telainiScorte = (values.first['value'] is num) 
              ? (values.first['value'] as num).toInt() 
              : int.tryParse(values.first['value'].toString());
        }
      }
      
      // Estrai info telaini covata da 'wit$number:telaini_covata' se disponibile
      if (entities.containsKey('wit\$number:telaini_covata')) {
        final values = entities['wit\$number:telaini_covata'] as List<dynamic>;
        if (values.isNotEmpty) {
          telainiCovata = (values.first['value'] is num) 
              ? (values.first['value'] as num).toInt() 
              : int.tryParse(values.first['value'].toString());
        }
      }
      
      // Determina il tipo di comando dagli intents
      if (intents.isNotEmpty) {
        final primoIntent = intents.first['name'] as String?;
        if (primoIntent == 'ControlloArnia') {
          tipoComando = 'controllo';
        } else if (primoIntent == 'TrattamentoArnia') {
          tipoComando = 'trattamento';
        }
      }
      
      // Manteniamo anche l'analisi del testo come fallback
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
      
      // Estrai informazioni su telaini come fallback (ricerca pattern come "X telaini" o "X telaini di covata/scorte")
      if (telainiTotali == null || telainiCovata == null || telainiScorte == null) {
        final telainiRegex = RegExp(r'(\d+)\s+telaini(?:\s+di\s+(\w+))?');
        final matches = telainiRegex.allMatches(text.toLowerCase());
        
        for (final match in matches) {
          final count = int.tryParse(match.group(1) ?? '');
          final type = match.group(2);
          
          if (count != null) {
            if (type == null && telainiTotali == null) {
              telainiTotali = count;
            } else if (type == 'covata' && telainiCovata == null) {
              telainiCovata = count;
            } else if ((type == 'scorte' || type == 'miele') && telainiScorte == null) {
              telainiScorte = count;
            }
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
      
      // Se tipoComando non è stato estratto dagli intents, determina dal testo
      if (tipoComando == null) {
        if (text.toLowerCase().contains('controllo') || 
            text.toLowerCase().contains('ispezione')) {
          tipoComando = 'controllo';
        } else if (text.toLowerCase().contains('trattamento')) {
          tipoComando = 'trattamento';
        } else {
          tipoComando = 'controllo'; // Default
        }
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