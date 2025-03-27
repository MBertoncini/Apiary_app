// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';

/// Servizio per la riproduzione di audio nell'app
class AudioService {
  // Singleton pattern
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Percorsi dei suoni
  static const String _soundStart = 'assets/sounds/start_listening.mp3';
  static const String _soundStop = 'assets/sounds/stop_listening.mp3';
  static const String _soundSuccess = 'assets/sounds/success.mp3';
  static const String _soundError = 'assets/sounds/error.mp3';
  
  // Flag per attivare/disattivare i suoni
  bool _soundEnabled = true;
  
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool value) {
    _soundEnabled = value;
  }
  
  // Riproduci suono di inizio registrazione
  Future<void> playStartSound() async {
    if (!_soundEnabled) return;
    await _playSound(_soundStart);
  }
  
  // Riproduci suono di fine registrazione
  Future<void> playStopSound() async {
    if (!_soundEnabled) return;
    await _playSound(_soundStop);
  }
  
  // Riproduci suono di successo
  Future<void> playSuccessSound() async {
    if (!_soundEnabled) return;
    await _playSound(_soundSuccess);
  }
  
  // Riproduci suono di errore
  Future<void> playErrorSound() async {
    if (!_soundEnabled) return;
    await _playSound(_soundError);
  }
  
  // Metodo helper per riprodurre un suono
  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('Errore nella riproduzione del suono: $e');
    }
  }
  
  // Ripulisci le risorse quando non più necessarie
  void dispose() {
    _audioPlayer.dispose();
  }
}