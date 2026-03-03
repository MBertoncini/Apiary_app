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
  Future<void> syncPending() async {
    final pending = await _dao.getPendingSync();
    for (final record in pending) {
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

        await _apiService.postMultipart(
          ApiConstants.analisiTelainiUrl,
          fields,
          file: imageFile,
          fileField: 'immagine',
        );

        await _dao.markSynced(record['id']);
      } catch (e) {
        debugPrint('AnalisiTelainoService: sync failed for record ${record['id']}: $e');
      }
    }
  }
}
