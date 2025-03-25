// lib/widgets/rich_message_widget.dart
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import 'package:intl/intl.dart';

class RichMessageWidget extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final bool isUser;
  final VoidCallback? onRetry;

  const RichMessageWidget({
    Key? key,
    required this.message,
    required this.timestamp,
    required this.isUser,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          _buildFormattedContent(),
          
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

  // Costruisce il contenuto formattato usando RichText
  Widget _buildFormattedContent() {
    // Dividi il messaggio in righe
    final lines = message.split('\n');
    List<Widget> contentWidgets = [];
    
    // Buffer per righe normali
    List<String> textBuffer = [];
    
    // Flag per tracciare se siamo in una sezione di titolo, elenco, ecc.
    bool isProcessingList = false;
    List<Widget> listItemWidgets = [];
    
    // Funzione per gestire il flush del buffer di testo
    void flushTextBuffer() {
      if (textBuffer.isNotEmpty) {
        contentWidgets.add(
          Text(
            textBuffer.join('\n'),
            style: TextStyle(
              color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
            ),
          ),
        );
        textBuffer = [];
      }
    }
    
    // Funzione per gestire il flush degli elementi di lista
    void flushListItems() {
      if (listItemWidgets.isNotEmpty) {
        contentWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItemWidgets,
          ),
        );
        listItemWidgets = [];
        isProcessingList = false;
      }
    }
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Salta le righe vuote
      if (line.isEmpty) continue;
      
      // Controllo per titoli (con ** o senza)
      if (line.startsWith('**') && line.endsWith(':**')) {
        // Titolo in stile Markdown, rimuoviamo i marcatori
        flushTextBuffer();
        flushListItems();
        
        final titleText = line.substring(2, line.length - 3);
        contentWidgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              titleText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isUser ? Colors.white : ThemeConstants.primaryColor,
              ),
            ),
          ),
        );
      }
      // Controllo per elementi di lista (che iniziano con asterisco o punto)
      else if (line.startsWith('* ') || line.startsWith('• ')) {
        flushTextBuffer();
        isProcessingList = true;
        
        // Estrai il testo dell'elemento (rimuovendo il marcatore)
        final itemText = line.substring(line.startsWith('* ') ? 2 : 2);
        
        // Gestione speciale per arnie
        if (itemText.contains('Arnia') && !itemText.contains(':')) {
          // Caso speciale per arnie numerate senza dati aggiuntivi
          listItemWidgets.add(
            _buildListItemWithBullet(
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                  ),
                  children: [
                    TextSpan(
                      text: itemText,
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // Gestione speciale per arnie con dati
        else if (itemText.contains('Arnia') && itemText.contains(':')) {
          // Caso normale: elemento con arnia e dati
          final parts = itemText.split(':');
          if (parts.length >= 2) {
            final arniaPart = parts[0].trim();
            final dataPart = parts.sublist(1).join(':').trim();
            
            listItemWidgets.add(
              _buildListItemWithBullet(
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                    ),
                    children: [
                      TextSpan(
                        text: arniaPart + ': ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUser ? Colors.white : ThemeConstants.primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: dataPart,
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // Fallback se non è possibile dividere correttamente
            listItemWidgets.add(_buildListItemWithBullet(Text(
              itemText,
              style: TextStyle(
                color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
              ),
            )));
          }
        }
        // Controlli con informazioni sulla regina e stato
        else if (itemText.contains('(telaini:')) {
          // Identifica la data, i telaini e lo stato della regina
          String dataText = "";
          String telainiText = "";
          String reginaText = "";
          
          // Estrai la data se presente
          final dateMatch = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(itemText);
          if (dateMatch != null) {
            dataText = dateMatch.group(0)!;
          }
          
          // Estrai info telaini
          final telainiMatch = RegExp(r'\(telaini:[^)]*\)').firstMatch(itemText);
          if (telainiMatch != null) {
            telainiText = telainiMatch.group(0)!;
          }
          
          // Estrai info regina
          if (itemText.contains('regina presente')) {
            reginaText = '👑 regina presente';
          } else if (itemText.contains('regina assente')) {
            reginaText = '⚠️ regina assente';
          }
          
          // Costruisci l'elemento di lista con parti colorate
          listItemWidgets.add(
            _buildListItemWithBullet(
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                  ),
                  children: [
                    TextSpan(text: dataText + ' '),
                    TextSpan(text: telainiText + ' '),
                    TextSpan(
                      text: reginaText,
                      style: TextStyle(
                        color: reginaText.contains('assente') ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // Note e altri elementi di lista regolari
        else if (itemText.startsWith('L\'Arnia') || itemText.startsWith('Le arnie')) {
          // Note e suggerimenti
          listItemWidgets.add(
            _buildListItemWithBullet(
              Text(
                itemText,
                style: TextStyle(
                  color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }
        else {
          // Elemento di lista generico
          listItemWidgets.add(_buildListItemWithBullet(Text(
            itemText,
            style: TextStyle(
              color: isUser ? Colors.white : ThemeConstants.textPrimaryColor,
            ),
          )));
        }
      }
      // Testo normale senza formattazione speciale
      else {
        // Se siamo in una lista, aggiungiamo spazio
        if (isProcessingList) {
          flushListItems();
        }
        
        // Gestione speciale per note
        if (line.startsWith('**📝 Note:**')) {
          flushTextBuffer();
          
          contentWidgets.add(
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '📝 Note:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isUser ? Colors.white : ThemeConstants.primaryColor,
                ),
              ),
            ),
          );
        } 
        // Testo normale
        else {
          textBuffer.add(line);
        }
      }
    }
    
    // Flush di eventuali buffer rimasti
    flushTextBuffer();
    flushListItems();
    
    // Restituisci un Column con tutti i widget
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }
  
  // Helper per costruire elementi di lista con bullet point
  Widget _buildListItemWithBullet(Widget content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4.0),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isUser ? Colors.white : ThemeConstants.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}