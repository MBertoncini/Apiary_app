import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/dao/arnia_dao.dart';
import '../database/dao/apiario_dao.dart';
import '../services/connectivity_service.dart';
import '../services/language_service.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
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
    
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    try {
      if (qrData['type'] == 'arnia') {
        return await _navigateToArnia(context, qrData, isConnected, s);
      } else if (qrData['type'] == 'apiario') {
        return await _navigateToApiario(context, qrData, isConnected, s);
      }

      // Tipo QR non riconosciuto
      _showErrorDialog(context, s.qrNavUnsupportedTitle, s.qrNavUnsupportedMsg);
      return false;
    } catch (e) {
      _showErrorDialog(context, s.qrNavErrorTitle, s.qrNavErrorMsg('$e'));
      return false;
    }
  }

  /// Naviga alla schermata di dettaglio dell'arnia
  Future<bool> _navigateToArnia(BuildContext context, Map<String, dynamic> qrData, bool isConnected, dynamic s) async {
    final int arniaId = qrData['id'];

    // Prima cerca l'arnia localmente
    final arnia = await _arniaDao.getById(arniaId);

    if (arnia != null) {
      Navigator.of(context).pushNamed(
        AppConstants.arniaDetailRoute,
        arguments: arniaId,
      );
      return true;
    } else if (isConnected) {
      try {
        final response = await _apiService.get('${ApiConstants.arnieUrl}$arniaId/');
        await _arniaDao.syncFromServer([response]);
        Navigator.of(context).pushNamed(
          AppConstants.arniaDetailRoute,
          arguments: arniaId,
        );
        return true;
      } catch (e) {
        _showErrorDialog(context, s.qrNavArniaNonTrovatoTitle, s.qrNavArniaNonTrovatoMsg);
        return false;
      }
    } else {
      _showErrorDialog(context, s.qrNavArniaOfflineTitle, s.qrNavArniaOfflineMsg);
      return false;
    }
  }

  /// Naviga alla schermata di dettaglio dell'apiario
  Future<bool> _navigateToApiario(BuildContext context, Map<String, dynamic> qrData, bool isConnected, dynamic s) async {
    final int apiarioId = qrData['id'];

    // Prima cerca l'apiario localmente
    final apiario = await _apiarioDao.getById(apiarioId);

    if (apiario != null) {
      Navigator.of(context).pushNamed(
        AppConstants.apiarioDetailRoute,
        arguments: apiarioId,
      );
      return true;
    } else if (isConnected) {
      try {
        final response = await _apiService.get('${ApiConstants.apiariUrl}$apiarioId/');
        await _apiarioDao.syncFromServer([response]);
        Navigator.of(context).pushNamed(
          AppConstants.apiarioDetailRoute,
          arguments: apiarioId,
        );
        return true;
      } catch (e) {
        _showErrorDialog(context, s.qrNavApiarioNonTrovatoTitle, s.qrNavApiarioNonTrovatoMsg);
        return false;
      }
    } else {
      _showErrorDialog(context, s.qrNavApiarioOfflineTitle, s.qrNavApiarioOfflineMsg);
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}