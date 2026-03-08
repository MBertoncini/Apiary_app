// lib/services/voice_feedback_service.dart
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../widgets/voice_animations.dart';
import 'audio_service.dart';

/// Servizio per fornire feedback visivo, sonoro e tattile durante l'input vocale
class VoiceFeedbackService {
  // Singleton pattern
  static final VoiceFeedbackService _instance = VoiceFeedbackService._internal();
  factory VoiceFeedbackService() => _instance;
  
  // Servizio audio per i suoni
  final AudioService _audioService = AudioService();
  
  // Flag per controllare se la vibrazione è abilitata
  bool _vibrationEnabled = true;
  
  // Costruttore private
  VoiceFeedbackService._internal();
  
  // Getter e setter
  bool get vibrationEnabled => _vibrationEnabled;
  set vibrationEnabled(bool value) {
    _vibrationEnabled = value;
  }
  
  bool get soundEnabled => _audioService.soundEnabled;
  set soundEnabled(bool value) {
    _audioService.soundEnabled = value;
  }
  
  // Inizializzazione
  Future<void> initialize() async {
    // Verifica se la vibrazione è supportata
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    _vibrationEnabled = hasVibrator;
  }
  
  // === METODI PER VIBRAZIONE ===
  
  // Vibra quando inizia l'ascolto
  Future<void> vibrateStart() async {
    if (!_vibrationEnabled) return;
    try {
      Vibration.vibrate(duration: 100);
    } catch (e) {
      debugPrint('Errore nella vibrazione: $e');
    }
  }
  
  // Vibra quando termina l'ascolto
  Future<void> vibrateStop() async {
    if (!_vibrationEnabled) return;
    try {
      Vibration.vibrate(duration: 50);
    } catch (e) {
      debugPrint('Errore nella vibrazione: $e');
    }
  }
  
  // Vibra per feedback di successo
  Future<void> vibrateSuccess() async {
    if (!_vibrationEnabled) return;
    try {
      Vibration.vibrate(pattern: [0, 50, 100, 50]);
    } catch (e) {
      debugPrint('Errore nella vibrazione: $e');
    }
  }
  
  // Vibra per feedback di errore
  Future<void> vibrateError() async {
    if (!_vibrationEnabled) return;
    try {
      Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
    } catch (e) {
      debugPrint('Errore nella vibrazione: $e');
    }
  }
  
  // === METODI PER SUONI ===
  
  // Suono quando inizia l'ascolto
  Future<void> playListeningStartSound() async {
    try {
      await _audioService.playStartSound();
    } catch (e) {
      debugPrint('Errore nella riproduzione del suono di avvio: $e');
    }
  }

  Future<void> playListeningStopSound() async {
    try {
      await _audioService.playStopSound();
    } catch (e) {
      // Ignoriamo l'errore se il file non esiste invece di stamparlo
      // Questo è un workaround fino a quando non vengono aggiunti i file audio
      if (!e.toString().contains('Unable to load asset')) {
        debugPrint('Errore nella riproduzione del suono di stop: $e');
      }
    }
  }
  
  // Suono per feedback di successo
  Future<void> playSuccessSound() async {
    try {
      await _audioService.playSuccessSound();
    } catch (e) {
      // Ignoriamo l'errore se il file non esiste
      if (!e.toString().contains('Unable to load asset')) {
        debugPrint('Errore nella riproduzione del suono di successo: $e');
      }
    }
  }
  
  // Suono per feedback di errore
  Future<void> playErrorSound() async {
    try {
      await _audioService.playErrorSound();
    } catch (e) {
      // Ignoriamo l'errore se il file non esiste
      if (!e.toString().contains('Unable to load asset')) {
        debugPrint('Errore nella riproduzione del suono di errore: $e');
      }
    }
  }
  
  // === METODI PER COMPONENTI VISUALI ===

  Widget buildAnimatedMicButton({
    required bool isListening,
    required bool isProcessing,
    required VoidCallback onPressed,
  }) {
    return VoiceMicButton(
      isListening: isListening,
      isProcessing: isProcessing,
      onPressed: onPressed,
    );
  }

  Widget buildPulsingAnimation(bool isActive) {
    return VoicePulsingRings(isActive: isActive);
  }

  Widget buildWaveformAnimation(bool isActive) {
    return VoiceWaveform(isActive: isActive);
  }
}