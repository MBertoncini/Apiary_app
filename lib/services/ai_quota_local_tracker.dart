// lib/services/ai_quota_local_tracker.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Storage locale della chiave API Groq personale dell'utente.
///
/// **Nota storica**: questa classe tracciava anche i contatori giornalieri
/// di chiamate voice/stats come gate offline. Il tracking è stato
/// centralizzato in [AiQuotaService] (che integra backend + overlay
/// ottimistico locale), quindi qui rimane solo la persistenza della chiave
/// Groq personale per il proxy NL query.
class AiQuotaLocalTracker {
  static const _groqKeyKey = 'groq_api_key';

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
