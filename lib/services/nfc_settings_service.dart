// lib/services/nfc_settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la modalità di azione NFC scelta dall'utente.
class NfcSettingsService {
  static const String _actionKey = 'nfc_action_mode';

  /// Apre il form di controllo manuale (default storico).
  static const String actionManual = 'manual';

  /// Avvia il controllo vocale con il numero arnia pre-impostato.
  static const String actionVoice = 'voice';

  Future<String> getAction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_actionKey) ?? actionManual;
  }

  Future<void> setAction(String action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_actionKey, action);
  }
}
