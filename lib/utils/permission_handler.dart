// lib/utils/permission_handler.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Solicita permisos de micrófono y muestra un diálogo si es necesario
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    // Verificar estado actual del permiso
    PermissionStatus status = await Permission.microphone.status;
    
    // Si ya está concedido, retornar true
    if (status.isGranted) {
      return true;
    }
    
    // Si está permanentemente denegado, mostrar un diálogo explicativo
    if (status.isPermanentlyDenied) {
      return await _showPermissionDialog(
        context, 
        'Permesso del microfono necessario',
        'Il permesso del microfono è necessario per la funzione dei comandi vocali. '
        'Per favore, abilita il permesso nella configurazione dell\'app.'
      );
    }
    
    // Solicitar permiso
    status = await Permission.microphone.request();
    
    // Si no se concede, mostrar diálogo explicativo
    if (!status.isGranted) {
      return await _showPermissionDialog(
        context, 
        'Permiso denegado',
        'El permiso de micrófono es necesario para la función de comandos de voz. '
        'La app no podrá reconocer tu voz sin este permiso.'
      );
    }
    
    return status.isGranted;
  }
  
  /// Muestra un diálogo explicando por qué se necesita el permiso
  static Future<bool> _showPermissionDialog(
    BuildContext context, 
    String title, 
    String message
  ) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCELLA'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              openAppSettings();
            },
            child: Text('APRI CONFIGURAZIONE'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}