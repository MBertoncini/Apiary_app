import 'package:flutter/foundation.dart';
import '../models/colonia.dart';
import '../database/dao/colonia_dao.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

/// Service per la gestione del ciclo di vita delle colonie.
/// Coordina la cache locale (SQLite via [ColoniaDao]) con il backend remoto.
class ColoniaService {
  final ApiService _apiService;
  final ColoniaDao _dao = ColoniaDao();

  ColoniaService(this._apiService);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Restituisce tutte le colonie dell'utente (prima locale, poi dal server).
  Future<List<Colonia>> getColonie() async {
    try {
      final response = await _apiService.get(ApiConstants.colonieUrl);
      final List<dynamic> data = response is List
          ? response
          : (response as Map<String, dynamic>)['results'] ?? [];
      final colonie = data
          .cast<Map<String, dynamic>>()
          .map(Colonia.fromJson)
          .toList();
      await _dao.syncFromServer(colonie.map(ColoniaDao.toRow).toList());
      return colonie;
    } catch (_) {}
    final rows = await _dao.getAll();
    return rows.map(ColoniaDao.fromRow).toList();
  }

  /// Restituisce il dettaglio di una colonia (prima dal server, poi dalla cache).
  Future<Colonia?> getColonia(int coloniaId) async {
    try {
      final url = ApiConstants.replaceParams(
        ApiConstants.coloniaDettaglioUrl,
        {'colonia_id': coloniaId.toString()},
      );
      final response = await _apiService.get(url);
      final colonia = Colonia.fromJson(response as Map<String, dynamic>);
      await _dao.insert(ColoniaDao.toRow(colonia));
      return colonia;
    } catch (_) {}
    final row = await _dao.getById(coloniaId);
    return row != null ? ColoniaDao.fromRow(row) : null;
  }

  /// Restituisce la colonia attiva di un'arnia.
  /// Cache-first con TTL di 5 minuti: interroga il server solo se la cache
  /// è assente, scaduta o [forceRefresh] è true.
  Future<Colonia?> getColoniaAttivaByArnia(
    int arniaId, {
    bool forceRefresh = false,
  }) async {
    const cacheTtlMs = 5 * 60 * 1000; // 5 minuti

    // 1) Leggi dalla cache locale
    final cached = await _dao.getAttivaByArnia(arniaId);
    if (!forceRefresh && cached != null) {
      final lastUpdated = cached['last_updated'] as int?;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (lastUpdated != null && (now - lastUpdated) < cacheTtlMs) {
        debugPrint('[ColoniaService] cache fresca per arnia $arniaId, skip server');
        return ColoniaDao.fromRow(cached);
      }
    }

    // 2) Cache assente o scaduta: recupera dal server
    try {
      final url = ApiConstants.replaceParams(
        ApiConstants.arniaColoniaAttivaUrl,
        {'arnia_id': arniaId.toString()},
      );
      final response = await _apiService.get(url);
      debugPrint('[ColoniaService] risposta server arnia $arniaId: $response');
      final colonia = Colonia.fromJson(response as Map<String, dynamic>);
      debugPrint('[ColoniaService] fromJson ok, id=${colonia.id} arnia=${colonia.arnia} isAttiva=${colonia.isAttiva}');
      try {
        final row = ColoniaDao.toRow(colonia);
        debugPrint('[ColoniaService] toRow: $row');
        await _dao.insert(row);
        debugPrint('[ColoniaService] insert OK per colonia ${colonia.id}');
      } catch (e, st) {
        debugPrint('[ColoniaService] ERRORE insert cache: $e\n$st');
      }
      return colonia;
    } catch (e, st) {
      debugPrint('[ColoniaService] ERRORE fetch/parse server arnia $arniaId: $e\n$st');
    }

    // Fallback: usa la cache anche se scaduta
    debugPrint('[ColoniaService] fallback cache scaduta per arnia $arniaId');
    return cached != null ? ColoniaDao.fromRow(cached) : null;
  }

  /// Restituisce la storia delle colonie di un'arnia.
  Future<List<Colonia>> getStoriaColonieByArnia(int arniaId) async {
    try {
      final url = ApiConstants.replaceParams(
        ApiConstants.arniaStoriaColonieUrl,
        {'arnia_id': arniaId.toString()},
      );
      final response = await _apiService.get(url);
      final List<dynamic> data = response is List
          ? response
          : (response as Map<String, dynamic>)['results'] ?? [];
      return data.cast<Map<String, dynamic>>().map(Colonia.fromJson).toList();
    } catch (_) {}
    final rows = await _dao.getByArnia(arniaId);
    return rows.map(ColoniaDao.fromRow).toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Crea una nuova colonia per un'arnia o un nucleo.
  Future<Colonia?> creaColonia({
    int? arniaId,
    int? nucleoId,
    required String dataInizio,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      if (arniaId != null)  'arnia':  arniaId,
      if (nucleoId != null) 'nucleo': nucleoId,
      'data_inizio': dataInizio,
      if (note != null) 'note': note,
    };
    final response = await _apiService.post(ApiConstants.colonieUrl, payload);
    final colonia = Colonia.fromJson(response as Map<String, dynamic>);
    await _dao.insert(ColoniaDao.toRow(colonia));
    return colonia;
  }

  /// Chiude il ciclo di vita di una colonia.
  Future<Colonia?> chiudiColonia(
    int coloniaId, {
    required String stato,
    String? dataFine,
    String? motivoFine,
    String? noteFine,
    int? coloniaSuccessoreId,
  }) async {
    final url = ApiConstants.replaceParams(
      ApiConstants.coloniaChiudiUrl,
      {'colonia_id': coloniaId.toString()},
    );
    final payload = <String, dynamic>{
      'stato': stato,
      if (dataFine != null)            'data_fine':          dataFine,
      if (motivoFine != null)          'motivo_fine':        motivoFine,
      if (noteFine != null)            'note_fine':          noteFine,
      if (coloniaSuccessoreId != null) 'colonia_successore': coloniaSuccessoreId,
    };
    final response = await _apiService.post(url, payload);
    final colonia = Colonia.fromJson(response as Map<String, dynamic>);
    await _dao.insert(ColoniaDao.toRow(colonia));
    return colonia;
  }

  /// Sposta la colonia in un altro contenitore fisico (nomadismo, conversione).
  Future<Colonia?> spostaColonia(
    int coloniaId, {
    int? arniaId,
    int? nucleoId,
    String? note,
  }) async {
    final url = ApiConstants.replaceParams(
      ApiConstants.coloniaSpostaUrl,
      {'colonia_id': coloniaId.toString()},
    );
    final payload = <String, dynamic>{
      if (arniaId != null)  'arnia':  arniaId,
      if (nucleoId != null) 'nucleo': nucleoId,
      if (note != null)     'note':   note,
    };
    final response = await _apiService.post(url, payload);
    final colonia = Colonia.fromJson(response as Map<String, dynamic>);
    await _dao.insert(ColoniaDao.toRow(colonia));
    return colonia;
  }
}
