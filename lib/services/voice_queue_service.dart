// lib/services/voice_queue_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceQueueService {
  static const String _queueKey = 'voice_offline_queue';

  Future<void> addToQueue(
      String transcription, int? apiarioId, String? apiarioNome) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    queue.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'transcription': transcription,
      'apiario_id': apiarioId,
      'apiario_nome': apiarioNome,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  Future<int> getQueueCount() async {
    final queue = await getQueue();
    return queue.length;
  }

  /// Save a list of raw transcriptions to the queue as backup.
  /// Returns the generated IDs so the caller can remove them later on success.
  Future<List<String>> addBatchToQueue(
    List<String> transcriptions,
    int? apiarioId,
    String? apiarioNome,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    final ids = <String>[];
    final now = DateTime.now();
    for (int i = 0; i < transcriptions.length; i++) {
      final id = '${now.millisecondsSinceEpoch}_$i';
      ids.add(id);
      queue.add({
        'id': id,
        'transcription': transcriptions[i],
        'apiario_id': apiarioId,
        'apiario_nome': apiarioNome,
        'timestamp': now.toIso8601String(),
      });
    }
    await prefs.setString(_queueKey, jsonEncode(queue));
    return ids;
  }

  /// Remove a specific item from the queue by its ID.
  Future<void> removeFromQueue(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    queue.removeWhere((item) => item['id'] == id);
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Remove multiple items by their IDs.
  Future<void> removeItemsFromQueue(List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    final idSet = ids.toSet();
    queue.removeWhere((item) => idSet.contains(item['id']));
    await prefs.setString(_queueKey, jsonEncode(queue));
  }
}
