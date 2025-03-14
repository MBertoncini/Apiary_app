import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class SyncStatusWidget extends StatelessWidget {
  final DateTime lastSync;
  
  const SyncStatusWidget({
    Key? key,
    required this.lastSync,
  }) : super(key: key);
  
  String _getFormattedTimestamp() {
    return "${lastSync.day.toString().padLeft(2, '0')}/${lastSync.month.toString().padLeft(2, '0')} ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}";
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync,
            size: 12,
            color: ThemeConstants.textSecondaryColor,
          ),
          SizedBox(width: 4),
          Text(
            'Sincr. ${_getFormattedTimestamp()}',
            style: TextStyle(
              fontSize: 11,
              color: ThemeConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}