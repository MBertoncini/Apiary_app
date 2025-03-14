import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/sync_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

// Provider per il servizio di sincronizzazione
final syncServiceProvider = Provider<SyncService>((ref) {
  final apiService = ApiService(ref.watch(authStateProvider.notifier));
  return SyncService(apiService);
});

// Provider per lo stato di sincronizzazione
final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final connectivityState = ref.watch(connectivityStateProvider);
  
  return SyncStateNotifier(syncService, connectivityState);
});

class SyncStateNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  final ConnectivityState _connectivityState;
  StreamSubscription? _syncSubscription;
  
  SyncStateNotifier(this._syncService, this._connectivityState)
      : super(SyncState.initial()) {
    _init();
  }
  
  void _init() {
    // Ascolta gli aggiornamenti di stato dal servizio di sincronizzazione
    _syncSubscription = _syncService.syncStatusStream.listen((syncStatus) {
      state = SyncState(
        isInProgress: syncStatus.isInProgress,
        lastSyncTime: syncStatus.isSuccess ? DateTime.now() : state.lastSyncTime,
        lastSyncError: syncStatus.isError ? syncStatus.message : null,
        statusMessage: syncStatus.message,
      );
    });
    
    // Se connesso, avvia sincronizzazione automatica
    if (_connectivityState.isConnected) {
      sync();
    }
  }
  
  Future<bool> sync() async {
    if (state.isInProgress || !_connectivityState.isConnected) {
      return false;
    }
    
    state = state.copyWith(
      isInProgress: true,
      statusMessage: 'Sincronizzazione in corso...',
    );
    
    final result = await _syncService.synchronize();
    
    if (result) {
      state = state.copyWith(
        isInProgress: false,
        lastSyncTime: DateTime.now(),
        lastSyncError: null,
        statusMessage: 'Sincronizzazione completata',
      );
    } else {
      state = state.copyWith(
        isInProgress: false,
        lastSyncError: 'Sincronizzazione fallita',
        statusMessage: 'Sincronizzazione fallita',
      );
    }
    
    return result;
  }
  
  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}

// Stato di sincronizzazione
class SyncState {
  final bool isInProgress;
  final DateTime? lastSyncTime;
  final String? lastSyncError;
  final String statusMessage;
  
  SyncState({
    required this.isInProgress,
    this.lastSyncTime,
    this.lastSyncError,
    required this.statusMessage,
  });
  
  factory SyncState.initial() {
    return SyncState(
      isInProgress: false,
      lastSyncTime: null,
      lastSyncError: null,
      statusMessage: 'Mai sincronizzato',
    );
  }
  
  SyncState copyWith({
    bool? isInProgress,
    DateTime? lastSyncTime,
    String? lastSyncError,
    String? statusMessage,
  }) {
    return SyncState(
      isInProgress: isInProgress ?? this.isInProgress,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}