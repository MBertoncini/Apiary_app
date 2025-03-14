import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/dao/apiario_dao.dart';
import '../models/apiario.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Provider per i DAO
final apiarioDaoProvider = Provider((ref) => ApiarioDao());

// Provider per lo stato degli apiari
final apiariStateProvider = StateNotifierProvider<ApiariStateNotifier, ApiariState>((ref) {
  final authState = ref.watch(authStateProvider);
  final apiarioDao = ref.watch(apiarioDaoProvider);
  final apiService = ApiService(ref.read(authStateProvider.notifier));
  
  return ApiariStateNotifier(apiarioDao, apiService, authState.isAuthenticated);
});

class ApiariStateNotifier extends StateNotifier<ApiariState> {
  final ApiarioDao _apiarioDao;
  final ApiService _apiService;
  final bool _isAuthenticated;
  
  ApiariStateNotifier(this._apiarioDao, this._apiService, this._isAuthenticated)
      : super(ApiariState.initial()) {
    if (_isAuthenticated) {
      loadApiari();
    }
  }
  
  Future<void> loadApiari() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Prima carica i dati locali
      final apiari = await _apiarioDao.getAll();
      state = state.copyWith(
        apiari: apiari,
        isLoading: false,
        selectedApiarioId: apiari.isNotEmpty ? apiari.first.id : null,
      );
      
      // Poi prova a sincronizzare da server in background
      _syncFromServer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: 'Errore caricamento apiari: ${e.toString()}',
      );
    }
  }
  
  Future<void> _syncFromServer() async {
    try {
      final apiariData = await _apiService.get(ApiConstants.apiariUrl);
      
      // Converti i dati JSON in oggetti Apiario
      final serverApiari = (apiariData as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      // Sincronizza con il database locale
      await _apiarioDao.syncFromServer(serverApiari);
      
      // Ricarica i dati dal database locale
      final apiari = await _apiarioDao.getAll();
      state = state.copyWith(
        apiari: apiari,
        isLoading: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      // Non aggiornare lo stato in caso di errore, abbiamo già caricato i dati locali
      print('Errore sincronizzazione apiari dal server: $e');
    }
  }
  
  Future<void> createApiario(Apiario apiario) async {
    state = state.copyWith(isSaving: true);
    
    try {
      // Prima crea sul server
      final response = await _apiService.post(ApiConstants.apiariUrl, apiario.toJson());
      
      // Poi salva localmente con ID dal server
      final newApiario = Apiario.fromJson(response);
      await _apiarioDao.insert(newApiario);
      
      // Aggiorna lo stato
      final apiari = await _apiarioDao.getAll();
      state = state.copyWith(
        apiari: apiari,
        isSaving: false,
        selectedApiarioId: newApiario.id,
      );
    } catch (e) {
      // Se il server fallisce, crea solo localmente
      try {
        final id = await _apiarioDao.insert(apiario);
        
        // Aggiorna lo stato
        final apiari = await _apiarioDao.getAll();
        state = state.copyWith(
          apiari: apiari,
          isSaving: false,
          selectedApiarioId: id,
          error: 'Apiario salvato solo localmente, sincronizzazione fallita',
        );
      } catch (dbError) {
        state = state.copyWith(
          isSaving: false,
          error: 'Errore salvataggio apiario: ${dbError.toString()}',
        );
      }
    }
  }
  
  Future<void> updateApiario(Apiario apiario) async {
    state = state.copyWith(isSaving: true);
    
    try {
      // Prima aggiorna sul server
      await _apiService.put('${ApiConstants.apiariUrl}${apiario.id}/', apiario.toJson());
      
      // Poi aggiorna localmente
      await _apiarioDao.update(apiario);
      
      // Aggiorna lo stato
      final apiari = await _apiarioDao.getAll();
      state = state.copyWith(
        apiari: apiari,
        isSaving: false,
      );
    } catch (e) {
      // Se il server fallisce, aggiorna solo localmente
      try {
        await _apiarioDao.update(apiario);
        
        // Aggiorna lo stato
        final apiari = await _apiarioDao.getAll();
        state = state.copyWith(
          apiari: apiari,
          isSaving: false,
          error: 'Apiario aggiornato solo localmente, sincronizzazione fallita',
        );
      } catch (dbError) {
        state = state.copyWith(
          isSaving: false,
          error: 'Errore aggiornamento apiario: ${dbError.toString()}',
        );
      }
    }
  }
  
  Future<void> deleteApiario(int id) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Prima elimina sul server
      await _apiService.delete('${ApiConstants.apiariUrl}$id/');
      
      // Poi elimina localmente
      await _apiarioDao.delete(id);
      
      // Aggiorna lo stato
      final apiari = await _apiarioDao.getAll();
      state = state.copyWith(
        apiari: apiari,
        isLoading: false,
        selectedApiarioId: apiari.isNotEmpty ? apiari.first.id : null,
      );
    } catch (e) {
      // Se il server fallisce, elimina solo localmente
      try {
        await _apiarioDao.delete(id);
        
        // Aggiorna lo stato
        final apiari = await _apiarioDao.getAll();
        state = state.copyWith(
          apiari: apiari,
          isLoading: false,
          selectedApiarioId: apiari.isNotEmpty ? apiari.first.id : null,
          error: 'Apiario eliminato solo localmente, sincronizzazione fallita',
        );
      } catch (dbError) {
        state = state.copyWith(
          isLoading: false,
          error: 'Errore eliminazione apiario: ${dbError.toString()}',
        );
      }
    }
  }
  
  void selectApiario(int id) {
    state = state.copyWith(selectedApiarioId: id);
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Stato degli apiari
class ApiariState {
  final List<Apiario> apiari;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final int? selectedApiarioId;
  final DateTime? lastSyncTime;
  
  ApiariState({
    required this.apiari,
    required this.isLoading,
    required this.isSaving,
    this.error,
    this.selectedApiarioId,
    this.lastSyncTime,
  });
  
  factory ApiariState.initial() {
    return ApiariState(
      apiari: [],
      isLoading: false,
      isSaving: false,
      error: null,
      selectedApiarioId: null,
      lastSyncTime: null,
    );
  }
  
  ApiariState copyWith({
    List<Apiario>? apiari,
    bool? isLoading,
    bool? isSaving,
    String? error,
    int? selectedApiarioId,
    DateTime? lastSyncTime,
  }) {
    return ApiariState(
      apiari: apiari ?? this.apiari,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      selectedApiarioId: selectedApiarioId ?? this.selectedApiarioId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
  
  Apiario? get selectedApiario {
    if (selectedApiarioId == null) return null;
    try {
      return apiari.firstWhere((element) => element.id == selectedApiarioId);
    } catch (e) {
      return null;
    }
  }
}