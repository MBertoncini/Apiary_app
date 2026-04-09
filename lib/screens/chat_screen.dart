// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/language_service.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../widgets/chart_widget.dart';
import '../utils/chart_exporter.dart';
import '../widgets/formatted_message_widget.dart';
import '../widgets/rich_message_widget.dart';
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;
  
  @override
  void initState() {
    super.initState();
    // Scorre automaticamente in basso quando arrivano nuovi messaggi
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    final chatService = Provider.of<ChatService>(context);

    // Auto-scroll quando nuovi messaggi arrivano
    if (chatService.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ApiarioAI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: s.chatTooltipClear,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.chatClearTitle),
                  content: Text(s.chatClearMsg),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.dialogCancelBtn),
                    ),
                    TextButton(
                      onPressed: () {
                        chatService.clearConversation();
                        Navigator.pop(context);
                      },
                      child: Text(s.chatClearBtn),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Area informativa
          Container(
            padding: const EdgeInsets.all(12),
            color: ThemeConstants.primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                  color: ThemeConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.chatInfoBanner,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista dei messaggi
          Expanded(
            child: chatService.messages.isEmpty
                ? Center(
                    child: Text(
                      s.chatEmpty,
                      style: TextStyle(color: ThemeConstants.textSecondaryColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: chatService.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageItem(context, chatService.messages[index], index);
                    },
                  ),
          ),
          
          // Indicatore di caricamento
          if (chatService.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.chatLoading,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

          // Messaggi di errore
          if (chatService.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.chatErrMsg(chatService.error!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        chatService.clearError();
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Divisore
          Divider(height: 1),
          
          // Area di composizione messaggio
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
  
  // Costruisce l'area di input del messaggio
  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Campo di input
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _s.chatHint,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
              onSubmitted: _isComposing ? _handleSubmitted : null,
            ),
          ),
          
          // Pulsante di invio
          IconButton(
            icon: Icon(Icons.send),
            color: _isComposing 
                ? ThemeConstants.primaryColor 
                : ThemeConstants.textSecondaryColor.withOpacity(0.5),
            onPressed: _isComposing
                ? () => _handleSubmitted(_textController.text)
                : null,
          ),
        ],
      ),
    );
  }
  
  // Gestisce l'invio del messaggio
  void _handleSubmitted(String text) {
    if (!_isComposing) return;
    
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendMessage(text);
  }
  
  // Funzione per ritrasmettere un messaggio in caso di errore
  void _retryMessage(String messageText) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendMessage(messageText);
    
    // Mostra un breve feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_s.chatRetrySnackbar),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  // Costruisce un singolo elemento messaggio
  Widget _buildMessageItem(BuildContext context, ChatMessage message, int index) {
    final isUser = message.isUser;
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (solo per i messaggi del bot)
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: ThemeConstants.primaryColor,
              child: Icon(
                Icons.hive,
                color: Colors.white,
                size: 16,
              ),
              radius: 16,
            ),
            SizedBox(width: 8),
          ],
          
          // Contenuto del messaggio
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Messaggio con formattazione ricca
                RichMessageWidget(
                  message: message.text,
                  timestamp: message.timestamp,
                  isUser: isUser,
                  onRetry: isUser ? () => _retryMessage(message.text) : null,
                ),
                
                // Se il messaggio contiene un grafico, mostralo
                if (message.hasChart && message.chartData != null && !chatService.isProcessingChart)
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: ChartWidget(chartData: message.chartData!),
                        ),
                      ),
                      
                      // Pulsante per esportare/condividere il grafico
                      Positioned(
                        top: 16,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ChartExporter.captureAndShareChart(
                                context,
                                ChartWidget(chartData: message.chartData!),
                                message.chartData!['title'] ?? 'Grafico',
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.share,
                                size: 20,
                                color: ThemeConstants.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                // Se stiamo ancora elaborando un grafico, mostra uno spinner
                if (message.hasChart && chatService.isProcessingChart)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            _s.chatGeneratingChart,
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Spazio dopo l'avatar dell'utente (per allineare)
          if (isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 16,
              ),
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}