// lib/services/voice_data_processor.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_entry.dart';
import 'api_service.dart';

/// Service for processing voice input data using Gemini API
class VoiceDataProcessor with ChangeNotifier {
  final ApiService _apiService;
  bool _isProcessing = false;
  String? _error;
  
  // Gemini API key and endpoint - in production, use secure storage
  static const String _apiKey = "AIzaSyCgoAfYh-MjTXm9_RzHEKhlfWAxXzUFNGs";
  static const String _apiUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent";
  
  // Command types that can be recognized
  static const List<String> supportedCommands = [
    'ispezione', 'controllo', 'regina', 'telaini', 'scorte',
    'covata', 'problemi', 'trattamento', 'note'
  ];
  
  // Getters
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  
  // Constructor
  VoiceDataProcessor(this._apiService);
  
  /// Process voice input to extract structured data
  Future<VoiceEntry?> processVoiceInput(String voiceInput) async {
    if (voiceInput.isEmpty) return null;
    
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      // Create a prompt for Gemini to extract structured data
      final prompt = _createExtractionPrompt(voiceInput);
      
      // Send request to Gemini API
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [{"text": prompt}]
            }
          ],
          "generationConfig": {
            "temperature": 0.1,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        var responseText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract JSON structure from response
        final jsonRegExp = RegExp(r'\{.*\}', dotAll: true);
        final match = jsonRegExp.firstMatch(responseText);
        
        if (match != null) {
          String jsonStr = match.group(0)!;
          
          // Parse the JSON structure into a VoiceEntry
          Map<String, dynamic> data = jsonDecode(jsonStr);
          final voiceEntry = VoiceEntry.fromJson(data);
          
          _isProcessing = false;
          notifyListeners();
          return voiceEntry;
        } else {
          throw Exception('Non è stato possibile estrarre dati strutturati dalla risposta');
        }
      } else {
        throw Exception('Errore nella richiesta all\'API: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Create the prompt for Gemini API to extract structured data
  String _createExtractionPrompt(String voiceInput) {
    return '''
    Sei un assistente specializzato per apicoltori che estrae dati strutturati da comandi vocali.
    
    L'apicoltore ha fornito il seguente comando vocale:
    "$voiceInput"
    
    Estrai i dati strutturati e restituiscili in formato JSON con i seguenti campi (solo se menzionati):
    
    1. apiario_id o apiario_nome: ID o nome dell'apiario
    2. arnia_id o arnia_numero: ID o numero dell'arnia
    3. tipo_comando: Tipo di comando (ispezione, controllo, regina, telaini, etc.)
    4. data: Data dell'ispezione (se menzionata, altrimenti usa la data odierna)
    5. presenza_regina: booleano che indica se la regina è presente
    6. regina_vista: booleano che indica se la regina è stata vista
    7. uova_fresche: booleano che indica se sono presenti uova fresche
    8. celle_reali: booleano che indica se sono presenti celle reali
    9. numero_celle_reali: numero di celle reali (se menzionato)
    10. telaini_totali: numero totale di telaini
    11. telaini_covata: numero di telaini con covata
    12. telaini_scorte: numero di telaini con scorte
    13. forza_famiglia: valutazione della famiglia (debole, normale, forte)
    14. sciamatura: booleano che indica se c'è rischio di sciamatura
    15. problemi_sanitari: booleano che indica se ci sono problemi sanitari
    16. tipo_problema: descrizione del tipo di problema riscontrato
    17. note: eventuali note aggiuntive
    
    Segui queste regole:
    - Includi solo i campi che l'apicoltore ha menzionato nel comando vocale
    - Per valori numerici, estrai solo il numero (ad es. "3 telaini" => 3)
    - Sostituisci parole come "sì", "presente", "osservata" con valori booleani true
    - Se il campo non è menzionato, non includerlo nel JSON
    - Se il contenuto è ambiguo, usa il valore più probabile basato sul contesto
    - Assumi che l'apicoltore stia facendo un'ispezione oggi se non specifica una data
    
    Restituisci SOLO il JSON, senza testo introduttivo o di chiusura.
    ''';
  }
  
  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Validate and match apiaries and hives with existing database entries
  Future<Map<String, int>> validateEntities(VoiceEntry entry) async {
    Map<String, int> result = {};
    
    try {
      // Check if apiario exists
      if (entry.apiarioNome != null) {
        final apiariResponse = await _apiService.get('apiari/');
        final List<dynamic> apiari = apiariResponse['results'] ?? [];
        
        // Find matching apiario
        final matchingApiario = apiari.firstWhere(
          (a) => a['nome'].toString().toLowerCase() == entry.apiarioNome!.toLowerCase(),
          orElse: () => null
        );
        
        if (matchingApiario != null) {
          result['apiario_id'] = matchingApiario['id'];
          
          // If arnia is specified, check if it exists in this apiario
          if (entry.arniaNumero != null) {
            final arnieResponse = await _apiService.get('apiari/${matchingApiario['id']}/arnie/');
            final List<dynamic> arnie = arnieResponse['results'] ?? [];
            
            // Find matching arnia
            final matchingArnia = arnie.firstWhere(
              (a) => a['numero'].toString() == entry.arniaNumero.toString(),
              orElse: () => null
            );
            
            if (matchingArnia != null) {
              result['arnia_id'] = matchingArnia['id'];
            }
          }
        }
      }
      
      return result;
    } catch (e) {
      _error = 'Errore nella validazione: $e';
      notifyListeners();
      return {};
    }
  }
}