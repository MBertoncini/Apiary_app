// lib/services/pagamento_service.dart
import '../models/pagamento.dart';
import '../models/quota_utente.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class PagamentoService {
  final ApiService _apiService;
  
  PagamentoService(this._apiService);
  
  // Metodo per ottenere tutti i pagamenti
  Future<List<Pagamento>> getPagamenti() async {
    try {
      final response = await _apiService.get(ApiConstants.pagamentiUrl);
      
      if (response is List) {
        return response.map((json) => Pagamento.fromJson(json)).toList();
      } else if (response is Map && response.containsKey('results')) {
        final results = response['results'] as List;
        return results.map((json) => Pagamento.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Errore nel recupero dei pagamenti: $e');
      return [];
    }
  }
  
  // Metodo per ottenere un pagamento specifico
  Future<Pagamento> getPagamento(int id) async {
    final response = await _apiService.get('${ApiConstants.pagamentiUrl}$id/');
    return Pagamento.fromJson(response);
  }
  
  // Metodo per creare un nuovo pagamento
  Future<Pagamento> createPagamento(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConstants.pagamentiUrl, data);
    return Pagamento.fromJson(response);
  }
  
  // Metodo per aggiornare un pagamento esistente
  Future<Pagamento> updatePagamento(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('${ApiConstants.pagamentiUrl}$id/', data);
    return Pagamento.fromJson(response);
  }
  
  // Metodo per eliminare un pagamento
  Future<bool> deletePagamento(int id) async {
    try {
      await _apiService.delete('${ApiConstants.pagamentiUrl}$id/');
      return true;
    } catch (e) {
      print('Errore eliminazione pagamento: $e');
      return false;
    }
  }
  
  // Metodo per ottenere tutte le quote
  Future<List<QuotaUtente>> getQuote() async {
    try {
      final response = await _apiService.get(ApiConstants.quoteUrl);
      
      if (response is List) {
        return response.map((json) => QuotaUtente.fromJson(json)).toList();
      } else if (response is Map && response.containsKey('results')) {
        final results = response['results'] as List;
        return results.map((json) => QuotaUtente.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Errore nel recupero delle quote: $e');
      return [];
    }
  }
  
  // Metodo per ottenere una quota specifica
  Future<QuotaUtente> getQuota(int id) async {
    final response = await _apiService.get('${ApiConstants.quoteUrl}$id/');
    return QuotaUtente.fromJson(response);
  }
  
  // Metodo per creare una nuova quota
  Future<QuotaUtente> createQuota(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConstants.quoteUrl, data);
    return QuotaUtente.fromJson(response);
  }
  
  // Metodo per aggiornare una quota esistente
  Future<QuotaUtente> updateQuota(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('${ApiConstants.quoteUrl}$id/', data);
    return QuotaUtente.fromJson(response);
  }
  
  // Metodo per eliminare una quota
  Future<bool> deleteQuota(int id) async {
    try {
      await _apiService.delete('${ApiConstants.quoteUrl}$id/');
      return true;
    } catch (e) {
      print('Errore eliminazione quota: $e');
      return false;
    }
  }
}