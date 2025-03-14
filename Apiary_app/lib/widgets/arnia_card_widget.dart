import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../utils/date_formatter.dart';

class ArniaCardWidget extends StatelessWidget {
  final Map<String, dynamic> arnia;
  final Function() onTap;
  final Function()? onControlloTap;
  
  const ArniaCardWidget({
    Key? key,
    required this.arnia,
    required this.onTap,
    this.onControlloTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colorHex = arnia['colore_hex'] ?? '#FFFFFF';
    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              color: color,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Arnia ${arnia['numero']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!arnia['attiva'])
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Inattiva',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    DateFormatter.formatDate(arnia['data_installazione']),
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: onTap,
                        child: Text('Dettagli'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(80, 36),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      if (onControlloTap != null)
                        ElevatedButton(
                          onPressed: onControlloTap,
                          child: Text('Controllo'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(80, 36),
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: ThemeConstants.secondaryColor,
                          ),
                        ),
                    ],
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