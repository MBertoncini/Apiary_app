// lib/services/attrezzatura_service.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/attrezzatura.dart';
import '../models/spesa_attrezzatura.dart';
import '../models/manutenzione.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class AttrezzaturaService {
  final ApiService _apiService;

  AttrezzaturaService(this._apiService);

  // Metodo helper per la gestione delle risposte API
  Future<T> _handleApiResponse<T>(
      Future<dynamic> apiCall, String errorMessage, T Function(dynamic) transform) async {
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
      debugPrint('$errorMessage: $e');
      throw _formatErrorMessage(e);
    }
  }

  // Formatta il messaggio di errore in modo più user-friendly
  String _formatErrorMessage(dynamic error) {
    String errorMsg = error.toString();

    if (errorMsg.contains('<html>') || errorMsg.contains('<!DOCTYPE')) {
      return 'Impossibile connettersi al server. Verifica la tua connessione internet e riprova.';
    }

    if (errorMsg.contains('500')) {
      return 'Il server ha riscontrato un problema interno. Riprova più tardi.';
    }

    return errorMsg;
  }

  // ==================== ATTREZZATURE ====================

  // Ottiene tutte le attrezzature
  Future<List<Attrezzatura>> getAttrezzature() async {
    return _handleApiResponse(
      _apiService.get(ApiConstants.attrezzatureUrl),
      'Errore nel recupero delle attrezzature',
      (data) => (data as List).map((json) => Attrezzatura.fromJson(json)).toList(),
    );
  }

  // Ottiene un'attrezzatura specifica
  Future<Attrezzatura> getAttrezzatura(int id) async {
    return _handleApiResponse(
      _apiService.get('${ApiConstants.attrezzatureUrl}$id/'),
      'Errore nel recupero dell\'attrezzatura',
      (data) => Attrezzatura.fromJson(data),
    );
  }

  /// Crea una nuova attrezzatura.
  /// Se `prezzo_acquisto` > 0 il backend registra da solo la SpesaAttrezzatura
  /// (tipo='acquisto') e il Pagamento collegato: il client non deve crearli,
  /// altrimenti l'importo finisce più volte nelle uscite del bilancio.
  Future<Attrezzatura> createAttrezzatura(Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.post(ApiConstants.attrezzatureUrl, data),
      'Errore nella creazione dell\'attrezzatura',
      (response) => Attrezzatura.fromJson(response),
    );
  }

  // Aggiorna un'attrezzatura
  Future<Attrezzatura> updateAttrezzatura(int id, Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.put('${ApiConstants.attrezzatureUrl}$id/', data),
      'Errore nell\'aggiornamento dell\'attrezzatura',
      (response) => Attrezzatura.fromJson(response),
    );
  }

  // Elimina un'attrezzatura
  Future<bool> deleteAttrezzatura(int id) async {
    try {
      await _apiService.delete('${ApiConstants.attrezzatureUrl}$id/');
      return true;
    } catch (e) {
      debugPrint('Errore eliminazione attrezzatura: $e');
      throw _formatErrorMessage(e);
    }
  }

  // ==================== SPESE ATTREZZATURA ====================

  // Ottiene tutte le spese per un'attrezzatura
  Future<List<SpesaAttrezzatura>> getSpeseAttrezzatura(int attrezzaturaId) async {
    final url = ApiConstants.replaceParams(
      ApiConstants.attrezzaturaSpeseUrl,
      {'attrezzatura_id': attrezzaturaId.toString()},
    );
    return _handleApiResponse(
      _apiService.get(url),
      'Errore nel recupero delle spese',
      (data) => (data as List).map((json) => SpesaAttrezzatura.fromJson(json)).toList(),
    );
  }

  // Ottiene tutte le spese attrezzatura (generale)
  Future<List<SpesaAttrezzatura>> getAllSpeseAttrezzatura() async {
    return _handleApiResponse(
      _apiService.get(ApiConstants.speseAttrezzaturaUrl),
      'Errore nel recupero delle spese attrezzatura',
      (data) => (data as List).map((json) => SpesaAttrezzatura.fromJson(json)).toList(),
    );
  }

  // Metodo interno per creare SpesaAttrezzatura.
  // Il Pagamento collegato lo genera il backend (signal su SpesaAttrezzatura),
  // usando `pagato_da` per capire chi ha effettivamente sborsato il denaro.
  Future<SpesaAttrezzatura> _createSpesaAttrezzaturaInternal(Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.post(ApiConstants.speseAttrezzaturaUrl, data),
      'Errore nella creazione della spesa attrezzatura',
      (response) => SpesaAttrezzatura.fromJson(response),
    );
  }

  /// Crea una nuova spesa per un'attrezzatura.
  /// [pagatoDaId] indica chi ha effettivamente pagato; se null il backend usa
  /// l'utente autenticato. Il Pagamento collegato viene creato server-side.
  Future<SpesaAttrezzatura> createSpesaAttrezzatura(
    Map<String, dynamic> data, {
    int? pagatoDaId,
  }) async {
    return _createSpesaAttrezzaturaInternal({
      ...data,
      if (pagatoDaId != null) 'pagato_da': pagatoDaId,
    });
  }

  // Elimina una spesa attrezzatura
  Future<bool> deleteSpesaAttrezzatura(int id) async {
    try {
      await _apiService.delete('${ApiConstants.speseAttrezzaturaUrl}$id/');
      return true;
    } catch (e) {
      debugPrint('Errore eliminazione spesa attrezzatura: $e');
      throw _formatErrorMessage(e);
    }
  }

  // ==================== MANUTENZIONI ====================

  // Ottiene tutte le manutenzioni per un'attrezzatura
  Future<List<Manutenzione>> getManutenzioniAttrezzatura(int attrezzaturaId) async {
    final url = ApiConstants.replaceParams(
      ApiConstants.attrezzaturaManutenzioniUrl,
      {'attrezzatura_id': attrezzaturaId.toString()},
    );
    return _handleApiResponse(
      _apiService.get(url),
      'Errore nel recupero delle manutenzioni',
      (data) => (data as List).map((json) => Manutenzione.fromJson(json)).toList(),
    );
  }

  // Ottiene tutte le manutenzioni (generale)
  Future<List<Manutenzione>> getAllManutenzioni() async {
    return _handleApiResponse(
      _apiService.get(ApiConstants.manutenzioniUrl),
      'Errore nel recupero delle manutenzioni',
      (data) => (data as List).map((json) => Manutenzione.fromJson(json)).toList(),
    );
  }

  // Ottiene una manutenzione specifica
  Future<Manutenzione> getManutenzione(int id) async {
    return _handleApiResponse(
      _apiService.get('${ApiConstants.manutenzioniUrl}$id/'),
      'Errore nel recupero della manutenzione',
      (data) => Manutenzione.fromJson(data),
    );
  }

  /// Crea una nuova manutenzione per un'attrezzatura.
  /// Se costo > 0 crea anche la SpesaAttrezzatura (tipo='manutenzione'); il
  /// Pagamento collegato lo genera il backend a partire dalla spesa.
  /// [pagatoDaId] indica chi ha effettivamente pagato; se null usa [userId].
  Future<Manutenzione> createManutenzione(
    Map<String, dynamic> data, {
    required int userId,
    required String attrezzaturaNome,
    required bool condivisoConGruppo,
    int? pagatoDaId,
  }) async {
    // 1. Crea la manutenzione
    final manutenzione = await _handleApiResponse(
      _apiService.post(ApiConstants.manutenzioniUrl, data),
      'Errore nella creazione della manutenzione',
      (response) => Manutenzione.fromJson(response),
    );

    // 2. Se costo > 0, crea la SpesaAttrezzatura (il Pagamento lo crea il backend)
    final costo = data['costo'];
    if (costo != null && costo > 0) {
      // Determina la data da usare (data_esecuzione o data_programmata)
      final dataSpesa = data['data_esecuzione'] ?? data['data_programmata'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final gruppoId = condivisoConGruppo ? data['gruppo'] : null;
      final tipoDisplay = manutenzione.getTipoDisplay();

      try {
        await _createSpesaAttrezzaturaInternal({
          'attrezzatura': manutenzione.attrezzatura,
          'tipo': 'manutenzione',
          'descrizione': '$tipoDisplay: $attrezzaturaNome',
          'importo': costo,
          'data': dataSpesa,
          'gruppo': gruppoId,
          'utente': userId,
          if (pagatoDaId != null) 'pagato_da': pagatoDaId,
        });
      } catch (e) {
        debugPrint('Errore creazione SpesaAttrezzatura per manutenzione: $e');
      }
    }

    return manutenzione;
  }

  // Aggiorna una manutenzione
  Future<Manutenzione> updateManutenzione(int id, Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.put('${ApiConstants.manutenzioniUrl}$id/', data),
      'Errore nell\'aggiornamento della manutenzione',
      (response) => Manutenzione.fromJson(response),
    );
  }

  // Elimina una manutenzione
  Future<bool> deleteManutenzione(int id) async {
    try {
      await _apiService.delete('${ApiConstants.manutenzioniUrl}$id/');
      return true;
    } catch (e) {
      debugPrint('Errore eliminazione manutenzione: $e');
      throw _formatErrorMessage(e);
    }
  }

  // Completa una manutenzione (cambia stato a 'completata')
  Future<Manutenzione> completaManutenzione(
    int id, {
    double? costo,
    required int userId,
    required String attrezzaturaNome,
    required bool condivisoConGruppo,
    int? gruppoId,
    int? pagatoDaId,
  }) async {
    final dataEsecuzione = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final Map<String, dynamic> updateData = {
      'stato': 'completata',
      'data_esecuzione': dataEsecuzione,
    };

    if (costo != null) {
      updateData['costo'] = costo;
    }

    // Aggiorna la manutenzione
    final manutenzione = await updateManutenzione(id, updateData);

    // Se costo > 0 e la manutenzione non aveva costo prima, crea la
    // SpesaAttrezzatura (il Pagamento collegato lo crea il backend).
    if (costo != null && costo > 0) {
      final gruppoIdEffettivo = condivisoConGruppo ? gruppoId : null;
      final tipoDisplay = manutenzione.getTipoDisplay();

      try {
        await _createSpesaAttrezzaturaInternal({
          'attrezzatura': manutenzione.attrezzatura,
          'tipo': 'manutenzione',
          'descrizione': '$tipoDisplay: $attrezzaturaNome',
          'importo': costo,
          'data': dataEsecuzione,
          'gruppo': gruppoIdEffettivo,
          'utente': userId,
          if (pagatoDaId != null) 'pagato_da': pagatoDaId,
        });
      } catch (e) {
        debugPrint('Errore creazione SpesaAttrezzatura per completamento manutenzione: $e');
      }
    }

    return manutenzione;
  }
}
