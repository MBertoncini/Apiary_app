// lib/services/chat_service.dart
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../constants/api_constants.dart';
import 'ai_quota_service.dart';
import 'api_service.dart';

// Estensione per capitalizzare la prima lettera di una stringa
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class ChatService with ChangeNotifier {
  final ApiService _apiService;
  final AiQuotaService _quotaService;
  String _welcomeMessage =
      "Ciao! Sono ApiarioAI, il tuo assistente per l'apicoltura. Come posso aiutarti oggi?";

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isProcessingChart = false;

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

  ChatService(this._apiService, this._quotaService) {
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

  /// Update the welcome message with the localized version.
  void setWelcomeMessage(String message) {
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

  /// Invia un messaggio al backend e riceve la risposta AI.
  Future<void> sendMessage(String message, {String? preCheckErrorMsg}) async {
    if (message.trim().isEmpty) return;

    // Pre-check centralizzato: se la quota chat è esaurita non spediamo.
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
      // Costruisci la cronologia da passare al backend.
      // sublist(1, len-1): salta welcome iniziale e l'ultimo messaggio appena aggiunto.
      final history = _messages
          .sublist(1, _messages.length - 1)
          .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
          .toList();

      final responseData = await _apiService.post(
        ApiConstants.aiChatUrl,
        {'message': message, 'history': history},
      );

      // Incremento ottimistico: il backend ha accettato la chiamata.
      _quotaService.recordOptimisticCall(AiFeature.chat);

      final botText = responseData['response'] as String? ?? '';

      // Rileva tag grafici [GENERA_GRAFICO:tipo:id:periodo]
      final regex = RegExp(r'\[GENERA_GRAFICO:(\w+):(\d+)(?::([^\]]+))?\]');
      final match = regex.firstMatch(botText);

      if (match != null) {
        final tipoGrafico = match.group(1)!;
        final id = int.parse(match.group(2)!);
        dynamic periodo;
        if (match.group(3) != null) {
          try {
            periodo = int.parse(match.group(3)!);
          } catch (_) {
            if (match.group(3)!.toLowerCase() == 'tutto') periodo = 24;
          }
        }

        final cleanText = botText.replaceAll(match.group(0)!, '').trim();
        String chartType = '';
        Map<String, dynamic> params = {};
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
        }

        _messages.add(ChatMessage(
          text: '$cleanText\n\nSto preparando il grafico richiesto...',
          isUser: false,
          timestamp: DateTime.now(),
          hasChart: chartType.isNotEmpty,
          chartType: chartType.isNotEmpty ? chartType : null,
          chartData: chartType.isNotEmpty ? params : null,
        ));
        _isLoading = false;
        notifyListeners();

        if (chartType.isNotEmpty) {
          await _loadChart(chartType, params);
        }
      } else {
        _messages.add(ChatMessage(
          text: botText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
        notifyListeners();
      }
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

  Future<void> _loadChart(String chartType, Map<String, dynamic> params) async {
    _isProcessingChart = true;
    notifyListeners();
    try {
      // La logica chart data è gestita dal ChatScreen via chartData del messaggio.
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

  /// Recupera le informazioni sulla quota AI dal backend.
  /// Delega ad [AiQuotaService.refresh]; mantenuto per retrocompatibilità.
  Future<Map<String, dynamic>?> fetchQuota() async {
    await _quotaService.refresh();
    return _quotaService.rawData;
  }

  /// Invia una richiesta di upgrade tier AI al backend.
  Future<Map<String, dynamic>> requestUpgrade(String requestedTier) =>
      _quotaService.requestUpgrade(requestedTier);

  /// Attiva un codice tester/promo per sbloccare un tier superiore.
  Future<Map<String, dynamic>> activateCode(String code) =>
      _quotaService.activateCode(code);

  @override
  void dispose() {
    _quotaService.removeListener(_onQuotaChanged);
    super.dispose();
  }
}
