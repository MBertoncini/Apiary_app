import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../database/dao/controllo_arnia_dao.dart';

class ControlloService {
  final ApiService _apiService;
  final ControlloArniaDao _controlloDao = ControlloArniaDao();
  
  ControlloService(this._apiService);
  
  // Salva un controllo (online o offline)
  Future<Map<String, dynamic>> saveControllo(Map<String, dynamic> data) async {
    // Verifica connettività
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;
    
    if (isOnline) {
      try {
        // Online - prova a salvare direttamente al server
        final response = await _apiService.post(ApiConstants.controlliUrl, data);
        
        // Salva anche localmente
        await _controlloDao.syncFromServer([response]);
        
        return response;
      } catch (e) {
        // Fallback al salvataggio offline se l'API fallisce
        print('Errore salvataggio online, uso offline: $e');
        final id = await _controlloDao.insert(data);
        
        // Crea una versione con ID locale per l'UI
        data['id'] = id;
        data['sync_status'] = 'pending';
        
        return data;
      }
    } else {
      // Offline - salva localmente
      final id = await _controlloDao.insert(data);
      
      // Crea una versione con ID locale per l'UI
      data['id'] = id;
      data['sync_status'] = 'pending';
      
      return data;
    }
  }
  
  // Aggiorna un controllo esistente (online o offline)
  Future<Map<String, dynamic>> updateControllo(int id, Map<String, dynamic> data) async {
    // Verifica connettività
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;
    
    if (isOnline) {
      try {
        // Online - prova ad aggiornare sul server
        final response = await _apiService.put('${ApiConstants.controlliUrl}$id/', data);
        
        // Aggiorna anche localmente
        await _controlloDao.syncFromServer([response]);
        
        return response;
      } catch (e) {
        // Fallback al salvataggio offline se l'API fallisce
        print('Errore aggiornamento online, uso offline: $e');
        await _controlloDao.update(id, data);
        
        // Ritorna i dati aggiornati con stato di sincronizzazione
        data['id'] = id;
        data['sync_status'] = 'pending';
        
        return data;
      }
    } else {
      // Offline - aggiorna localmente
      await _controlloDao.update(id, data);
      
      // Ritorna i dati aggiornati con stato di sincronizzazione
      data['id'] = id;
      data['sync_status'] = 'pending';
      
      return data;
    }
  }
  
  // Ottieni un controllo per ID (locale o remoto)
  Future<Map<String, dynamic>?> getControlloById(int id) async {
    // Prima prova a recuperare localmente
    final localControllo = await _controlloDao.getById(id);
    
    // Verifica connettività solo se necessario
    if (localControllo == null) {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        try {
          // Recupera dal server
          final remoteControllo = await _apiService.get('${ApiConstants.controlliUrl}$id/');
          
          // Salva localmente per uso futuro
          await _controlloDao.syncFromServer([remoteControllo]);
          
          return remoteControllo;
        } catch (e) {
          print('Errore nel recupero del controllo: $e');
          return null;
        }
      }
    }
    
    return localControllo;
  }
  
  // Ottieni controlli per un'arnia specifica
  Future<List<Map<String, dynamic>>> getControlliByArnia(int arniaId) async {
    // Prima recupera i dati locali
    List<Map<String, dynamic>> localControlli = await _controlloDao.getByArnia(arniaId);
    
    // Verifica connettività
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;
    
    if (isOnline) {
      try {
        // Recupera dal server
        final response = await _apiService.get('${ApiConstants.arnieUrl}$arniaId/controlli/');
        List<Map<String, dynamic>> remoteControlli = [];
        
        if (response is List) {
          remoteControlli = List<Map<String, dynamic>>.from(response);
        } else if (response is Map && response['results'] != null) {
          remoteControlli = List<Map<String, dynamic>>.from(response['results']);
        }
        
        // Sincronizza con il database locale
        if (remoteControlli.isNotEmpty) {
          await _controlloDao.syncFromServer(remoteControlli);
          
          // Ricarica i dati dal database locale
          localControlli = await _controlloDao.getByArnia(arniaId);
        }
        
        return localControlli;
      } catch (e) {
        print('Errore nel recupero controlli dal server: $e');
        // Fallback ai dati locali
      }
    }
    
    return localControlli;
  }
  
  // Sincronizza manualmente i controlli in sospeso
  Future<bool> syncPendingControlli() async {
    // Verifica connettività
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;
    
    if (!isOnline) {
      return false;
    }
    
    try {
      // Ottieni i controlli in attesa di sincronizzazione
      final pendingControlli = await _controlloDao.getPendingChanges();
      
      for (var controllo in pendingControlli) {
        final id = controllo['id'];
        
        // Rimuovi campi specifici per il database locale
        controllo.remove('sync_status');
        controllo.remove('last_updated');
        
        try {
          if (id > 0) {
            // Se l'ID è positivo, potrebbe esistere già sul server
            await _apiService.put('${ApiConstants.controlliUrl}$id/', controllo);
          } else {
            // Altrimenti è un nuovo controllo
            final response = await _apiService.post(ApiConstants.controlliUrl, controllo);
            
            // Aggiorna l'ID locale con quello del server
            await _controlloDao.delete(id);
            await _controlloDao.syncFromServer([response]);
          }
          
          // Marca come sincronizzato
          await _controlloDao.markSynced(id);
        } catch (e) {
          print('Errore sincronizzazione controllo $id: $e');
          // Continua con il prossimo
        }
      }
      
      return true;
    } catch (e) {
      print('Errore generale durante la sincronizzazione: $e');
      return false;
    }
  }
}