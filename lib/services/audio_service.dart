// lib/services/audio_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioPlayer? _player;
  bool _soundEnabled = true;
  
  // Riferimenti alle risorse audio
  static const String _startSoundPath = 'assets/sounds/start_recording.mp3';
  static const String _stopSoundPath = 'assets/sounds/stop_recording.mp3';
  static const String _successSoundPath = 'assets/sounds/success.mp3';
  static const String _errorSoundPath = 'assets/sounds/error.mp3';
  
  // Getter e setter
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool value) {
    _soundEnabled = value;
  }
  
  AudioService() {
    _initPlayer();
  }
  
  Future<void> _initPlayer() async {
    _player = AudioPlayer();
  }
  
  // Funzione di utilità per riprodurre un suono
  Future<void> _playSound(String assetPath) async {
    if (!_soundEnabled) return;
    
    try {
      if (_player == null) {
        await _initPlayer();
      }
      
      await _player!.stop(); // Ferma qualsiasi riproduzione in corso
      await _player!.play(AssetSource(assetPath));
    } catch (e) {
      print('Errore nella riproduzione del suono: $e');
    }
  }
  
  // Riproduce il suono di inizio ascolto
  Future<void> playStartSound() async {
    await _playSound(_startSoundPath);
  }
  
  // Riproduce il suono di fine ascolto
  Future<void> playStopSound() async {
    await _playSound(_stopSoundPath);
  }
  
  // Riproduce il suono di successo
  Future<void> playSuccessSound() async {
    await _playSound(_successSoundPath);
  }
  
  // Riproduce il suono di errore
  Future<void> playErrorSound() async {
    await _playSound(_errorSoundPath);
  }
  
  // Pulisci le risorse
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}