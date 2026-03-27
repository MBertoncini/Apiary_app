// lib/services/ai_quota_local_tracker.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily call counts locally (SharedPreferences) for:
/// - Gemini voice input (client-side calls)
/// - Groq stats NL query
/// Also stores the Groq API key locally.
class AiQuotaLocalTracker {
  static const _voiceDateKey  = 'ai_quota_voice_date';
  static const _voiceCountKey = 'ai_quota_voice_count';
  static const _statsDateKey  = 'ai_quota_stats_date';
  static const _statsCountKey = 'ai_quota_stats_count';
  static const _groqKeyKey    = 'groq_api_key';

  // Serializes concurrent read-modify-write operations to prevent lost updates.
  Future<void> _lock = Future.value();

  Future<T> _run<T>(Future<T> Function() fn) {
    final Completer<void> done = Completer();
    final Future<T> result = _lock.then<T>((_) => fn());
    _lock = done.future;
    result.whenComplete(done.complete);
    return result;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<int> _getCount(String dateKey, String countKey) => _run(() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    if ((prefs.getString(dateKey) ?? '') != today) {
      await prefs.setString(dateKey, today);
      await prefs.setInt(countKey, 0);
      return 0;
    }
    return prefs.getInt(countKey) ?? 0;
  });

  Future<void> _increment(String dateKey, String countKey) => _run(() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    if ((prefs.getString(dateKey) ?? '') != today) {
      await prefs.setString(dateKey, today);
      await prefs.setInt(countKey, 1);
    } else {
      await prefs.setInt(countKey, (prefs.getInt(countKey) ?? 0) + 1);
    }
  });

  Future<int> getVoiceCallsToday() => _getCount(_voiceDateKey, _voiceCountKey);
  Future<void> incrementVoiceCall() => _increment(_voiceDateKey, _voiceCountKey);

  Future<int> getStatsCallsToday() => _getCount(_statsDateKey, _statsCountKey);
  Future<void> incrementStatsCall() => _increment(_statsDateKey, _statsCountKey);

  Future<String> getGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groqKeyKey) ?? '';
  }

  Future<void> setGroqApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.isEmpty) {
      await prefs.remove(_groqKeyKey);
    } else {
      await prefs.setString(_groqKeyKey, key);
    }
  }
}
