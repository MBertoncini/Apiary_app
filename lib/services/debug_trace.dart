// lib/services/debug_trace.dart
import 'package:flutter/foundation.dart';

/// Tracer diagnostico visibile in-UI.
/// Usato quando logcat è filtrato dal vendor (Honor/MagicOS) e i
/// `debugPrint`/`flutter logs` non vengono recapitati.
///
/// TEMPORANEO: rimuovere quando il bug voice→Gemini è risolto e i log
/// del dispositivo tornano affidabili.
class DebugTrace extends ChangeNotifier {
  static final DebugTrace instance = DebugTrace._();
  DebugTrace._();

  static const int _maxEntries = 40;
  final List<String> _entries = [];

  List<String> get entries => List.unmodifiable(_entries);

  static void log(String msg) {
    final t = DateTime.now();
    final stamp = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
    instance._entries.add('$stamp  $msg');
    if (instance._entries.length > _maxEntries) {
      instance._entries.removeAt(0);
    }
    instance.notifyListeners();
    debugPrint('[TRACE] $msg');
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
