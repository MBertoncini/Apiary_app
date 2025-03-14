import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SyncService with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSync;
  
  // Getter
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSync;
  
  SyncService(this._apiService, this._storageService) {
    _loadLastSyncTime();
    _startPeriodicSync();
  }
  
  Future<void> _loadLastSyncTime() async {
    final timestamp = await _storageService.getLastSyncTimestamp();
    if (timestamp != null) {
      _lastSync = DateTime.parse(timestamp);
      notifyListeners();
    }
  }
  
  void _startPeriodicSync() {
    // Sincronizza ogni X minuti (default: 30)
    _syncTimer = Timer.periodic(
      Duration(minutes: AppConstants.defaultSyncInterval),
      (_) => syncData(),
    );
  }
  
  Future<bool> syncData() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      // Ottieni l'ultimo timestamp di sync
      final lastSync = await _storageService.getLastSyncTimestamp();
      
      // Sincronizza dati
      final syncData = await _apiService.syncData(lastSync: lastSync);
      await _storageService.saveSyncData(syncData);
      
      // Aggiorna last sync
      if (syncData.containsKey('timestamp')) {
        _lastSync = DateTime.parse(syncData['timestamp']);
      }
      
      return true;
    } catch (e) {
      print('Error during sync: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}