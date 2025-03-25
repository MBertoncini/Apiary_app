// lib/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'api_service.dart';
import 'mcp_service.dart';

class ChatService with ChangeNotifier {
  final ApiService _apiService;
  final MCPService _mcpService;
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  
  // Chiave API per Gemini - da sostituire con la tua effettiva
  // In produzione, questa dovrebbe essere immagazzinata in modo sicuro
  static const String _apiKey = "AIzaSyCgoAfYh-MjTXm9_RzHEKhlfWAxXzUFNGs";
  static const String _apiUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent";
  
  // L'ID utente è usato per tenere traccia della conversazione
  final String _userId;
  
  ChatService(this._apiService, this._mcpService, this._userId) {
    // Inizializza con un messaggio di benvenuto
    _messages.add(
      ChatMessage(
        text: "Ciao! Sono il tuo assistente per l'apicoltura. Come posso aiutarti oggi?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
  
  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
    Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Aggiungi il messaggio dell'utente
    final userMessage = ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
        // Prepara il contesto MCP
        final mcpContext = await _prepareMCPContext();
        
        // Genera la risposta
        final response = await _generateResponse(message, mcpContext);
        
        // Aggiungi la risposta del bot
        final botMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        );
        
        _messages.add(botMessage);
        _isLoading = false;
        notifyListeners();
    } catch (e) {
        // Verifica se è un errore 503
        bool isServiceUnavailable = e.toString().contains("503") || 
                                e.toString().contains("Service Unavailable");
        
        if (isServiceUnavailable) {
        _error = "Errore 503: Server temporaneamente non disponibile. Puoi riprovare usando il pulsante di ripetizione sui messaggi.";
        } else {
        _error = e.toString();
        }
        _isLoading = false;
        notifyListeners();
    }
    }

    // Metodo per gestire il ritorno all'ultimo messaggio in caso di errore 503
    Future<void> retryLastUserMessage() async {
    // Trova l'ultimo messaggio dell'utente
    ChatMessage? lastUserMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].isUser) {
        lastUserMessage = _messages[i];
        break;
        }
    }
    
    if (lastUserMessage != null) {
        // Riprova a inviare lo stesso messaggio
        await sendMessage(lastUserMessage.text);
    } else {
        _error = "Nessun messaggio da riprovare";
        notifyListeners();
    }
    }

    // Metodo per gestire le richieste HTTP e intercettare gli errori 503
    Future<String> _makeApiRequest(Uri uri, Map<String, dynamic> requestBody) async {
    try {
        final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
        );
        
        if (response.statusCode == 200) {
        return response.body;
        } else if (response.statusCode == 503) {
        throw Exception('Errore 503: Server temporaneamente non disponibile');
        } else {
        try {
            final errorMessage = jsonDecode(response.body)['error']['message'];
            throw Exception('Errore API: $errorMessage');
        } catch (e) {
            throw Exception('Errore nella risposta: ${response.statusCode}');
        }
        }
    } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('TimeoutException')) {
        throw Exception('Errore di connessione: controlla la tua connessione internet');
        }
        rethrow;
    }
    }

  
  // Prepara il contesto MCP raccogliendo le informazioni necessarie
  Future<Map<String, dynamic>> _prepareMCPContext() async {
    // Questo metodo raccoglie i dati necessari tramite MCP
    return await _mcpService.prepareContext(_userId);
  }
  
  // Genera una risposta utilizzando l'API di Gemini
  Future<String> _generateResponse(String userMessage, Map<String, dynamic> mcpContext) async {
    final systemPrompt = _getSystemPrompt(mcpContext);
    
    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": systemPrompt}
          ]
        },
        {
          "role": "model",
          "parts": [
            {"text": "Capisco. Sono pronto ad aiutare l'apicoltore rispondendo alle sue domande in base ai dati del suo apiario."}
          ]
        },
        {
          "role": "user",
          "parts": [
            {"text": userMessage}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 1024,
      }
    };
    
    final response = await http.post(
      Uri.parse('$_apiUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final botResponse = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      return botResponse;
    } else {
      // Fallback in caso di errore
      try {
        final errorMessage = jsonDecode(response.body)['error']['message'];
        throw Exception('Errore API Gemini: $errorMessage');
      } catch (e) {
        throw Exception('Errore nella generazione della risposta: ${response.statusCode}');
      }
    }
  }
  
// Modifica da implementare nel file chat_service.dart
// Metodo _getSystemPrompt migliorato per includere dati dettagliati sui telaini


String _getSystemPrompt(Map<String, dynamic> mcpContext) {
  return """
Sei un assistente virtuale specializzato in apicoltura per l'app "Apiario Manager". 
Il tuo compito è aiutare gli apicoltori a gestire il loro lavoro in modo efficiente.

Ecco i dati dell'apicoltore che sta chattando con te (usa queste informazioni per le tue risposte):

APIARI:
${_formatApiariData(mcpContext['apiari'])}

ARNIE:
${_formatArnieData(mcpContext['arnie'])}

TRATTAMENTI:
${_formatTrattamentiData(mcpContext['trattamenti'])}

CONTROLLI RECENTI:
${_formatControlliDetailedData(mcpContext['controlli'])}

LINEE GUIDA:
1. Rispondi brevemente e in modo chiaro. L'apicoltore sta probabilmente consultando l'app mentre è sul campo.
2. Fornisci consigli pratici basati sui dati degli apiari disponibili.
3. Se noti problemi (come trattamenti in scadenza o controlli mancanti), evidenziali.
4. Usa termini specifici dell'apicoltura italiana.
5. Non inventare dati non presenti nel contesto fornito.
6. Se l'apicoltore chiede dati che non hai, suggerisci dove potrebbe trovarli nell'app.

Rispondi all'apicoltore in modo utile e professionale.
""";
}

