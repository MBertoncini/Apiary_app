// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../config/api_keys.dart';
import '../constants/gemini_constants.dart';
import 'ai_quota_service.dart';
import 'api_service.dart' show QuotaExceededException;
import 'mcp_service.dart';

// Estensione per capitalizzare la prima lettera di una stringa
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class ChatService with ChangeNotifier {
  final AiQuotaService _quotaService;
  final MCPService _mcpService;
  
  String _welcomeMessage =
      "Ciao! Sono ApiarioAI, il tuo assistente per l'apicoltura. Come posso aiutarti oggi?";

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isProcessingChart = false;
  String? _personalApiKey;

  // Cache breve del riepilogo contesto utente (apiari/arnie/trattamenti)
  // iniettato nel system prompt. Serve per evitare di ricolpire gli endpoint
  // lista ad ogni turno di chat, pur rigenerandolo periodicamente per
  // riflettere nuove arnie/apiari creati durante la sessione.
  String? _userContextCache;
  DateTime? _userContextCachedAt;
  static const Duration _userContextTtl = Duration(seconds: 60);

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isProcessingChart => _isProcessingChart;
  String? get error => _error;

  /// Mirror reattivo del gate centralizzato per la chat.
  bool get isQuotaExceeded => !_quotaService.canCall(AiFeature.chat);

  /// Dati grezzi di quota — esposti per retrocompatibilità. Le nuove UI
  /// dovrebbero consumare direttamente [AiQuotaService].
  Map<String, dynamic>? get lastQuotaData => _quotaService.rawData;
  Map<String, dynamic>? get allTierLimits => _quotaService.allTierLimits;

  ChatService(this._quotaService, this._mcpService) {
    _messages.add(
      ChatMessage(
        text: _welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    _quotaService.addListener(_onQuotaChanged);
  }

  void _onQuotaChanged() {
    // Se la quota è cambiata e non siamo più bloccati, pulisci l'errore stale.
    if (_error != null && _quotaService.canCall(AiFeature.chat)) {
      _error = null;
      notifyListeners();
    } else {
      // Propaga comunque il cambio stato (bar colorate nella ChatScreen).
      notifyListeners();
    }
  }

  /// Imposta la chiave API personale dell'utente per bypassare i limiti di tier.
  void setPersonalKey(String? key) {
    _personalApiKey = (key != null && key.isNotEmpty) ? key : null;
  }

  /// Update the welcome message with the localized version.
  /// Idempotente: nessun notifyListeners se il messaggio è invariato, per
  /// evitare loop notify→build→notify se viene chiamato dentro build().
  void setWelcomeMessage(String message) {
    if (message == _welcomeMessage) return;
    _welcomeMessage = message;
    if (_messages.isNotEmpty && !_messages[0].isUser) {
      _messages[0] = ChatMessage(
        text: message,
        isUser: false,
        timestamp: _messages[0].timestamp,
      );
      notifyListeners();
    }
  }

  /// Invia un messaggio all'AI e gestisce la risposta, inclusi i tool call.
  Future<void> sendMessage(String message, {String? preCheckErrorMsg}) async {
    if (message.trim().isEmpty) return;

    // Pre-check centralizzato: se la quota chat è esaurita non spediamo.
    // Se c'è una chiave personale, canCall(chat) dovrebbe comunque restituire true
    // se implementato correttamente nel gating.
    if (!_quotaService.canCall(AiFeature.chat)) {
      _error = preCheckErrorMsg ?? 'Quota AI giornaliera esaurita';
      notifyListeners();
      return;
    }

    _messages.add(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Prepara il prompt di sistema includendo il contesto utente
      //    (apiari/arnie reali dell'utente) così l'AI non è costretta a
      //    indovinare gli ID o restare sul generico.
      final userContext = await _buildUserContextSummary();
      final systemPrompt = _getSystemPrompt(userContext);

      // 2. Prepara la cronologia per Gemini
      List<Map<String, dynamic>> contents = [];

      for (int i = 1; i < _messages.length; i++) {
        final m = _messages[i];
        contents.add({
          'role': m.isUser ? 'user' : 'model',
          'parts': [{'text': m.text}],
        });
      }

      // 3. Loop di chiamata a Gemini con supporto Function Calling
      final botResponse = await _executeGeminiLoop(contents, systemPrompt);
      
      if (botResponse == null) {
        throw Exception('Non è stato possibile ottenere una risposta da Gemini.');
      }

      // Incremento ottimistico: la chiamata ha avuto successo.
      _quotaService.recordOptimisticCall(AiFeature.chat);
      // Notifica il backend per tenere il contatore autoritativo
      unawaited(_quotaService.recordChatCallToBackend());

      // 4. Gestione della risposta finale (testo + eventuali grafici)
      await _handleFinalResponse(botResponse);

    } on QuotaExceededException catch (e) {
      _error = e.message;
      _quotaService.markExceeded(AiFeature.chat);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getSystemPrompt(String userContext) {
    return """Sei ApiarioAI, un assistente esperto in apicoltura integrato nell'app Apiary App.
Il tuo compito è aiutare l'utente a gestire i suoi apiari, le sue arnie e a monitorare la salute delle api.

REGOLE DI RISPOSTA:
1. Sii professionale, utile e conciso.
2. Usa i tool a tua disposizione (Function Calling) per recuperare dati reali e aggiornati dell'utente quando servono dettagli specifici (controlli, telaini, regine, fioriture, trattamenti).
3. Quando l'utente si riferisce a un apiario o a un'arnia per nome o numero, RISOLVI L'ID usando il CONTESTO UTENTE qui sotto prima di chiamare un tool. Non chiedere conferma se l'ID è univocamente identificabile dal contesto.
4. Se il contesto non basta (es. informazioni storiche su un controllo specifico), chiama il tool appropriato; non inventare dati.
5. Quando fornisci dati numerici o statistiche, sii preciso e cita l'origine (es. "ultimo controllo del 10/04").
6. Se generi un grafico usando i tool `generate...Chart`, la tua risposta testuale DEVE includere il tag speciale nel formato: `[GENERA_GRAFICO:tipo:id:periodo]`.
   - tipi validi: 'popolazione', 'salute', 'trattamenti', 'produzione'.
   - id: l'ID dell'arnia (per 'popolazione') o dell'apiario (per gli altri).
   - periodo: opzionale, es. numero di mesi per popolazione o anni per produzione.
   Esempio: "Ecco l'andamento della covata per l'arnia 5. [GENERA_GRAFICO:popolazione:5:6]"

CONTESTO UTENTE CORRENTE:
$userContext

STRUMENTI DISPONIBILI:
Hai accesso a strumenti per consultare apiari, arnie, trattamenti, controlli e fioriture (getApiarioInfo, getArniaInfo, getControlliRecenti, getTrattamentiAttivi, getFioritureAttive, searchArnie, getControlloDettagliato, getRiepilogoArniaTelaini) e per generare grafici. Usali attivamente quando l'utente chiede qualcosa di specifico sui suoi dati.""";
  }

  /// Costruisce un riepilogo compatto di apiari/arnie/trattamenti dell'utente
  /// da iniettare nel system prompt. Cache breve (60s) per evitare ri-fetch
  /// ad ogni turno della stessa sessione di chat.
  Future<String> _buildUserContextSummary() async {
    final now = DateTime.now();
    final cached = _userContextCache;
    final cachedAt = _userContextCachedAt;
    if (cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _userContextTtl) {
      return cached;
    }

    try {
      final ctx = await _mcpService.prepareContext();
      final apiari = (ctx['apiari'] as List?) ?? const [];
      final arnie = (ctx['arnie'] as List?) ?? const [];
      final trattamenti = (ctx['trattamenti'] as List?) ?? const [];
      final fioriture = (ctx['fioriture'] as List?) ?? const [];

      String apiariBlock;
      if (apiari.isEmpty) {
        apiariBlock = '  (nessun apiario registrato)';
      } else {
        apiariBlock = apiari.take(15).map((a) {
          final id = a['id'];
          final nome = a['nome'] ?? a['name'] ?? 'senza nome';
          final pos = a['posizione'] ?? a['localita'] ?? '';
          return '  - apiario ID=$id "$nome"'
              '${pos is String && pos.isNotEmpty ? ' ($pos)' : ''}';
        }).join('\n');
      }

      String arnieBlock;
      if (arnie.isEmpty) {
        arnieBlock = '  (nessuna arnia registrata)';
      } else {
        arnieBlock = arnie.take(50).map((h) {
          final id = h['id'];
          final numero = h['numero'] ?? '?';
          final apiarioNome = h['apiario_nome'] ?? '';
          final stato = h['stato'] ?? '';
          return '  - arnia ID=$id n°$numero'
              '${apiarioNome is String && apiarioNome.isNotEmpty ? ' [apiario: $apiarioNome]' : ''}'
              '${stato is String && stato.isNotEmpty ? ' [stato: $stato]' : ''}';
        }).join('\n');
        if (arnie.length > 50) {
          arnieBlock += '\n  (… e altre ${arnie.length - 50} arnie)';
        }
      }

      final summary = [
        'APIARI (${apiari.length}):',
        apiariBlock,
        '',
        'ARNIE (${arnie.length}):',
        arnieBlock,
        '',
        'Trattamenti recenti/attivi: ${trattamenti.length}',
        'Fioriture segnalate attive: ${fioriture.length}',
      ].join('\n');

      _userContextCache = summary;
      _userContextCachedAt = now;
      return summary;
    } catch (e) {
      debugPrint('[ChatService] errore costruzione contesto utente: $e');
      // Restituisce un messaggio degradato ma non blocca la chat.
      return '(contesto utente non disponibile: $e)';
    }
  }

  /// Invalida la cache del contesto utente. Da chiamare quando sappiamo che
  /// i dati sono cambiati (nuovo apiario/arnia creato in sessione) e vogliamo
  /// che il prossimo prompt veda lo stato aggiornato.
  void invalidateUserContext() {
    _userContextCache = null;
    _userContextCachedAt = null;
  }

  Future<String?> _executeGeminiLoop(List<Map<String, dynamic>> contents, String systemPrompt) async {
    final tools = _mcpService.getGeminiToolDeclarations();

    // Loop limitato per evitare loop infiniti tra AI e tool
    for (int iteration = 0; iteration < 5; iteration++) {
      final response = await _callGeminiApi(contents, systemPrompt, tools);

      if (response == null) return null;

      final candidates = response['candidates'];
      final candidate = (candidates is List && candidates.isNotEmpty)
          ? candidates.first
          : null;
      if (candidate == null) return null;

      final content = candidate is Map ? candidate['content'] : null;
      final rawParts = content is Map ? content['parts'] : null;
      if (rawParts is! List || rawParts.isEmpty) {
        // Gemini può rispondere senza parts se è scattata una safety rule o
        // il modello ha restituito finishReason=SAFETY. Esci pulito senza
        // crashare il parser.
        final finishReason = candidate is Map ? candidate['finishReason'] : null;
        debugPrint('[ChatService] empty parts, finishReason=$finishReason');
        return null;
      }

      // Cerca chiamate a funzioni in modo type-safe (elementi non-Map
      // vengono ignorati invece di far crashare containsKey).
      final functionCalls = rawParts
          .where((p) => p is Map && p.containsKey('functionCall'))
          .toList();

      if (functionCalls.isEmpty) {
        // Nessuna chiamata a funzione: concatena tutti i text part in una
        // singola risposta. Gemini può spezzare la risposta in più parti e
        // prendere solo la prima causava risposte troncate.
        final buffer = StringBuffer();
        for (final p in rawParts) {
          if (p is! Map) continue;
          final t = p['text'];
          if (t is! String || t.isEmpty) continue;
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(t);
        }
        final joined = buffer.toString();
        return joined.isEmpty ? null : joined;
      }

      // Aggiungi la risposta del modello (che contiene le chiamate ai tool)
      // alla cronologia, preservando l'ordine originale delle parts.
      contents.add({
        'role': 'model',
        'parts': rawParts,
      });

      // Esegui le chiamate ai tool in parallelo: Gemini consente più
      // function call per turno e serializzarle moltiplica la latenza.
      final toolResponses = await Future.wait(functionCalls.map((call) async {
        final funcCall = (call as Map)['functionCall'];
        if (funcCall is! Map) {
          return <String, dynamic>{
            'functionResponse': {
              'name': '',
              'response': {'content': {'error': 'functionCall malformato'}},
            }
          };
        }
        final name = funcCall['name'] as String? ?? '';
        final rawArgs = funcCall['args'];
        final args = rawArgs is Map
            ? Map<String, dynamic>.from(rawArgs)
            : <String, dynamic>{};

        debugPrint('[ChatService] Executing tool: $name with args: $args');
        final result = name.isEmpty
            ? {'error': 'functionCall senza nome'}
            : await _mcpService.executeToolCall(name, args);

        return <String, dynamic>{
          'functionResponse': {
            'name': name,
            'response': {'content': result},
          }
        };
      }));

      // Aggiungi le risposte dei tool alla cronologia
      contents.add({
        'role': 'user',
        'parts': toolResponses,
      });
    }

    return "Mi dispiace, ho avuto difficoltà a elaborare la richiesta dopo troppi passaggi.";
  }

  Future<Map<String, dynamic>?> _callGeminiApi(
    List<Map<String, dynamic>> contents, 
    String systemPrompt,
    List<Map<String, dynamic>> tools,
  ) async {
    final apiKey = _personalApiKey ?? ApiKeys.geminiApiKey;
    if (apiKey == 'YOUR_GEMINI_API_KEY' || apiKey.isEmpty) {
      throw Exception('Chiave API Gemini non configurata.');
    }

    for (var modelName in kGeminiModelFallbacks) {
      try {
        final url = '$kGeminiBaseUrl/$modelName:generateContent?key=$apiKey';
        
        final body = {
          'contents': contents,
          'system_instruction': {
            'parts': [{'text': systemPrompt}]
          },
          'tools': [
            {'function_declarations': tools}
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
        };

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else if (response.statusCode == 429) {
          debugPrint('Rate limit on $modelName, trying next...');
          continue;
        } else {
          debugPrint('Error from $modelName (${response.statusCode}): ${response.body}');
          continue;
        }
      } catch (e) {
        debugPrint('Exception calling $modelName: $e');
        continue;
      }
    }
    return null;
  }

  Future<void> _handleFinalResponse(String botText) async {
    final regex = RegExp(r'\[GENERA_GRAFICO:(\w+):(\d+)(?::([^\]]+))?\]');
    final match = regex.firstMatch(botText);

    if (match == null) {
      _messages.add(ChatMessage(
        text: botText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
      notifyListeners();
      return;
    }

    final tipoGrafico = match.group(1)!;
    final id = int.parse(match.group(2)!);
    int? periodo;
    if (match.group(3) != null) {
      final raw = match.group(3)!;
      periodo = int.tryParse(raw);
      if (periodo == null && raw.toLowerCase() == 'tutto') periodo = 24;
    }

    final cleanText = botText.replaceAll(match.group(0)!, '').trim();

    String chartTool = '';
    Map<String, dynamic> params = {};
    switch (tipoGrafico) {
      case 'popolazione':
        chartTool = 'generateArniaPopulationChart';
        params = {'arniaId': id, 'months': periodo ?? 6};
        break;
      case 'salute':
        chartTool = 'generateApiarioHealthChart';
        params = {'apiarioId': id};
        break;
      case 'trattamenti':
        chartTool = 'generateTrattamentiEffectivenessChart';
        params = {'apiarioId': id};
        break;
      case 'produzione':
        chartTool = 'generateHoneyProductionChart';
        params = {'apiarioId': id, 'years': periodo ?? 3};
        break;
    }

    // Se il tipo marker non è riconosciuto, mostra comunque il testo pulito
    // invece di perdere la risposta del bot.
    if (chartTool.isEmpty) {
      _messages.add(ChatMessage(
        text: cleanText.isEmpty ? botText : cleanText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Placeholder con chartData=null mentre carichiamo davvero i dati.
    // `_loadChart` lo ritroverà per indice e lo sostituirà con il risultato
    // del tool (serie, data, chart_type, ecc.) necessario a ChartWidget.
    final placeholder = ChatMessage(
      text: cleanText.isEmpty
          ? 'Sto preparando il grafico richiesto...'
          : '$cleanText\n\nSto preparando il grafico richiesto...',
      isUser: false,
      timestamp: DateTime.now(),
      hasChart: true,
      chartType: chartTool,
      chartData: null,
    );
    _messages.add(placeholder);
    final placeholderIndex = _messages.length - 1;
    _isLoading = false;
    notifyListeners();

    await _loadChart(chartTool, params, cleanText, placeholderIndex);
  }

  Future<void> retryLastUserMessage() async {
    int idx = _messages.length - 1;
    while (idx >= 0 && !_messages[idx].isUser) idx--;
    if (idx < 0) {
      _error = 'Nessun messaggio da riprovare';
      notifyListeners();
      return;
    }
    final text = _messages[idx].text;
    _messages.removeRange(idx, _messages.length);
    _error = null;
    notifyListeners();
    await sendMessage(text);
  }

  Future<void> _loadChart(
    String chartTool,
    Map<String, dynamic> params,
    String prefixText,
    int placeholderIndex,
  ) async {
    _isProcessingChart = true;
    notifyListeners();
    try {
      final result = await _mcpService.executeToolCall(chartTool, params);

      // Verifica che l'indice del placeholder punti ancora al messaggio
      // attesto: l'utente potrebbe aver inviato altro nel frattempo.
      final valid = placeholderIndex >= 0 &&
          placeholderIndex < _messages.length &&
          !_messages[placeholderIndex].isUser &&
          _messages[placeholderIndex].hasChart &&
          _messages[placeholderIndex].chartType == chartTool;

      if (result.containsKey('error')) {
        final errMsg =
            'Errore nella generazione del grafico: ${result['error']}';
        final finalText = prefixText.isEmpty ? errMsg : '$prefixText\n\n$errMsg';
        if (valid) {
          _messages[placeholderIndex] = ChatMessage(
            text: finalText,
            isUser: false,
            timestamp: _messages[placeholderIndex].timestamp,
          );
        } else {
          _messages.add(ChatMessage(
            text: finalText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }
        return;
      }

      // Sostituisci il placeholder con un messaggio che contiene i dati
      // reali del grafico (serie, data, chart_type) usati da ChartWidget.
      final finalText = prefixText.isEmpty
          ? (result['title'] as String? ?? 'Ecco il grafico richiesto.')
          : prefixText;
      if (valid) {
        _messages[placeholderIndex] = ChatMessage(
          text: finalText,
          isUser: false,
          timestamp: _messages[placeholderIndex].timestamp,
          hasChart: true,
          chartType: chartTool,
          chartData: result,
        );
      } else {
        _messages.add(ChatMessage(
          text: finalText,
          isUser: false,
          timestamp: DateTime.now(),
          hasChart: true,
          chartType: chartTool,
          chartData: result,
        ));
      }
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Errore nella generazione del grafico: $e',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isProcessingChart = false;
      notifyListeners();
    }
  }

  void clearConversation() {
    _messages = [
      ChatMessage(
        text: _welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchQuota() async {
    await _quotaService.refresh();
    return _quotaService.rawData;
  }

  Future<Map<String, dynamic>> requestUpgrade(String requestedTier) =>
      _quotaService.requestUpgrade(requestedTier);

  Future<Map<String, dynamic>> activateCode(String code) =>
      _quotaService.activateCode(code);

  @override
  void dispose() {
    _quotaService.removeListener(_onQuotaChanged);
    super.dispose();
  }
}
