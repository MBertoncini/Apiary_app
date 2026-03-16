// lib/services/voice_queue_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voice_entry.dart';

class VoiceQueueService {
  static const String _queueKey = 'voice_offline_queue';
  static const String _draftKey = 'voice_session_draft';

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

  // ── Session draft (crash recovery) ──────────────────────────────────────
  // The draft stores the in-progress batch transcriptions so that if the app
  // is killed during a long apiary visit the data is not lost.

  /// Persist the current batch transcriptions as a recoverable draft.
  /// Passing an empty list removes any existing draft.
  Future<void> saveDraft(
    List<String> transcriptions,
    int? apiarioId,
    String? apiarioNome,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (transcriptions.isEmpty) {
      await prefs.remove(_draftKey);
      return;
    }
    await prefs.setString(
      _draftKey,
      jsonEncode({
        'transcriptions': transcriptions,
        'apiario_id': apiarioId,
        'apiario_nome': apiarioNome,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Load a previously saved draft, or null if none exists.
  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Delete any existing draft.
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  // ── Verification draft ────────────────────────────────────────────────────
  // Persists VoiceEntry objects that have been processed by Gemini but not yet
  // submitted to the backend.  Saved immediately on entering the verification
  // screen and cleared only after all entries are successfully posted.
  // This ensures that Gemini-processed data (which costs API tokens) is never
  // lost due to network errors, wrong arnia numbers, or app crashes.

  static const String _verificationDraftKey = 'voice_verification_draft';

  /// Persist the list of pending VoiceEntry objects.
  Future<void> saveVerificationDraft(List<VoiceEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await prefs.remove(_verificationDraftKey);
      return;
    }
    await prefs.setString(
      _verificationDraftKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Load previously saved VoiceEntry objects, or empty list if none.
  Future<List<VoiceEntry>> loadVerificationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_verificationDraftKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => VoiceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete the verification draft (call after all entries are submitted).
  Future<void> clearVerificationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verificationDraftKey);
  }
}
