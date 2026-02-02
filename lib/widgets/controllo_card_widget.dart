import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../utils/date_formatters.dart';

class ControlloCardWidget extends StatelessWidget {
  final Map<String, dynamic> controllo;
  final Function()? onTap;
  
  const ControlloCardWidget({
    Key? key,
    required this.controllo,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: ThemeConstants.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Controllo del ${DateFormatter.formatDate(controllo['data'])}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Arnia ${controllo['arnia_numero']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(
                    'Scorte: ${controllo['telaini_scorte']}', 
                    Icons.grid_view,
                    Colors.orange,
                  ),
                  _buildTag(
                    'Covata: ${controllo['telaini_covata']}', 
                    Icons.grid_view,
                    Colors.blue,
                  ),
                  _buildTag(
                    controllo['presenza_regina'] ? 'Regina presente' : 'Regina assente', 
                    Icons.star,
                    controllo['presenza_regina'] ? Colors.green : Colors.red,
                  ),
                  if (controllo['problemi_sanitari'])
                    _buildTag(
                      'Problemi sanitari', 
                      Icons.warning,
                      Colors.red,
                    ),
                ],
              ),
              
              if (controllo['note'] != null && controllo['note'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    controllo['note'],
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}