// Helper per formattare i dati degli apiari
String _formatApiariData(List<dynamic> apiari) {
  if (apiari.isEmpty) return "Nessun apiario registrato.";
  
  return apiari.map((apiario) => 
    "- ${apiario['nome']}: ${apiario['posizione'] ?? 'posizione non specificata'}, " +
    "${apiario['numero_arnie']} arnie" +
    (apiario['ultima_visita'] != null ? ", ultima visita: ${apiario['ultima_visita']}" : "")
  ).join("\n");
}

// Helper per formattare i dati delle arnie
String _formatArnieData(List<dynamic> arnie) {
  if (arnie.isEmpty) return "Nessuna arnia registrata.";
  
  return arnie.map((arnia) => 
    "- Arnia ${arnia['numero']}: " +
    "apiario ${arnia['apiario_nome']}, " +
    "stato: ${arnia['stato'] ?? 'non specificato'}"
  ).join("\n");
}

// Helper per formattare i dati dei trattamenti
String _formatTrattamentiData(List<dynamic> trattamenti) {
  if (trattamenti.isEmpty) return "Nessun trattamento registrato.";
  
  return trattamenti.map((trattamento) => 
    "- ${trattamento['tipo_trattamento_nome']}: " +
    "apiario ${trattamento['apiario_nome']}, " +
    "stato: ${trattamento['stato']}, " +
    "dal ${trattamento['data_inizio']} " +
    (trattamento['data_fine'] != null ? "al ${trattamento['data_fine']}" : "in corso")
  ).join("\n");
}

// NUOVO: Helper migliorato per formattare i dati dettagliati dei controlli
String _formatControlliDetailedData(List<dynamic> controlli) {
  if (controlli.isEmpty) return "Nessun controllo recente registrato.";
  
  return controlli.map((controllo) {
    // Prepara la descrizione dei telaini
    String telainiInfo = "";
    if (controllo['telaini_config_decoded'] != null) {
      int telainiCovata = controllo['telaini_covata'] ?? 0;
      int telainiScorte = controllo['telaini_scorte'] ?? 0;
      int telainiVuoti = controllo['telaini_vuoti'] ?? 0;
      int telainiDiaframma = controllo['telaini_diaframma'] ?? 0;
      int telainiNutritore = controllo['telaini_nutritore'] ?? 0;
      
      List<String> telainiParts = [];
      
      if (telainiCovata > 0) telainiParts.add("$telainiCovata di covata");
      if (telainiScorte > 0) telainiParts.add("$telainiScorte di scorte");
      if (telainiVuoti > 0) telainiParts.add("$telainiVuoti vuoti");
      if (telainiDiaframma > 0) telainiParts.add("$telainiDiaframma diaframmi");
      if (telainiNutritore > 0) telainiParts.add("$telainiNutritore nutritori");
      
      telainiInfo = " (telaini: " + telainiParts.join(", ") + ")";
    }
    
    // Prepara le informazioni sulla regina
    String reginaInfo = "";
    if (controllo['stato_regina'] != null) {
      var regina = controllo['stato_regina'];
      
      List<String> reginaParts = [];
      if (regina['presente'] == true) {
        reginaParts.add("regina presente");
        if (regina['vista'] == true) reginaParts.add("vista");
        if (regina['uova_fresche'] == true) reginaParts.add("uova fresche");
      } else {
        reginaParts.add("regina assente");
      }
      
      if (regina['celle_reali'] == true) {
        reginaParts.add("${regina['numero_celle_reali']} celle reali");
      }
      
      if (regina['sostituita'] == true) {
        reginaParts.add("regina sostituita");
      }
      
      if (reginaParts.isNotEmpty) {
        reginaInfo = " (" + reginaParts.join(", ") + ")";
      }
    }
    
    // Prepara le informazioni sui problemi
    String problemiInfo = "";
    if ((controllo['sciamatura'] == true) || (controllo['problemi_sanitari'] == true)) {
      List<String> problemiParts = [];
      
      if (controllo['sciamatura'] == true) {
        problemiParts.add("sciamatura rilevata");
        if (controllo['note_sciamatura'] != null && controllo['note_sciamatura'].isNotEmpty) {
          problemiParts.add("note: ${controllo['note_sciamatura']}");
        }
      }
      
      if (controllo['problemi_sanitari'] == true) {
        problemiParts.add("problemi sanitari");
        if (controllo['note_problemi'] != null && controllo['note_problemi'].isNotEmpty) {
          problemiParts.add("dettagli: ${controllo['note_problemi']}");
        }
      }
      
      if (problemiParts.isNotEmpty) {
        problemiInfo = " [ATTENZIONE: " + problemiParts.join(", ") + "]";
      }
    }
    
    return "- Controllo arnia ${controllo['arnia_numero']}: " +
           "data: ${controllo['data']}, " +
           "stato: ${controllo['stato'] ?? 'non specificato'}" +
           telainiInfo +
           reginaInfo +
           problemiInfo +
           (controllo['note'] != null && controllo['note'].isNotEmpty ? 
           "\n  Note: ${controllo['note']}" : "");
  }).join("\n\n");
}
  
  // Cancella la conversazione
  void clearConversation() {
    _messages = [
      ChatMessage(
        text: "Ciao! Sono il tuo assistente per l'apicoltura. Come posso aiutarti oggi?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    notifyListeners();
  }
  
  // Cancella messaggio di errore
  void clearError() {
    _error = null;
    notifyListeners();
  }
}