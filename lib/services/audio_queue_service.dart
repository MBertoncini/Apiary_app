// lib/services/audio_queue_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coda persistente di registrazioni audio in attesa di essere elaborate
/// da Gemini. I file audio vengono salvati nella directory documenti
/// dell'app; i metadati (path + contesto) vengono salvati in SharedPreferences.
///
/// Un item rimane in coda finché:
///  - Gemini lo elabora con successo → rimosso dalla coda
///  - Il controllo viene salvato nel DB → il file viene eliminato dal disco
///
/// Gli item vengono ordinati per timestamp (prima il più vecchio).
class AudioQueueService {
  static const String _queueKey = 'audio_recording_queue';

  // ── Lettura ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[AudioQueue] parse error: $e');
      return [];
    }
  }

  Future<int> getQueueCount() async {
    final q = await getQueue();
    return q.length;
  }

  // ── Scrittura ────────────────────────────────────────────────────────────

  Future<void> addToQueue({
    required String filePath,
    int? apiarioId,
    String? apiarioNome,
    int? recordingDurationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    final now = DateTime.now();
    queue.add({
      'id': '${now.millisecondsSinceEpoch}_${now.microsecond}',
      'file_path': filePath,
      'apiario_id': apiarioId,
      'apiario_nome': apiarioNome,
      'duration_seconds': recordingDurationSeconds,
      'timestamp': now.toIso8601String(),
    });
    await prefs.setString(_queueKey, jsonEncode(queue));
    debugPrint('[AudioQueue] Added: $filePath (${queue.length} total)');
  }

  Future<void> removeFromQueue(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    queue.removeWhere((item) => item['id'] == id);
    await prefs.setString(_queueKey, jsonEncode(queue));
    debugPrint('[AudioQueue] Removed id=$id (${queue.length} remaining)');
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  // ── Pulizia file ─────────────────────────────────────────────────────────

  /// Elimina il file audio dal disco. Non rimuove dalla coda.
  static Future<void> deleteFile(String? filePath) async {
    if (filePath == null) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[AudioQueue] Deleted file: $filePath');
      }
    } catch (e) {
      debugPrint('[AudioQueue] Error deleting file $filePath: $e');
    }
  }

  /// Elimina tutti i file audio in coda dal disco e svuota la coda.
  Future<void> clearQueueAndFiles() async {
    final queue = await getQueue();
    for (final item in queue) {
      await deleteFile(item['file_path'] as String?);
    }
    await clearQueue();
  }

  /// Rimuove dalla coda gli item il cui file non esiste più sul disco
  /// (pulizia di sicurezza all'avvio).
  Future<void> pruneOrphanedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    final valid = <Map<String, dynamic>>[];
    for (final item in queue) {
      final path = item['file_path'] as String?;
      if (path != null && File(path).existsSync()) {
        valid.add(item);
      } else {
        debugPrint('[AudioQueue] Pruning orphaned item: $path');
      }
    }
    if (valid.length != queue.length) {
      await prefs.setString(_queueKey, jsonEncode(valid));
    }
  }
}
