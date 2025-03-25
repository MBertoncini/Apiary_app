// lib/widgets/formatted_message_widget.dart
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import 'package:intl/intl.dart';

class FormattedMessageWidget extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final bool isUser;
  final VoidCallback? onRetry;

  const FormattedMessageWidget({
    Key? key,
    required this.message,
    required this.timestamp,
    required this.isUser,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parsa il messaggio per individuare le diverse parti
    final formattedParts = _parseMessageParts(message);

    return Container(
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
          // Contenuto formattato del messaggio
          ...formattedParts,
          
          // Timestamp e pulsante retry
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isUser 
                      ? Colors.white.withOpacity(0.7) 
                      : ThemeConstants.textSecondaryColor,
                ),
              ),
              
              // Pulsante di ripetizione solo per messaggi utente
              if (isUser && onRetry != null) ...[
                SizedBox(width: 4),
                InkWell(
                  onTap: onRetry,
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
    );
  }

  // Parsing del messaggio e generazione di widget formattati
  List<Widget> _parseMessageParts(String text) {
    List<Widget> widgets = [];
    
    // Dividi il testo in righe
    final lines = text.split('\n');
    
    // Buffer per accumulare parti di testo normale
    String textBuffer = '';
    bool inList = false;
    List<Widget> listItems = [];
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Controlla se è un'intestazione
      if (line.startsWith('**') && line.contains(':**')) {
        // Aggiungi il buffer di testo precedente se presente
        if (textBuffer.isNotEmpty) {
          widgets.add(Text(
            textBuffer,
            style: TextStyle(
              color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
            ),
          ));
          textBuffer = '';
        }
        
        // Termina qualsiasi lista in corso
        if (inList) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: listItems,
              ),
            )
          );
          listItems = [];
          inList = false;
        }
        
        // Estrai il titolo tra asterischi
        final headerRegex = RegExp(r'\*\*(.*?)\*\*:');
        final match = headerRegex.firstMatch(line);
        
        if (match != null) {
          final headerText = match.group(1)!;
          final remainingText = line.substring(match.end).trim();
          
          widgets.add(Padding(
            padding: EdgeInsets.only(top: i > 0 ? 12.0 : 0.0, bottom: 4.0),
            child: Text(
              headerText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isUser ? Colors.white : ThemeConstants.primaryColor,
              ),
            ),
          ));
          
          if (remainingText.isNotEmpty) {
            widgets.add(Text(
              remainingText,
              style: TextStyle(
                color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
              ),
            ));
          }
        } else {
          textBuffer += line + '\n';
        }
      }
      // Controlla se è un elemento di lista
      else if (line.startsWith('* ') || line.startsWith('- ') || 
              RegExp(r'^\d+\.\s').hasMatch(line)) {
        // Se non siamo già in modalità lista, prepara una nuova lista
        if (!inList) {
          // Aggiungi il buffer di testo precedente se presente
          if (textBuffer.isNotEmpty) {
            widgets.add(Text(
              textBuffer,
              style: TextStyle(
                color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
              ),
            ));
            textBuffer = '';
          }
          inList = true;
          listItems = [];
        }
        
        // Rimuovi il marcatore di lista e aggiungi l'elemento
        String itemText;
        if (line.startsWith('* ') || line.startsWith('- ')) {
          itemText = line.substring(2);
        } else {
          // Per liste numerate, trova la posizione dopo il numero e il punto
          final match = RegExp(r'^\d+\.\s').firstMatch(line);
          itemText = line.substring(match!.end);
        }
        
        // Parsing più sofisticato per elementi dell'elenco di arnie
        if (itemText.contains('**Arnia')) {
          final arniaMatch = RegExp(r'\*\*Arnia (\d+):\*\*').firstMatch(itemText);
          if (arniaMatch != null) {
            final arniaNum = arniaMatch.group(1);
            final details = itemText.substring(arniaMatch.end).trim();
            
            // Crea un elemento dell'elenco più strutturato per le arnie
            listItems.add(
              Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bullet o numero
                    Container(
                      width: 20,
                      alignment: Alignment.center,
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: isUser ? Colors.white : ThemeConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    // Contenuto dell'elemento
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Numero dell'arnia in grassetto
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Arnia $arniaNum: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isUser ? Colors.white : ThemeConstants.primaryColor,
                                  ),
                                ),
                                TextSpan(
                                  text: details,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Fallback per il formato standard
            _addStandardListItem(listItems, itemText);
          }
        } else {
          // Formato standard per gli altri elementi della lista
          _addStandardListItem(listItems, itemText);
        }
      }
      // Se è un'opzione numerata per i tipi di grafico
      else if (RegExp(r'^\d+\.\s\*\*[A-Z]+\*\*').hasMatch(line)) {
        // Aggiungi il buffer di testo precedente se presente
        if (textBuffer.isNotEmpty) {
          widgets.add(Text(
            textBuffer,
            style: TextStyle(
              color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
            ),
          ));
          textBuffer = '';
        }
        
        // Termina qualsiasi lista in corso
        if (inList) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: listItems,
              ),
            )
          );
          listItems = [];
          inList = false;
        }
        
        // Estrai il numero e il tipo di grafico
        final match = RegExp(r'^(\d+)\.\s\*\*([A-Z]+)\*\*:(.*)').firstMatch(line);
        
        if (match != null) {
          final number = match.group(1)!;
          final optionTitle = match.group(2)!;
          final description = match.group(3)!.trim();
          
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numero dell'opzione
                  Container(
                    width: 20,
                    child: Text(
                      "$number.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : ThemeConstants.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  // Opzione e descrizione
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: optionTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUser ? Colors.white : ThemeConstants.primaryColor,
                            ),
                          ),
                          TextSpan(
                            text: ": $description",
                            style: TextStyle(
                              color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Se il pattern non corrisponde esattamente, aggiungi come testo normale
          textBuffer += line + '\n';
        }
      }
      // Testo normale
      else {
        textBuffer += line + '\n';
      }
    }
    
    // Aggiungi qualsiasi testo rimanente nel buffer
    if (textBuffer.isNotEmpty) {
      widgets.add(Text(
        textBuffer.trimRight(),
        style: TextStyle(
          color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
        ),
      ));
    }
    
    // Aggiungi qualsiasi elemento di lista rimanente
    if (inList && listItems.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItems,
          ),
        )
      );
    }
    
    return widgets;
  }
  
  // Helper per aggiungere elementi di lista standard
  void _addStandardListItem(List<Widget> listItems, String itemText) {
    listItems.add(
      Padding(
        padding: EdgeInsets.only(bottom: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              alignment: Alignment.center,
              child: Text(
                '•',
                style: TextStyle(
                  color: isUser ? Colors.white : ThemeConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                itemText,
                style: TextStyle(
                  color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}