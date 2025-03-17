import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servizio che gestisce e monitora lo stato della connettività
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectionChange => _connectionChangeController.stream;
  bool _hasConnection = false;
  
  ConnectivityService() {
    // Inizializza lo stato
    _checkConnection();
    
    // Ascolta cambiamenti di connettività
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  /// Controlla lo stato attuale della connessione
  Future<void> _checkConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }
  
  /// Aggiorna lo stato della connessione
  void _updateConnectionStatus(ConnectivityResult result) {
    bool hasConnection = result != ConnectivityResult.none;
    
    // Evita notifiche duplicate se lo stato non è cambiato
    if (hasConnection != _hasConnection) {
      _hasConnection = hasConnection;
      _connectionChangeController.add(hasConnection);
    }
  }
  
  /// Controlla se il dispositivo è attualmente connesso
  Future<bool> isConnected() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  void dispose() {
    _connectionChangeController.close();
  }
}