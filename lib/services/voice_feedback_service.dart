// lib/services/voice_feedback_service_updated.dart
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../constants/theme_constants.dart';
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
      print('Errore nella vibrazione: $e');
    }
  }
  
  // Vibra quando termina l'ascolto
  Future<void> vibrateStop() async {
    if (!_vibrationEnabled) return;
    try {
      Vibration.vibrate(duration: 50);
    } catch (e) {
      print('Errore nella vibrazione: $e');
    }
  }
  
  // Vibra per feedback di successo
  Future<void> vibrateSuccess() async {
    if (!_vibrationEnabled) return;
    try {
      Vibration.vibrate(pattern: [0, 50, 100, 50]);
    } catch (e) {
      print('Errore nella vibrazione: $e');
    }
  }
  
  // Vibra per feedback di errore
  Future<void> vibrateError() async {
    if (!_vibrationEnabled) return;
    try {
      Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
    } catch (e) {
      print('Errore nella vibrazione: $e');
    }
  }
  
  // === METODI PER SUONI ===
  
  // Suono quando inizia l'ascolto
  Future<void> playListeningStartSound() async {
    await _audioService.playStartSound();
  }
  
  // Suono quando termina l'ascolto
  Future<void> playListeningStopSound() async {
    await _audioService.playStopSound();
  }
  
  // Suono per feedback di successo
  Future<void> playSuccessSound() async {
    await _audioService.playSuccessSound();
  }
  
  // Suono per feedback di errore
  Future<void> playErrorSound() async {
    await _audioService.playErrorSound();
  }
  
  // === METODI PER COMPONENTI VISUALI ===
  
  // Widget animato per il pulsante del microfono
  Widget buildAnimatedMicButton({
    required bool isListening,
    required bool isProcessing,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: isListening ? 100 : 80,
        height: isListening ? 100 : 80,
        decoration: BoxDecoration(
          color: isProcessing 
              ? Colors.orange 
              : (isListening ? Colors.red : ThemeConstants.primaryColor),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isListening 
                  ? Colors.red.withOpacity(0.5) 
                  : ThemeConstants.primaryColor.withOpacity(0.3),
              spreadRadius: isListening ? 4 : 2,
              blurRadius: isListening ? 8 : 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: isProcessing
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  )