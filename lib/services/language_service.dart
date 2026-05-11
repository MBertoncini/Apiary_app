// lib/services/language_service.dart
//
// Manages the app language. Persists the selected locale to SharedPreferences
// and notifies listeners (rebuilding the widget tree) when it changes.
//
// To add a new language:
//   1. Create lib/l10n/strings_xx.dart extending AppStrings
//   2. Add a case to _setFromCode()
//   3. Add the locale to supportedLocales and supportedLanguages

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../l10n/strings_it.dart';
import '../l10n/strings_en.dart';

class LanguageService extends ChangeNotifier {
  static const String _prefKey = 'language_code';

  AppStrings _strings = StringsEn();

  LanguageService() {
    _loadSaved();
  }

  /// Current localized strings instance.
  AppStrings get strings => _strings;

  /// Current locale (used by MaterialApp).
  Locale get locale => _strings.locale;

  /// BCP-47 language code of the active language.
  String get currentCode => _strings.locale.languageCode;

  /// All supported locales — keep in sync with [supportedLanguages].
  static const List<Locale> supportedLocales = [
    Locale('it'),
    Locale('en'),
  ];

  /// Human-readable name for each language code, used by the settings picker.
  static const Map<String, String> supportedLanguages = {
    'it': 'Italiano',
    'en': 'English',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Persists [languageCode] and rebuilds the whole UI.
  Future<void> setLanguage(String languageCode) async {
    _setFromCode(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(_prefKey);

    if (code == null) {
      // Primo avvio: prova a rilevare la lingua di sistema per corrispondere
      // alla scheda del Play Store visualizzata dall'utente.
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (supportedLanguages.containsKey(systemLocale)) {
        code = systemLocale;
      } else {
        code = 'en'; // Default internazionale se la lingua di sistema non è supportata
      }
    }

    _setFromCode(code);
    notifyListeners();
  }

  void _setFromCode(String code) {
    switch (code) {
      case 'it':
        _strings = StringsIt();
        break;
      default:
        _strings = StringsEn();
    }
  }
}
