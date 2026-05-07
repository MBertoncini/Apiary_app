import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Avvia la scansione di un tag NFC.
  /// Ritorna l'ID del tag (stringa esadecimale) o null se annullato/errore.
  Future<String?> scanTag() async {
    final completer = Completer<String?>();

    try {
      final available = await NfcManager.instance.isAvailable();
      if (!available) {
        debugPrint('NFC non disponibile');
        return null;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final identifier = tag.data['nfca']?['identifier'] ??
              tag.data['mifareultralight']?['identifier'] ??
              tag.data['ndefformatable']?['identifier'];

          String? tagId;
          if (identifier != null) {
            tagId = (identifier as List<int>)
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':')
                .toUpperCase();
          }

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
