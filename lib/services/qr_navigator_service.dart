import 'package:flutter/material.dart';
import '../database/dao/arnia_dao.dart';
import '../database/dao/apiario_dao.dart';
import '../services/connectivity_service.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';  // Aggiunto l'import
import '../services/api_service.dart';

/// Servizio che gestisce la navigazione dopo la scansione di un QR code
class QrNavigatorService {
  final ArniaDao _arniaDao = ArniaDao();
  final ApiarioDao _apiarioDao = ApiarioDao();
  final ConnectivityService _connectivityService;
  final ApiService _apiService;

  QrNavigatorService(this._connectivityService, this._apiService);

  /// Naviga alla schermata appropriata in base ai dati del QR
  Future<bool> navigateToQrResult(BuildContext context, Map<String, dynamic> qrData) async {
    bool isConnected = await _connectivityService.isConnected();
    
    try {
      if (qrData['type'] == 'arnia') {
        return await _navigateToArnia(context, qrData, isConnected);
      } else if (qrData['type'] == 'apiario') {
        return await _navigateToApiario(context, qrData, isConnected);
      }
      
      // Tipo QR non riconosciuto
      _showErrorDialog(context, 'Tipo QR non supportato', 
          'Il formato del QR code scansionato non è riconosciuto.');
      return false;
    } catch (e) {
      _showErrorDialog(context, 'Errore', 'Si è verificato un errore: $e');
      return false;
    }
  }

  /// Naviga alla schermata di dettaglio dell'arnia
  Future<bool> _navigateToArnia(BuildContext context, Map<String, dynamic> qrData, bool isConnected) async {
    final int arniaId = qrData['id'];
    
    // Prima cerca l'arnia localmente
    final arnia = await _arniaDao.getById(arniaId);
    
    if (arnia != null) {
      // L'arnia è stata trovata localmente, naviga direttamente
      Navigator.of(context).pushNamed(
        AppConstants.arniaDetailRoute,
        arguments: arniaId,
      );
      return true;
    } else if (isConnected) {
      // L'arnia non è stata trovata localmente, ma siamo online
      // Tenta di recuperarla dal server e poi navigare
      try {
        final response = await _apiService.get('${ApiConstants.arnieUrl}$arniaId/');
        
        // Salva l'arnia localmente per uso futuro
        await _arniaDao.syncFromServer([response]);
        
        Navigator.of(context).pushNamed(
          AppConstants.arniaDetailRoute,
          arguments: arniaId,
        );
        return true;
      } catch (e) {
        _showErrorDialog(context, 'Arnia non trovata', 
            'L\'arnia scansionata non è stata trovata nel sistema. Assicurati di avere i permessi necessari.');
        return false;
      }
    } else {
      // Offline e l'arnia non è nel database locale
      _showErrorDialog(context, 'Arnia non disponibile offline', 
          'L\'arnia scansionata non è disponibile in modalità offline. Connettiti a internet per scaricare i dati.');
      return false;
    }
  }

  /// Naviga alla schermata di dettaglio dell'apiario
  Future<bool> _navigateToApiario(BuildContext context, Map<String, dynamic> qrData, bool isConnected) async {
    final int apiarioId = qrData['id'];
    
    // Prima cerca l'apiario localmente
    final apiario = await _apiarioDao.getById(apiarioId);
    
    if (apiario != null) {
      // L'apiario è stato trovato localmente, naviga direttamente
      Navigator.of(context).pushNamed(
        AppConstants.apiarioDetailRoute,
        arguments: apiarioId,
      );
      return true;
    } else if (isConnected) {
      // L'apiario non è stato trovato localmente, ma siamo online
      // Tenta di recuperarlo dal server e poi navigare
      try {
        final response = await _apiService.get('${ApiConstants.apiariUrl}$apiarioId/');
        
        // Salva l'apiario localmente per uso futuro
        await _apiarioDao.syncFromServer([response]);
        
        Navigator.of(context).pushNamed(
          AppConstants.apiarioDetailRoute,
          arguments: apiarioId,
        );
        return true;
      } catch (e) {
        _showErrorDialog(context, 'Apiario non trovato', 
            'L\'apiario scansionato non è stato trovato nel sistema. Assicurati di avere i permessi necessari.');
        return false;
      }
    } else {
      // Offline e l'apiario non è nel database locale
      _showErrorDialog(context, 'Apiario non disponibile offline', 
          'L\'apiario scansionato non è disponibile in modalità offline. Connettiti a internet per scaricare i dati.');
      return false;
    }
  }

  /// Mostra un dialogo di errore
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}