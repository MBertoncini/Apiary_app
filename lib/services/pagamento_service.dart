// lib/services/pagamento_service.dart
import '../models/pagamento.dart';
import '../models/quota_utente.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';
import 'dart:convert';

class PagamentoService {
  final ApiService _apiService;
  
  PagamentoService(this._apiService);
  
  // Metodo helper per la gestione delle risposte API
  Future<T> _handleApiResponse<T>(Future<dynamic> apiCall, String errorMessage, T Function(dynamic) transform) async {
    try {
      final response = await apiCall;
      
      // Gestione risposta come lista o come mappa con risultati
      if (response is List) {
        return transform(response);
      } else if (response is Map && response.containsKey('results')) {
        return transform(response['results']);
      } else {
        return transform(response);
      }
    } catch (e) {
      print('$errorMessage: $e');
      // Rethrow con messaggio più pulito
      throw _formatErrorMessage(e);
    }
  }
  
  // Formatta il messaggio di errore in modo più user-friendly
  String _formatErrorMessage(dynamic error) {
    String errorMsg = error.toString();
    
    // Se contiene HTML, fornisci un messaggio più chiaro
    if (errorMsg.contains('<html>') || errorMsg.contains('<!DOCTYPE')) {
      return 'Impossibile connettersi al server. Verifica la tua connessione internet e riprova.';
    }
    
    // Se contiene "500", è probabilmente un errore del server
    if (errorMsg.contains('500')) {
      return 'Il server ha riscontrato un problema interno. Riprova più tardi.';
    }
    
    return errorMsg;
  }
  
  // Metodo per ottenere tutti i pagamenti
  Future<List<Pagamento>> getPagamenti() async {
    return _handleApiResponse(
      _apiService.get(ApiConstants.pagamentiUrl),
      'Errore nel recupero dei pagamenti',
      (data) => (data as List).map((json) => Pagamento.fromJson(json)).toList()
    );
  }
  
  // Metodo per ottenere un pagamento specifico
  Future<Pagamento> getPagamento(int id) async {
    return _handleApiResponse(
      _apiService.get('${ApiConstants.pagamentiUrl}$id/'),
      'Errore nel recupero del pagamento',
      (data) => Pagamento.fromJson(data)
    );
  }
  
  // Metodo per creare un nuovo pagamento
  Future<Pagamento> createPagamento(Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.post(ApiConstants.pagamentiUrl, data),
      'Errore nella creazione del pagamento',
      (response) => Pagamento.fromJson(response)
    );
  }
  
  // Metodo per aggiornare un pagamento esistente
  Future<Pagamento> updatePagamento(int id, Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.put('${ApiConstants.pagamentiUrl}$id/', data),
      'Errore nell\'aggiornamento del pagamento',
      (response) => Pagamento.fromJson(response)
    );
  }
  
  // Metodo per eliminare un pagamento
  Future<bool> deletePagamento(int id) async {
    try {
      await _apiService.delete('${ApiConstants.pagamentiUrl}$id/');
      return true;
    } catch (e) {
      print('Errore eliminazione pagamento: $e');
      throw _formatErrorMessage(e);
    }
  }
  
  // Metodo per ottenere tutte le quote
  Future<List<QuotaUtente>> getQuote() async {
    return _handleApiResponse(
      _apiService.get(ApiConstants.quoteUrl),
      'Errore nel recupero delle quote',
      (data) => (data as List).map((json) => QuotaUtente.fromJson(json)).toList()
    );
  }
  
  // Metodo per ottenere una quota specifica
  Future<QuotaUtente> getQuota(int id) async {
    return _handleApiResponse(
      _apiService.get('${ApiConstants.quoteUrl}$id/'),
      'Errore nel recupero della quota',
      (data) => QuotaUtente.fromJson(data)
    );
  }
  
  // Metodo per creare una nuova quota
  Future<QuotaUtente> createQuota(Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.post(ApiConstants.quoteUrl, data),
      'Errore nella creazione della quota',
      (response) => QuotaUtente.fromJson(response)
    );
  }
  
  // Metodo per aggiornare una quota esistente
  Future<QuotaUtente> updateQuota(int id, Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.put('${ApiConstants.quoteUrl}$id/', data),
      'Errore nell\'aggiornamento della quota',
      (response) => QuotaUtente.fromJson(response)
    );
  }
  
  // Metodo per eliminare una quota
  Future<bool> deleteQuota(int id) async {
    try {
      await _apiService.delete('${ApiConstants.quoteUrl}$id/');
      return true;
    } catch (e) {
      print('Errore eliminazione quota: $e');
      throw _formatErrorMessage(e);
    }
  }
}