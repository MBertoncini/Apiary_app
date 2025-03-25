// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  
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
    final chatService = Provider.of<ChatService>(context);
    
    // Auto-scroll quando nuovi messaggi arrivano
    if (chatService.messages.isNotEmpty) {
      _scrollToBottom();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('ApiarioAI Assistant'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: 'Cancella conversazione',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Cancellare la conversazione?'),
                  content: Text('Questa azione cancellerà tutti i messaggi e non può essere annullata.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('ANNULLA'),
                    ),
                    TextButton(
                      onPressed: () {
                        chatService.clearConversation();
                        Navigator.pop(context);
                      },
                      child: Text('CANCELLA'),
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
            padding: EdgeInsets.all(12),
            color: ThemeConstants.primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, 
                  color: ThemeConstants.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ApiarioAI ha accesso ai dati dei tuoi apiari per fornirti risposte personalizzate.',
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
                      'Nessun messaggio. Inizia una conversazione!',
                      style: TextStyle(color: ThemeConstants.textSecondaryColor),
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
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ApiarioAI sta elaborando...',
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
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Errore: ${chatService.error}',
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
                hintText: 'Scrivi un messaggio...',
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
        content: Text('Riprovando a inviare il messaggio...'),
        duration: Duration(seconds: 1),
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
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isUser 
                    ? ThemeConstants.primaryColor 
                    : ThemeConstants.backgroundColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Testo del messaggio
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                    ),
                  ),
                  
                  // Riga con timestamp e pulsante di ripetizione (solo per messaggi utente)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timestamp
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser 
                              ? Colors.white.withOpacity(0.7) 
                              : ThemeConstants.textSecondaryColor,
                        ),
                      ),
                      
                      // Pulsante di ripetizione (solo per messaggi utente)
                      if (isUser) ...[
                        SizedBox(width: 4),
                        InkWell(
                          onTap: () => _retryMessage(message.text),
                          child: Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.refresh,
                              size: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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