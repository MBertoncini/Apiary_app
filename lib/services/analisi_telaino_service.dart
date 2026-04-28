import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../database/dao/analisi_telaino_dao.dart';
import '../models/analisi_telaino.dart';
import 'api_service.dart';

class AnalisiTelainoService {
  final ApiService _apiService;
  final AnalisiTelainoDao _dao = AnalisiTelainoDao();

  AnalisiTelainoService(this._apiService);

  /// Save an analysis: tries online first, falls back to local-only.
  Future<AnalisiTelaino> saveAnalisi(AnalisiTelaino analisi, {File? imageFile}) async {
    try {
      // Try to save to server
      final fields = <String, String>{
        'arnia': analisi.arnia.toString(),
        'numero_telaino': analisi.numeroTelaino.toString(),
        'facciata': analisi.facciata,
        'conteggio_api': analisi.conteggioApi.toString(),
        'conteggio_regine': analisi.conteggioRegine.toString(),
        'conteggio_fuchi': analisi.conteggioFuchi.toString(),
        'conteggio_celle_reali': analisi.conteggioCelleReali.toString(),
        'confidence_media': analisi.confidenceMedia.toStringAsFixed(4),
      };
      if (analisi.note != null && analisi.note!.isNotEmpty) {
        fields['note'] = analisi.note!;
      }

      final response = await _apiService.postMultipart(
        ApiConstants.analisiTelainiUrl,
        fields,
        file: imageFile,
        fileField: 'immagine',
      );

      final saved = AnalisiTelaino.fromJson(response);

      // Cache locally as synced
      final localData = response as Map<String, dynamic>;
      localData['sync_status'] = 'synced';
      localData['last_updated'] = DateTime.now().millisecondsSinceEpoch;
      await _dao.insert(localData);

      return saved;
    } catch (e) {
      debugPrint('AnalisiTelainoService: online save failed, saving locally: $e');
      // Save locally with pending status
      final localData = analisi.toJson();
      localData['sync_status'] = 'pending';
      localData['last_updated'] = DateTime.now().millisecondsSinceEpoch;
      if (imageFile != null) {
        localData['immagine'] = imageFile.path;
      }
      // Generate a temporary negative ID for local records
      localData['id'] = -DateTime.now().millisecondsSinceEpoch;
      await _dao.insert(localData);
      return analisi;
    }
  }

  /// Get analyses for a specific arnia. Tries API first, falls back to local cache.
  Future<List<AnalisiTelaino>> getAnalisiByArnia(int arniaId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.analisiTelainiUrl}?arnia=$arniaId',
      );
      final List<dynamic> results = response is List ? response : (response['results'] ?? []);
      final analisi = results.map((json) => AnalisiTelaino.fromJson(json)).toList();

      // Cache locally
      for (final json in results) {
        if (json is Map<String, dynamic>) {
          json['sync_status'] = 'synced';
          json['last_updated'] = DateTime.now().millisecondsSinceEpoch;
          await _dao.insert(json);
        }
      }

      return analisi;
    } catch (e) {
      debugPrint('AnalisiTelainoService: fetching from local cache: $e');
      final local = await _dao.getByArnia(arniaId);
      return local.map((m) => AnalisiTelaino.fromJson(m)).toList();
    }
  }

  /// Upload pending local analyses to the server.
  ///
  /// Per ogni record con ID negativo (locale-only):
  /// 1. Effettua l'upload e cattura il JSON ritornato dal backend (che porta
  ///    il nuovo ID positivo).
  /// 2. Cancella la riga locale con ID negativo.
  /// 3. Inserisce la nuova versione con sync_status: 'synced'.
  ///
  /// Senza questi step, al successivo getAnalisiByArnia il record server
  /// veniva inserito come nuovo, generando duplicati visibili nella lista.
  ///
  /// Errori: 4xx → marca come 'failed' (record corrotto, niente retry);
  /// 5xx / network → resta pending per retry al prossimo sync.
  Future<void> syncPending() async {
    final pending = await _dao.getPendingSync();
    for (final record in pending) {
      final localId = record['id'] as int;
      try {
        final fields = <String, String>{
          'arnia': record['arnia'].toString(),
          'numero_telaino': record['numero_telaino'].toString(),
          'facciata': record['facciata'].toString(),
          'conteggio_api': record['conteggio_api'].toString(),
          'conteggio_regine': record['conteggio_regine'].toString(),
          'conteggio_fuchi': record['conteggio_fuchi'].toString(),
          'conteggio_celle_reali': record['conteggio_celle_reali'].toString(),
          'confidence_media': record['confidence_media'].toString(),
        };
        if (record['note'] != null) {
          fields['note'] = record['note'].toString();
        }

        File? imageFile;
        if (record['immagine'] != null && record['immagine'].toString().startsWith('/')) {
          final f = File(record['immagine'].toString());
          if (await f.exists()) imageFile = f;
        }

        final response = await _apiService.postMultipart(
          ApiConstants.analisiTelainiUrl,
          fields,
          file: imageFile,
          fileField: 'immagine',
        );

        if (response is Map<String, dynamic> && response['id'] != null) {
          // Cancella il record con ID locale negativo e re-inserisci con
          // l'ID server. Senza questa sostituzione, getAnalisiByArnia
          // duplica la riga al primo refresh dal backend.
          await _dao.delete(localId);
          final replacement = Map<String, dynamic>.from(response);
          replacement['sync_status'] = 'synced';
          replacement['last_updated'] = DateTime.now().millisecondsSinceEpoch;
          await _dao.insert(replacement);
        } else {
          // Backend non ha restituito ID: come fallback marca synced il
          // record locale (vecchio comportamento), perdendo la connessione
          // col record server. Sarà comunque rimpiazzato dal prossimo GET.
          await _dao.markSynced(localId);
        }
      } on HttpStatusException catch (e) {
        if (e.isClientError) {
          debugPrint(
              'AnalisiTelainoService: 4xx for record $localId, marking failed: ${e.statusCode} ${e.body}');
          await _dao.markFailed(localId);
        } else {
          // 5xx / altro: lascia il record pending per retry.
          debugPrint(
              'AnalisiTelainoService: ${e.statusCode} for record $localId, will retry: ${e.body}');
        }
      } catch (e) {
        // Errori transitori (network, timeout): record resta pending.
        debugPrint('AnalisiTelainoService: sync transient error for record $localId: $e');
      }
    }
  }
}
