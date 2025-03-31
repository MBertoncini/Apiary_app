// lib/services/voice_feedback_service.dart
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
                : Icon(
                    isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: isListening ? 40 : 32,
                    key: ValueKey<bool>(isListening),
                  ),
          ),
        ),
      ),
    );
  }

  // Widget per l'animazione di pulsazione
  Widget buildPulsingAnimation(bool isActive) {
    if (!isActive) return SizedBox.shrink();
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // Widget per l'animazione della forma d'onda
  Widget buildWaveformAnimation(bool isActive) {
    if (!isActive) return SizedBox.shrink();
    
    return Container(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          9,
          (index) => _buildWaveBar(index % 3 == 0 ? 1.0 : 0.7),
        ),
      ),
    );
  }
  
  // Helper per costruire una barra della forma d'onda
  Widget _buildWaveBar(double heightFactor) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (300 * heightFactor).toInt()),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 2),
      width: 4,
      height: 30 * heightFactor,
      decoration: BoxDecoration(
        color: ThemeConstants.primaryColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}