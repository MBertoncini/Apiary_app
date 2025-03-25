// lib/widgets/retry_button_widget.dart
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class RetryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isUserMessage;
  
  const RetryButton({
    Key? key,
    required this.onPressed,
    required this.isUserMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 12,
                color: isUserMessage 
                    ? Colors.white.withOpacity(0.75)
                    : ThemeConstants.textSecondaryColor,
              ),
              SizedBox(width: 2),
              Text(
                'Riprova',
                style: TextStyle(
                  fontSize: 10,
                  color: isUserMessage 
                      ? Colors.white.withOpacity(0.75)
                      : ThemeConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget per il messaggio di errore 503
class ErrorMessage503Widget extends StatelessWidget {
  final VoidCallback onRetry;
  
  const ErrorMessage503Widget({
    Key? key,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text(
                'Errore 503',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Si è verificato un errore temporaneo del server. Puoi riprovare a inviare il messaggio usando il pulsante "Riprova" qui sotto o nella bolla del messaggio.',
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text('Riprova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}