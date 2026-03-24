// lib/services/audio_recorder_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Gestisce la registrazione audio tramite flutter_sound.
/// Produce file AAC nel directory temporanea del dispositivo.
class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;
  String? _currentPath;

  bool get isRecording => _recorder.isRecording;

  Future<bool> _init() async {
    if (_isInitialized) return true;
    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(
          const Duration(milliseconds: 200));
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[AudioRecorder] init error: $e');
      return false;
    }
  }

  Future<bool> hasMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Avvia la registrazione. Restituisce true se avviata con successo.
  /// I file vengono salvati nella directory documenti (non nella temp)
  /// così sopravvivono ai riavvii dell'app finché non vengono eliminati
  /// esplicitamente dopo il salvataggio nel DB.
  Future<bool> startRecording() async {
    if (!await hasMicPermission()) return false;
    if (!await _init()) return false;
    if (_recorder.isRecording) return true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/apiary_voice_recordings');
      if (!folder.existsSync()) folder.createSync(recursive: true);
      _currentPath =
          '${folder.path}/apiary_voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(
        toFile: _currentPath,
        codec: Codec.aacADTS,
        bitRate: 64000,
        sampleRate: 16000,
      );
      debugPrint('[AudioRecorder] Recording started: $_currentPath');
      return true;
    } catch (e) {
      debugPrint('[AudioRecorder] startRecording error: $e');
      return false;
    }
  }

  /// Ferma la registrazione e restituisce il path del file.
  Future<String?> stopRecording() async {
    if (!_recorder.isRecording) return _currentPath;
    try {
      final path = await _recorder.stopRecorder();
      debugPrint('[AudioRecorder] Recording stopped: ${path ?? _currentPath}');
      return path ?? _currentPath;
    } catch (e) {
      debugPrint('[AudioRecorder] stopRecording error: $e');
      return _currentPath;
    }
  }

  Future<void> dispose() async {
    try {
      if (_recorder.isRecording) await _recorder.stopRecorder();
      await _recorder.closeRecorder();
    } catch (e) {
      debugPrint('[AudioRecorder] dispose error: $e');
    }
    _isInitialized = false;
  }
}
