// lib/services/attrezzatura_service.dart
import 'package:intl/intl.dart';
import '../models/attrezzatura.dart';
import '../models/spesa_attrezzatura.dart';
import '../models/manutenzione.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';
import 'pagamento_service.dart';

class AttrezzaturaService {
  final ApiService _apiService;
  final PagamentoService _pagamentoService;

  AttrezzaturaService(this._apiService)
      : _pagamentoService = PagamentoService(_apiService);

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
      print('$errorMessage: $e');
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
  /// Se prezzo_acquisto > 0, crea automaticamente:
  /// - SpesaAttrezzatura (tipo='acquisto')
  /// - Pagamento
  Future<Attrezzatura> createAttrezzatura(
    Map<String, dynamic> data, {
    required int userId,
  }) async {
    // 1. Crea l'attrezzatura
    final attrezzatura = await _handleApiResponse(
      _apiService.post(ApiConstants.attrezzatureUrl, data),
      'Errore nella creazione dell\'attrezzatura',
      (response) => Attrezzatura.fromJson(response),
    );

    // 2. Se prezzo_acquisto > 0, crea SpesaAttrezzatura e Pagamento
    final prezzoAcquisto = data['prezzo_acquisto'];
    if (prezzoAcquisto != null && prezzoAcquisto > 0) {
      final dataAcquisto = data['data_acquisto'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final condivisoConGruppo = data['condiviso_con_gruppo'] ?? false;
      final gruppoId = condivisoConGruppo ? data['gruppo'] : null;

      // Crea SpesaAttrezzatura
      try {
        await _createSpesaAttrezzaturaInternal({
          'attrezzatura': attrezzatura.id,
          'tipo': 'acquisto',
          'descrizione': 'Acquisto: ${attrezzatura.nome}',
          'importo': prezzoAcquisto,
          'data': dataAcquisto,
          'gruppo': gruppoId,
        });
      } catch (e) {
        print('Errore creazione SpesaAttrezzatura per acquisto: $e');
      }

      // Crea Pagamento
      try {
        await _pagamentoService.createPagamento({
          'utente': userId,
          'importo': prezzoAcquisto,
          'data': dataAcquisto,
          'descrizione': 'Acquisto attrezzatura: ${attrezzatura.nome}',
          'gruppo': gruppoId,
        });
      } catch (e) {
        print('Errore creazione Pagamento per acquisto attrezzatura: $e');
      }
    }

    return attrezzatura;
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
      print('Errore eliminazione attrezzatura: $e');
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

  // Metodo interno per creare SpesaAttrezzatura (senza Pagamento)
  Future<SpesaAttrezzatura> _createSpesaAttrezzaturaInternal(Map<String, dynamic> data) async {
    return _handleApiResponse(
      _apiService.post(ApiConstants.speseAttrezzaturaUrl, data),
      'Errore nella creazione della spesa attrezzatura',
      (response) => SpesaAttrezzatura.fromJson(response),
    );
  }

  /// Crea una nuova spesa per un'attrezzatura.
  /// Crea automaticamente un Pagamento collegato.
  Future<SpesaAttrezzatura> createSpesaAttrezzatura(
    Map<String, dynamic> data, {
    required int userId,
    required String attrezzaturaNome,
    required bool condivisoConGruppo,
  }) async {
    // 1. Crea la SpesaAttrezzatura
    final spesa = await _createSpesaAttrezzaturaInternal(data);

    // 2. Crea il Pagamento collegato
    final gruppoId = condivisoConGruppo ? data['gruppo'] : null;
    final tipoDisplay = spesa.getTipoDisplay();

    try {
      await _pagamentoService.createPagamento({
        'utente': userId,
        'importo': spesa.importo,
        'data': data['data'],
        'descrizione': 'Spesa attrezzatura ($tipoDisplay): $attrezzaturaNome - ${spesa.descrizione}',
        'gruppo': gruppoId,
      });
    } catch (e) {
      print('Errore creazione Pagamento per spesa attrezzatura: $e');
    }

    return spesa;
  }

  // Elimina una spesa attrezzatura
  Future<bool> deleteSpesaAttrezzatura(int id) async {
    try {
      await _apiService.delete('${ApiConstants.speseAttrezzaturaUrl}$id/');
      return true;
    } catch (e) {
      print('Errore eliminazione spesa attrezzatura: $e');
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
  /// Se costo > 0, crea automaticamente:
  /// - SpesaAttrezzatura (tipo='manutenzione')
  /// - Pagamento
  Future<Manutenzione> createManutenzione(
    Map<String, dynamic> data, {
    required int userId,
    required String attrezzaturaNome,
    required bool condivisoConGruppo,
  }) async {
    // 1. Crea la manutenzione
    final manutenzione = await _handleApiResponse(
      _apiService.post(ApiConstants.manutenzioniUrl, data),
      'Errore nella creazione della manutenzione',
      (response) => Manutenzione.fromJson(response),
    );

    // 2. Se costo > 0, crea SpesaAttrezzatura e Pagamento
    final costo = data['costo'];
    if (costo != null && costo > 0) {
      // Determina la data da usare (data_esecuzione o data_programmata)
      final dataSpesa = data['data_esecuzione'] ?? data['data_programmata'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final gruppoId = condivisoConGruppo ? data['gruppo'] : null;
      final tipoDisplay = manutenzione.getTipoDisplay();

      // Crea SpesaAttrezzatura
      try {
        await _createSpesaAttrezzaturaInternal({
          'attrezzatura': manutenzione.attrezzatura,
          'tipo': 'manutenzione',
          'descrizione': '$tipoDisplay: $attrezzaturaNome',
          'importo': costo,
          'data': dataSpesa,
          'gruppo': gruppoId,
        });
      } catch (e) {
        print('Errore creazione SpesaAttrezzatura per manutenzione: $e');
      }

      // Crea Pagamento
      try {
        await _pagamentoService.createPagamento({
          'utente': userId,
          'importo': costo,
          'data': dataSpesa,
          'descrizione': 'Manutenzione attrezzatura: $attrezzaturaNome - $tipoDisplay',
          'gruppo': gruppoId,
        });
      } catch (e) {
        print('Errore creazione Pagamento per manutenzione: $e');
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
      print('Errore eliminazione manutenzione: $e');
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

    // Se costo > 0 e la manutenzione non aveva costo prima, crea SpesaAttrezzatura e Pagamento
    if (costo != null && costo > 0) {
      final gruppoIdEffettivo = condivisoConGruppo ? gruppoId : null;
      final tipoDisplay = manutenzione.getTipoDisplay();

      // Crea SpesaAttrezzatura
      try {
        await _createSpesaAttrezzaturaInternal({
          'attrezzatura': manutenzione.attrezzatura,
          'tipo': 'manutenzione',
          'descrizione': '$tipoDisplay: $attrezzaturaNome',
          'importo': costo,
          'data': dataEsecuzione,
          'gruppo': gruppoIdEffettivo,
        });
      } catch (e) {
        print('Errore creazione SpesaAttrezzatura per completamento manutenzione: $e');
      }

      // Crea Pagamento
      try {
        await _pagamentoService.createPagamento({
          'utente': userId,
          'importo': costo,
          'data': dataEsecuzione,
          'descrizione': 'Manutenzione attrezzatura: $attrezzaturaNome - $tipoDisplay',
          'gruppo': gruppoIdEffettivo,
        });
      } catch (e) {
        print('Errore creazione Pagamento per completamento manutenzione: $e');
      }
    }

    return manutenzione;
  }
}
