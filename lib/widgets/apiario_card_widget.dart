import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../utils/date_formatters.dart';

class ApiarioCardWidget extends StatelessWidget {
  final Map<String, dynamic> apiario;
  final Function() onTap;
  
  const ApiarioCardWidget({
    Key? key,
    required this.apiario,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    bool hasCoordinates = apiario['latitudine'] != null && apiario['longitudine'] != null;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      apiario['nome'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      apiario['posizione'] ?? 'Posizione non specificata',
                      style: TextStyle(
                        color: ThemeConstants.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  if (hasCoordinates)
                    _buildTag(
                      'Mappa',
                      Icons.map,
                      ThemeConstants.secondaryColor,
                    ),
                  if (apiario['monitoraggio_meteo'] == true)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildTag(
                        'Meteo',
                        Icons.wb_sunny,
                        Colors.orange,
                      ),
                    ),
                  if (apiario['condiviso_con_gruppo'] == true)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildTag(
                        'Condiviso',
                        Icons.group,
                        Colors.purple,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
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
