// lib/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'api_service.dart';
import 'mcp_service.dart';
import '../widgets/formatted_message_widget.dart';

// Estensione per capitalizzare la prima lettera di una stringa
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}

class ChatService with ChangeNotifier {
  final ApiService _apiService;
  final MCPService _mcpService;
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  
  // Variabili per la gestione dei grafici
  bool _isProcessingChart = false;
  
  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isProcessingChart => _isProcessingChart;
  String? get error => _error;
  
  // ATTENZIONE: API key hardcoded - in produzione spostare in variabile d'ambiente
  // o file .env non committato. Usare: String.fromEnvironment('GEMINI_API_KEY')
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCbUxxKCI1f5aB3kcFA6jBFgAp3ZN6FP-M',
  );
  static const String _apiUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent";
  
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
  
  // Modifica il metodo _generateResponse per rilevare e processare richieste di grafici
  Future<ChatMessage> _generateResponse(String userMessage, Map<String, dynamic> mcpContext) async {
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

      // Accesso sicuro alla risposta Gemini con null-checks
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Risposta API Gemini vuota o formato non valido');
      }
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty || parts[0]['text'] == null) {
        throw Exception('Risposta API Gemini senza testo');
      }
      var botResponse = parts[0]['text'] as String;
      
      // MODIFICA QUI: Cambiamo la regex per accettare qualsiasi carattere tranne ']' nel terzo parametro
      final regex = RegExp(r'\[GENERA_GRAFICO:(\w+):(\d+)(?::([^\]]+))?\]');
      final match = regex.firstMatch(botResponse);
      
      if (match != null) {
        final tipoGrafico = match.group(1);
        final id = int.parse(match.group(2)!);
        
        // MODIFICA QUI: Modifichiamo la gestione del periodo
        dynamic periodo = null;
        if (match.group(3) != null) {
          // Prova a convertire in intero, ma se fallisce usa null
          try {
            periodo = int.parse(match.group(3)!);
          } catch (e) {
            // Se è "tutto" o un'altra stringa, usiamo un valore di default ampio
            if (match.group(3)!.toLowerCase() == 'tutto') {
              // Possiamo usare un valore grande per indicare "tutto"
              periodo = 24; // ad esempio 24 mesi
            }
          }
        }
        
        // Rimuovi il comando dalla risposta
        botResponse = botResponse.replaceAll(match.group(0)!, '');
        
        // Determina il tipo di grafico e prepara i parametri
        String chartType;
        Map<String, dynamic> params;
        
        switch (tipoGrafico) {
          case 'popolazione':
            chartType = 'generateArniaPopulationChart';
            params = {'arniaId': id, 'months': periodo ?? 6};
            break;
          case 'salute':
            chartType = 'generateApiarioHealthChart';
            params = {'apiarioId': id};
            break;
          case 'trattamenti':
            chartType = 'generateTrattamentiEffectivenessChart';
            params = {'apiarioId': id};
            break;
          case 'produzione':
            chartType = 'generateHoneyProductionChart';
            params = {'apiarioId': id, 'years': periodo ?? 3};
            break;
          default:
            chartType = '';
            params = {};
            break;
        }
        
        // Aggiungi un messaggio che indica che verrà generato un grafico
        botResponse += '\n\nSto preparando il grafico richiesto...';
        
        return ChatMessage(
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
          hasChart: true,
          chartType: chartType,
          chartData: params,
        );
      }
      
      return ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } else {
      try {
        final errorMessage = jsonDecode(response.body)['error']['message'];
        throw Exception('Errore API: $errorMessage');
      } catch (e) {
        throw Exception('Errore nella generazione della risposta: ${response.statusCode}');
      }
    }
  }
 
  Future<void> _processChartRequest(String chartType, Map<String, dynamic> params) async {
    try {
      _isProcessingChart = true;
      notifyListeners();
      
      // Verifica se il tool esiste prima di chiamarlo
      if (!_mcpService.tools.containsKey(chartType)) {
        // Tool non trovato, genera un messaggio di errore informativo
        final errorMessage = ChatMessage(
          text: "Mi dispiace, non posso generare questo tipo di grafico. Il tool '$chartType' non è disponibile.\n\n"
              "I grafici disponibili sono:\n"
              "• Popolazione dell'arnia (telaini nel tempo)\n"
              "• Stato di salute delle arnie in un apiario\n"
              "• Efficacia dei trattamenti\n"
              "• Produzione di miele",
          isUser: false,
          timestamp: DateTime.now(),
        );
        
        _messages.add(errorMessage);
        return;
      }
      
      // Ottieni i dati del grafico
      final chartData = await _mcpService.executeToolCall(chartType, params);
      
      if (chartData.containsKey('error')) {
        String errorMsg = chartData['error'];
        String userFriendlyMessage = "Mi dispiace, non sono riuscito a generare il grafico richiesto.";
        
        // Personalizza il messaggio in base all'errore
        if (errorMsg.contains("Tool not found")) {
          userFriendlyMessage += " Il tipo di grafico non è supportato.";
        } else if (errorMsg.contains("data")) {
          userFriendlyMessage += " Non ci sono dati sufficienti per questo grafico. Potrebbero non esserci abbastanza controlli registrati per l'arnia.";
        } else {
          userFriendlyMessage += " Errore: $errorMsg";
        }
        
        throw Exception(userFriendlyMessage);
      }
      
      // NUOVA VERIFICA: Controlla se ci sono abbastanza dati per un grafico significativo
      String warningMessage = "";
      if (chartData.containsKey('data') && chartData['data'] is List) {
        final dataPoints = chartData['data'] as List;
        final resourceId = params.containsKey('arniaId') 
            ? 'arnia ${params['arniaId']}' 
            : 'apiario ${params['apiarioId']}';
        
        if (dataPoints.isEmpty) {
          warningMessage = "⚠️ Attenzione: Non ci sono dati disponibili per ${resourceId}. "
              "Assicurati che siano stati registrati dei controlli.";
        } else if (dataPoints.length == 1) {
          warningMessage = "⚠️ Attenzione: ${resourceId.capitalize()} ha solo un controllo registrato. "
              "Il grafico mostrerà un solo punto e potrebbe non essere molto informativo. "
              "Considera di aggiungere più controlli per vedere l'andamento nel tempo.";
        } else if (dataPoints.length < 3 && chartType == 'generateArniaPopulationChart') {
          warningMessage = "ℹ️ Nota: ${resourceId.capitalize()} ha solo ${dataPoints.length} controlli registrati. "
              "Il grafico mostra una tendenza limitata. Più controlli forniranno un quadro più completo.";
        }
      }
      
      // Crea un messaggio con il grafico (aggiungendo l'avviso se necessario)
      final textMessage = warningMessage.isEmpty 
          ? "Ecco il grafico che hai richiesto:"
          : "Ecco il grafico che hai richiesto:\n\n$warningMessage";
      
      final graphMessage = ChatMessage(
        text: textMessage,
        isUser: false,
        timestamp: DateTime.now(),
        hasChart: true,
        chartType: chartData['chart_type'],
        chartData: chartData,
      );
      
      _messages.add(graphMessage);
    } catch (e) {
      // Messaggio di errore migliorato
      String errorMsg = e.toString();
      // Rimuovi "Exception: " dall'inizio del messaggio se presente
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.substring("Exception: ".length);
      }
      
      _error = errorMsg;
      
      // Aggiungi un messaggio di errore con consigli
      final errorMessage = ChatMessage(
        text: "$errorMsg\n\nPuoi provare a:\n"
            "• Assicurarti che l'arnia o l'apiario richiesto esista\n"
            "• Verificare che ci siano controlli registrati\n"
            "• Specificare un periodo di tempo più breve se l'arnia è recente",
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      _messages.add(errorMessage);
    } finally {
      _isProcessingChart = false;
      notifyListeners();
    }
  }


  // Modifica il metodo _getSystemPrompt per informare il modello della possibilità di generare grafici
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

  CAPACITÀ GRAFICHE:
  Puoi generare grafici per l'utente. Quando l'utente chiede di visualizzare i dati in forma grafica, offri di creare uno dei seguenti tipi di grafici:

  1. POPOLAZIONE: Andamento della popolazione di un'arnia (telaini nel tempo).
    Esempio: "Vorrei vedere l'andamento della popolazione dell'arnia 3"

  2. SALUTE: Stato di salute comparativo delle arnie in un apiario.
    Esempio: "Mostrami un grafico dello stato di salute delle arnie nell'apiario 1"

  3. TRATTAMENTI: Efficacia dei trattamenti effettuati in un apiario.
    Esempio: "Qual è stata l'efficacia dei trattamenti nell'apiario 2?"

  4. PRODUZIONE: Produzione di miele negli anni per un apiario.
    Esempio: "Mostrami la produzione di miele dell'apiario 1 negli ultimi anni"

  Per generare uno di questi grafici, includi nella tua risposta un tag speciale con questa sintassi:
  [GENERA_GRAFICO:tipo:id:periodo]

  LINEE GUIDA:
  1. Rispondi brevemente e in modo chiaro.
  2. Formatta sempre le risposte in modo leggibile usando:
    - Intestazioni chiare (senza asterischi o simboli speciali)
    - Elenchi puntati con "•" per elementi correlati
    - Per informazioni su arnie, usa il formato "Arnia X:" (senza asterischi)
    - Usa emoji appropriate per evidenziare informazioni: 👑 per regine presenti, ⚠️ per regine assenti o problemi, 📝 per note
  3. Fornisci consigli pratici basati sui dati disponibili.
  4. Se noti problemi (come trattamenti in scadenza o controlli mancanti), evidenziali chiaramente.
  5. Non inventare dati non presenti nel contesto fornito.
  6. Quando l'utente chiede visualizzazioni o confronti di dati, proponi la generazione di un grafico appropriato.
  7. MOLTO IMPORTANTE: NON USARE asterischi (**) o simboli Markdown nella formattazione. 
    Il sistema non supporta Markdown. Usa testo normale con emoji.

  Rispondi all'apicoltore in modo utile, professionale e con una formattazione chiara e leggibile.
  """;
  }
  
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
      _messages.add(response);
      _isLoading = false;
      notifyListeners();
      
      // Se la risposta richiede un grafico, avvia la generazione
      if (response.hasChart) {
        await _processChartRequest(response.chartType!, response.chartData!);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper per formattare i dati degli apiari (versione migliorata senza Markdown)
  String _formatApiariData(List<dynamic> apiari) {
    if (apiari.isEmpty) return "Nessun apiario registrato.";
    
    List<String> results = ["Apiari"];
    
    for (var apiario in apiari) {
      // RIMOSSI asterischi (**)
      results.add("• ${apiario['nome']}: ${apiario['posizione'] ?? 'posizione non specificata'}, " +
        "${apiario['numero_arnie']} arnie" +
        (apiario['ultima_visita'] != null ? ", ultima visita: ${apiario['ultima_visita']}" : ""));
    }
    
    return results.join("\n");
  }

  // Helper per formattare i dati delle arnie
  String _formatArnieData(List<dynamic> arnie) {
    if (arnie.isEmpty) return "Nessuna arnia registrata.";
    
    List<String> results = ["Arnie"];
    
    for (var arnia in arnie) {
      // RIMOSSI asterischi (**)
      results.add("• Arnia ${arnia['numero']}: " +
        "apiario ${arnia['apiario_nome']}, " +
        "stato: ${arnia['stato'] ?? 'non specificato'}");
    }
    
    return results.join("\n");
  }

  // Helper per formattare i dati dei trattamenti
  String _formatTrattamentiData(List<dynamic> trattamenti) {
    if (trattamenti.isEmpty) return "Nessun trattamento registrato.";
    
    List<String> results = ["Trattamenti"];
    
    for (var trattamento in trattamenti) {
      String stato = trattamento['stato'];
      String statoFormattato = stato;
      
      // Aggiungi emoji in base allo stato
      if (stato == 'in_corso') {
        statoFormattato = "⏳ in corso";
      } else if (stato == 'completato') {
        statoFormattato = "✅ completato";
      } else if (stato == 'programmato') {
        statoFormattato = "🔜 programmato";
      }
      
      // RIMOSSI asterischi (**)
      results.add("• ${trattamento['tipo_trattamento_nome']}: " +
        "apiario ${trattamento['apiario_nome']}, " +
        "stato: $statoFormattato, " +
        "dal ${trattamento['data_inizio']} " +
        (trattamento['data_fine'] != null ? "al ${trattamento['data_fine']}" : "in corso"));
    }
    
    return results.join("\n");
  }

  // Helper migliorato per formattare i dati dettagliati dei controlli
  String _formatControlliDetailedData(List<dynamic> controlli) {
    if (controlli.isEmpty) return "Nessun controllo recente registrato.";
    
    List<String> results = ["Controlli Recenti"];
    
    for (var controllo in controlli) {
      // Prepara la descrizione dei telaini
      String telainiInfo = "";
      if (controllo['telaini_config_decoded'] != null) {
        int telainiCovata = controllo['telaini_covata'] ?? 0;
        int telainiScorte = controllo['telaini_scorte'] ?? 0;
        int telainiVuoti = controllo['telaini_vuoti'] ?? 0;
        
        telainiInfo = "(telaini: $telainiCovata di covata, $telainiScorte di scorte, $telainiVuoti vuoti)";
      }
      
      // Prepara le informazioni sulla regina
      String reginaInfo = "";
      if (controllo['stato_regina'] != null) {
        var regina = controllo['stato_regina'];
        
        if (regina['presente'] == true) {
          reginaInfo = "👑 regina presente";
        } else {
          reginaInfo = "⚠️ regina assente";
        }
      }
      
      // IMPORTANTE: Qui è il problema - rimossi gli asterischi **
      // Vecchio formato: "* **Arnia ${controllo['arnia_numero']}:** ..."
      // Nuovo formato senza asterischi:
      results.add("• Arnia ${controllo['arnia_numero']}: ${controllo['data']} $telainiInfo $reginaInfo");
    }
    
    // Note e suggerimenti
    results.add("\n📝 Note:");
    
    // Verifica se ci sono arnie con regina assente
    List<int> arnieReginaAssente = [];
    for (var controllo in controlli) {
      if (controllo['stato_regina'] != null && 
          controllo['stato_regina']['presente'] == false &&
          !arnieReginaAssente.contains(controllo['arnia_numero'])) {
        arnieReginaAssente.add(controllo['arnia_numero']);
      }
    }
    
    if (arnieReginaAssente.isNotEmpty) {
      results.add("• L'Arnia ${arnieReginaAssente.join(', ')} risulta orfana. Considera di intervenire (introduzione di una nuova regina o un favo con larva giovane).");
    }
    
    // Identifica arnie con popolazione stabile
    List<int> arniePopolazioneStabile = [];
    for (var controllo in controlli) {
      if (!arnieReginaAssente.contains(controllo['arnia_numero']) &&
          !arniePopolazioneStabile.contains(controllo['arnia_numero'])) {
        arniePopolazioneStabile.add(controllo['arnia_numero']);
      }
    }
    
    if (arniePopolazioneStabile.isNotEmpty) {
      results.add("• Le arnie ${arniePopolazioneStabile.join(', ')} sembrano avere una popolazione stabile.");
    }
    
    return results.join("\n");
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