import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorDisplayWidget({
    required this.errorMessage,
    required this.onRetry,
  });

  // Metodo per estrarre il messaggio utile dall'errore HTML
  String _extractUsefulMessage(String message) {
    // Se contiene codice HTML, restituisci un messaggio generico
    if (message.contains('<html>') || message.contains('<!DOCTYPE')) {
      return "Si è verificato un errore nella connessione al server.";
    }
    
    // Limita la lunghezza del messaggio per evitare overflow
    if (message.length > 200) {
      return "${message.substring(0, 200)}...";
    }
    
    return message;
  }

  @override
  Widget build(BuildContext context) {
    // Usa il messaggio di errore formattato
    final formattedMessage = _extractUsefulMessage(errorMessage);
    
    return Center(
      child: SingleChildScrollView(  // Rende tutto scrollabile
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,  // Importante: usa lo spazio minimo necessario
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: ThemeConstants.errorColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Si è verificato un errore',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                formattedMessage,
                style: TextStyle(
                  color: ThemeConstants.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('RIPROVA'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}