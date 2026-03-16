// lib/services/chat_service.dart
import 'dart:convert';
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

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isProcessingChart = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isProcessingChart => _isProcessingChart;
  String? get error => _error;

  ChatService(this._apiService) {
    _messages.add(
      ChatMessage(
        text: "Ciao! Sono ApiarioAI, il tuo assistente per l'apicoltura. Come posso aiutarti oggi?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Invia un messaggio al backend e riceve la risposta AI.
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _messages.add(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Costruisci la cronologia da passare al backend (esclude il welcome message iniziale)
      final history = _messages
          .where((m) => !m.isUser || m.text != message) // tutti tranne l'ultimo appena aggiunto
          .skip(1) // salta il messaggio di benvenuto
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
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryLastUserMessage() async {
    ChatMessage? last;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        last = _messages[i];
        break;
      }
    }
    if (last != null) {
      await sendMessage(last.text);
    } else {
      _error = 'Nessun messaggio da riprovare';
      notifyListeners();
    }
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
        text: "Ciao! Sono ApiarioAI, il tuo assistente per l'apicoltura. Come posso aiutarti oggi?",
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

  /// Recupera le informazioni sulla quota AI giornaliera dal backend.
  Future<Map<String, dynamic>?> fetchQuota() async {
    try {
      final data = await _apiService.get(ApiConstants.aiQuotaUrl);
      return data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
