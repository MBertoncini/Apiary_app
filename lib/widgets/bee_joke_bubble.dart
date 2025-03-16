// widgets/bee_joke_bubble.dart
import 'package:flutter/material.dart';
import '../services/jokes_service.dart';

class BeeJokeBubble extends StatelessWidget {
  final VoidCallback onTap;
  
  const BeeJokeBubble({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.amber.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fumetto
            Center(
              child: Icon(
                Icons.chat_bubble,
                color: Colors.amber.shade600,
                size: 28,
              ),
            ),
            // Piccola ape
            Positioned(
              bottom: 5,
              right: 5,
              child: Icon(
                Icons.emoji_nature,
                color: Colors.amber.shade800,
                size: 14,
              ),
            ),
            // Puntini per indicare che c'è una freddura
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog per mostrare la freddura
class BeeJokeDialog extends StatelessWidget {
  final String joke;
  
  const BeeJokeDialog({
    Key? key,
    required this.joke,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titolo con ape
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_nature,
                  color: Colors.amber,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Freddura Apistica',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Freddura
            Text(
              joke,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            // Pulsante per chiudere
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'BUZZ!',
                style: TextStyle(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}