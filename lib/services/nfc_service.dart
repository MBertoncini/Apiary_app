import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  bool _isBackgroundSessionActive = false;

  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Estrae l'ID del tag dai dati grezzi.
  String? _extractTagId(NfcTag tag) {
    final dynamic identifier = 
        tag.data['nfca']?['identifier'] ??
        tag.data['nfcb']?['identifier'] ??
        tag.data['nfcf']?['identifier'] ??
        tag.data['nfcv']?['identifier'] ??
        tag.data['isodep']?['identifier'] ??
        tag.data['mifareclassic']?['identifier'] ??
        tag.data['mifareultralight']?['identifier'] ??
        tag.data['ndefformatable']?['identifier'] ??
        tag.data['mifare']?['identifier'] ??
        tag.data['feliCa']?['identifier'] ??
        tag.data['iso15693']?['identifier'] ??
        tag.data['iso7816']?['identifier'];

    if (identifier != null && identifier is List<int>) {
      return identifier
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase();
    }
    return null;
  }

  /// Avvia la scansione di un tag NFC (singola lettura con timeout).
  Future<String?> scanTag() async {
    final completer = Completer<String?>();

    try {
      final available = await isAvailable();
      if (!available) return null;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final tagId = _extractTagId(tag);
          await NfcManager.instance.stopSession();
          if (!completer.isCompleted) completer.complete(tagId);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () async {
          try {
            await NfcManager.instance.stopSession();
          } catch (_) {}
          return null;
        },
      );
    } catch (e) {
      debugPrint('Errore durante la scansione NFC: $e');
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {}
      return null;
    }
  }

  /// Avvia una sessione di ascolto persistente (per Android).
  Future<void> startBackgroundSession(Function(String) onTagDiscovered) async {
    if (_isBackgroundSessionActive) return;
    
    final available = await isAvailable();
    if (!available) return;

    _isBackgroundSessionActive = true;
    debugPrint('NFC: Avvio sessione persistente');

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final tagId = _extractTagId(tag);
          if (tagId != null) {
            onTagDiscovered(tagId);
          }
          // Su Android, se vogliamo continuare l'ascolto senza chiudere la sessione
          // o se vogliamo gestire letture multiple, nfc_manager a volte richiede
          // lo stop/start o semplicemente non chiamare stopSession.
          // In modalità "background", evitiamo di chiamare stopSession qui
          // a meno che non sia necessario per il plugin.
        },
      );
    } catch (e) {
      debugPrint('Errore NFC Background: $e');
      _isBackgroundSessionActive = false;
    }
  }

  /// Interrompe la sessione di ascolto persistente.
  Future<void> stopBackgroundSession() async {
    if (!_isBackgroundSessionActive) return;
    _isBackgroundSessionActive = false;
    debugPrint('NFC: Interruzione sessione persistente');
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('Errore stop NFC: $e');
    }
  }

  /// Scrive un testo NDEF sul tag.
  Future<bool> writeToTag(String data) async {
    final completer = Completer<bool>();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            await NfcManager.instance.stopSession(errorMessage: 'Tag non scrivibile');
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          final message = NdefMessage([NdefRecord.createText(data)]);
          try {
            await ndef.write(message);
            await NfcManager.instance.stopSession();
            if (!completer.isCompleted) completer.complete(true);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: 'Errore scrittura');
            if (!completer.isCompleted) completer.complete(false);
          }
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () async {
          try {
            await NfcManager.instance.stopSession();
          } catch (_) {}
          return false;
        },
      );
    } catch (e) {
      debugPrint('Errore scrittura NFC: $e');
      return false;
    }
  }
}
