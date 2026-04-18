// lib/services/chat_service.dart
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../constants/api_constants.dart';
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
  String _welcomeMessage = "Ciao! Sono ApiarioAI, il tuo assistente per l'apicoltura. Come posso aiutarti oggi?";

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isProcessingChart = false;
  bool _isQuotaExceeded = false;

  /// Cached quota data from last fetchQuota() call.
  Map<String, dynamic>? _lastQuotaData;

  /// When the current quota exceeded flag was set.
  DateTime? _quotaExceededAt;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isProcessingChart => _isProcessingChart;
  String? get error => _error;
  Map<String, dynamic>? get lastQuotaData => _lastQuotaData;

  /// Limiti per tutti i tier, dal backend. Null se non ancora caricati.
  Map<String, dynamic>? get allTierLimits =>
      _lastQuotaData?['all_tier_limits'] as Map<String, dynamic>?;

  bool get isQuotaExceeded {
    if (!_isQuotaExceeded) return false;
    // Auto-reset usando il reset_at del server (mezzanotte UTC) se disponibile,
    // altrimenti fallback a confronto data locale.
    final serverResetAt = (_lastQuotaData?['personal'] as Map?)?['reset_at'] as String?;
    if (serverResetAt != null) {
      final normalized = serverResetAt.endsWith('Z') || serverResetAt.contains('+')
          ? serverResetAt
          : '${serverResetAt}Z';
      final resetTime = DateTime.tryParse(normalized);
      if (resetTime != null && DateTime.now().toUtc().isAfter(resetTime)) {
        _isQuotaExceeded = false;
        _quotaExceededAt = null;
        _error = null;
        return false;
      }
    } else if (_quotaExceededAt != null) {
      // Fallback: nessun dato server — confronta mezzanotte UTC
      final now = DateTime.now().toUtc();
      final setDate = _quotaExceededAt!.toUtc();
      if (now.year != setDate.year ||
          now.month != setDate.month ||
          now.day != setDate.day) {
        _isQuotaExceeded = false;
        _quotaExceededAt = null;
        _error = null;
        return false;
      }
    }
    return true;
  }

  ChatService(this._apiService) {
    _messages.add(
      ChatMessage(
        text: _welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Update the welcome message with the localized version.
  void setWelcomeMessage(String message) {
    _welcomeMessage = message;
    // Update the first message if it's the welcome
    if (_messages.isNotEmpty && !_messages[0].isUser) {
      _messages[0] = ChatMessage(
        text: message,
        isUser: false,
        timestamp: _messages[0].timestamp,
      );
      notifyListeners();
    }
  }

  /// Returns true if quota is likely exceeded based on cached data.
  bool _isQuotaLikelyExceeded() {
    final data = _lastQuotaData;
    if (data == null) return false;
    final usage = data['usage'] as Map?;
    final tierLimits = data['tier_limits'] as Map?;
    if (usage == null || tierLimits == null) return false;
    final int totalUsed = ((usage['total_today'] ?? 0) as num).toInt();
    final int totalLimit = ((tierLimits['total'] ?? 0) as num).toInt();
    return totalLimit > 0 && totalUsed >= totalLimit;
  }

  /// Invia un messaggio al backend e riceve la risposta AI.
  Future<void> sendMessage(String message, {String? preCheckErrorMsg}) async {
    if (message.trim().isEmpty) return;

    // Pre-check: if quota is likely exhausted, don't waste the request.
    if (_isQuotaLikelyExceeded() || isQuotaExceeded) {
      _error = preCheckErrorMsg ?? 'Quota AI giornaliera esaurita';
      _isQuotaExceeded = true;
      _quotaExceededAt ??= DateTime.now();
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
      _isQuotaExceeded = true;
      _quotaExceededAt = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryLastUserMessage() async {
    // Trova l'ultimo messaggio utente e rimuovi esso + eventuali risposte bot successive,
    // così sendMessage non lo duplica nella lista.
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
      // Chiama il backend per i dati del grafico tramite MCPService se disponibile
      // Per ora aggiungiamo un placeholder — la logica chart data rimane invariata
      // perché MCPService non è più iniettato qui. Il ChatScreen gestisce i grafici
      // attraverso il chartData già passato nel messaggio.
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
    _isQuotaExceeded = false;
    _quotaExceededAt = null;
    notifyListeners();
  }

  /// Recupera le informazioni sulla quota AI giornaliera dal backend.
  /// Caches the result for pre-check quota validation.
  Future<Map<String, dynamic>?> fetchQuota() async {
    try {
      final data = await _apiService.get(ApiConstants.aiQuotaUrl);
      _lastQuotaData = data as Map<String, dynamic>;

      // If we had quota exceeded but backend says we have room now, auto-clear.
      if (_isQuotaExceeded) {
        final usage = _lastQuotaData?['usage'] as Map?;
        final tierLimits = _lastQuotaData?['tier_limits'] as Map?;
        if (usage != null && tierLimits != null) {
          final int totalUsed = ((usage['total_today'] ?? 0) as num).toInt();
          final int totalLimit = ((tierLimits['total'] ?? 0) as num).toInt();
          if (totalLimit > 0 && totalUsed < totalLimit) {
            _isQuotaExceeded = false;
            _quotaExceededAt = null;
            _error = null;
            notifyListeners();
          }
        }
      }

      return _lastQuotaData;
    } catch (_) {
      return null;
    }
  }

  /// Invia una richiesta di upgrade tier AI al backend.
  Future<Map<String, dynamic>> requestUpgrade(String requestedTier) async {
    final data = await _apiService.post(
      ApiConstants.aiRequestUpgradeUrl,
      {'requested_tier': requestedTier},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Attiva un codice tester/promo per sbloccare un tier superiore.
  /// Il backend valida il codice e aggiorna il tier dell'utente.
  Future<Map<String, dynamic>> activateCode(String code) async {
    final data = await _apiService.post(
      ApiConstants.aiActivateCodeUrl,
      {'code': code.trim()},
    );
    return Map<String, dynamic>.from(data as Map);
  }
}
