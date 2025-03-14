import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'database_helper.dart';
import 'dao/apiario_dao.dart';
import 'dao/arnia_dao.dart';
import 'dao/controllo_arnia_dao.dart';
// Importa altri DAO secondo necessità

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService;
  final ApiarioDao _apiarioDao = ApiarioDao();
  final ArniaDao _arniaDao = ArniaDao();
  final ControlloArniaDao _controlloArniaDao = ControlloArniaDao();
  // Istanzia altri DAO secondo necessità
  
  bool _isSyncing = false;
  final _syncController = StreamController<SyncStatus>.broadcast();
  
  Stream<SyncStatus> get syncStatusStream => _syncController.stream;
  bool get isSyncing => _isSyncing;
  
  SyncService(this._apiService);
  
  Future<bool> synchronize({bool force = false}) async {
    if (_isSyncing) {
      return false;
    }
    
    // Verifica connettività
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _syncController.add(SyncStatus(
        isError: true, 
        message: 'Nessuna connessione a internet'
      ));
      return false;
    }
    
    _isSyncing = true;
    _syncController.add(SyncStatus(
      isInProgress: true, 
      message: 'Sincronizzazione in corso...'
    ));
    
    try {
      // Ottieni ultimo timestamp sincronizzazione
      final lastSync = await _dbHelper.getLastSyncTime('apiari');
      
      // 1. Push: Invia modifiche pendenti al server
      await _pushChanges();
      
      // 2. Pull: Ottieni modifiche dal server
      await _pullChanges(lastSync);
      
      // 3. Aggiorna timestamp di sincronizzazione
      final now = DateTime.now().toIso8601String();
      await _dbHelper.updateSyncStatus('apiari', now);
      await _dbHelper.updateSyncStatus('arnie', now);
      await _dbHelper.updateSyncStatus('controlli', now);
      // Aggiorna altri timestamp secondo necessità
      
      _syncController.add(SyncStatus(
        isSuccess: true, 
        message: 'Sincronizzazione completata'
      ));
      
      return true;
    } catch (e) {
      _syncController.add(SyncStatus(
        isError: true, 
        message: 'Errore durante la sincronizzazione: $e'
      ));
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _pushChanges() async {
    // Invia apiari modificati
    final changedApiari = await _apiarioDao.getPendingChanges();
    for (final apiario in changedApiari) {
      try {
        final apiarioJson = apiario.toJson();
        // Rimuovi campi specifici per il database locale
        apiarioJson.remove('sync_status');
        apiarioJson.remove('last_updated');
        
        // Invia al server
        final response = await _apiService.put(
          '${ApiConstants.apiariUrl}${apiario.id}/', 
          apiarioJson
        );
        
        // Marca come sincronizzato
        await _apiarioDao.markSynced(apiario.id);
      } catch (e) {
        print('Errore sincronizzazione apiario ${apiario.id}: $e');
        // Continua con il prossimo elemento anche se questo fallisce
      }
    }
    
    // Invia arnie modificate
    final changedArnie = await _arniaDao.getPendingChanges();
    for (final arnia in changedArnie) {
      try {
        final arniaJson = arnia.toJson();
        arniaJson.remove('sync_status');
        arniaJson.remove('last_updated');
        
        await _apiService.put(
          '${ApiConstants.arnieUrl}${arnia.id}/', 
          arniaJson
        );
        
        await _arniaDao.markSynced(arnia.id);
      } catch (e) {
        print('Errore sincronizzazione arnia ${arnia.id}: $e');
      }
    }
    
    // Invia controlli modificati
    final changedControlli = await _controlloArniaDao.getPendingChanges();
    for (final controllo in changedControlli) {
      try {
        final controlloJson = controllo.toJson();
        controlloJson.remove('sync_status');
        controlloJson.remove('last_updated');
        
        await _apiService.put(
          '${ApiConstants.controlliUrl}${controllo.id}/', 
          controlloJson
        );
        
        await _controlloArniaDao.markSynced(controllo.id);
      } catch (e) {
        print('Errore sincronizzazione controllo ${controllo.id}: $e');
      }
    }
    
    // Continua con altre entità (regine, trattamenti, etc.)
  }
  
  Future<void> _pullChanges(String? lastSync) async {
    // Ottieni dati aggiornati dal server
    final syncData = await _apiService.syncData(lastSync: lastSync);
    
    // Sincronizza apiari
    if (syncData.containsKey('apiari')) {
      await _apiarioDao.syncFromServer(syncData['apiari']);
    }
    
    // Sincronizza arnie
    if (syncData.containsKey('arnie')) {
      await _arniaDao.syncFromServer(syncData['arnie']);
    }
    
    // Sincronizza controlli
    if (syncData.containsKey('controlli')) {
      await _controlloArniaDao.syncFromServer(syncData['controlli']);
    }
    
    // Continua con altre entità (regine, trattamenti, etc.)
  }
  
  void dispose() {
    _syncController.close();
  }
}

class SyncStatus {
  final bool isInProgress;
  final bool isSuccess;
  final bool isError;
  final String message;
  
  SyncStatus({
    this.isInProgress = false,
    this.isSuccess = false,
    this.isError = false,
    this.message = '',
  });
}