// lib/services/audio_service.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  
  // Singleton pattern
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();
  
  // Getter e setter
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool value) {
    _soundEnabled = value;
  }
  
  // Percorsi file audio corretti, senza duplicazione "assets/"
  static const String _startSoundPath = 'sounds/start_recording.mp3';
  static const String _stopSoundPath = 'sounds/stop_recording.mp3';
  static const String _successSoundPath = 'sounds/success.mp3';
  static const String _errorSoundPath = 'sounds/error.mp3';
  
  Future<void> _playSound(String soundPath) async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      debugPrint('Errore nella riproduzione del suono: $e');
    }
  }
  
  Future<void> playStartSound() async {
    await _playSound(_startSoundPath);
  }
  
  Future<void> playStopSound() async {
    await _playSound(_stopSoundPath);
  }
  
  Future<void> playSuccessSound() async {
    await _playSound(_successSoundPath);
  }
  
  Future<void> playErrorSound() async {
    await _playSound(_errorSoundPath);
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}