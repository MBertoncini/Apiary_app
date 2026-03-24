// lib/services/voice_settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la modalità di inserimento vocale scelta dall'utente.
class VoiceSettingsService {
  static const String _modeKey = 'voice_input_mode';

  /// Speech-to-text nativo → testo → Gemini (default storico).
  static const String modeStt = 'stt';

  /// Registrazione audio → Gemini multimodale direttamente.
  static const String modeAudio = 'audio';

  Future<String> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modeKey) ?? modeAudio;
  }

  Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode);
  }
}
