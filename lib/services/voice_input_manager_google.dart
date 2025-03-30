// lib/services/voice_input_manager_google.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/voice_entry.dart';
import 'wit_speech_recognition_service.dart';
import 'voice_data_processor.dart';
import 'voice_feedback_service.dart';

// Nota: abbiamo rimosso la definizione di VoiceEntryBatch che ora è importata da models/voice_entry.dart

/// Service che coordina il riconoscimento vocale e l'elaborazione dei dati
class VoiceInputManagerGoogle extends ChangeNotifier {
  final WitSpeechRecognitionService _speechService;
  final VoiceDataProcessor _dataProcessor;
  final VoiceFeedbackService _feedbackService;
  
  VoiceEntryBatch _currentBatch = VoiceEntryBatch();
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isBatchMode = false;
  String? _error;
  Timer? _autoStopTimer;
  
  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isBatchMode => _isBatchMode;
  VoiceEntryBatch get currentBatch => _currentBatch;
  String? get error => _error;
  
  // Constructor
  VoiceInputManagerGoogle(
    this._speechService, 
    this._dataProcessor, {
    VoiceFeedbackService? feedbackService
  }) : _feedbackService = feedbackService ?? VoiceFeedbackService() {
    // Setup listeners
    _speechService.addListener(_onSpeechServiceChanged);
    _dataProcessor.addListener(_onDataProcessorChanged);
  }

  // Listen for changes in the speech service
  void _onSpeechServiceChanged() {
    // Se il servizio vocale ha smesso di ascoltare e noi stavamo ascoltando,
    // elabora la trascrizione
    if (!_speechService.isListening && _isListening && !_isProcessing && 
        _speechService.transcription.isNotEmpty) {
      _processCurrentTranscription();
    }
    
    // Aggiorna il nostro stato di ascolto
    _isListening = _speechService.isListening;
    notifyListeners();
  }
  
  // Listen for changes in the data processor
  void _onDataProcessorChanged() {
    // Aggiorna il nostro stato di errore dal processore di dati
    if (_dataProcessor.error != null) {
      _error = _dataProcessor.error;
      notifyListeners();
    }
  }

  // Inizia l'ascolto
  Future<bool> startListening({bool batchMode = false}) async {
    if (_isListening) return true;
    
    // Verifica e richiede il permesso del microfono
    if (!await _speechService.hasMicrophonePermission()) {
      _error = 'Permesso microfono non concesso';
      notifyListeners();
      _feedbackService.vibrateError();
      return false;
    }
    
    // Cancella eventuali errori precedenti
    _error = null;
    _isBatchMode = batchMode;
    
    // Inizia il batch se in modalità batch
    if (batchMode && _currentBatch.isEmpty) {
      _currentBatch = VoiceEntryBatch();
    }
    
    // Fornisci feedback sonoro/aptico all'inizio dell'ascolto
    await _feedbackService.playListeningStartSound();
    await _feedbackService.vibrateStart();
    
    // Inizia l'ascolto
    final success = await _speechService.startListening();
    
    if (success) {
      _isListening = true;
      
      // In modalità standard, imposta un timeout per interrompere automaticamente dopo 60 secondi
      if (!batchMode) {
        _autoStopTimer?.cancel();
        _autoStopTimer = Timer(Duration(seconds: 60), () {
          if (_isListening) {
            stopListening();
          }
        });
      }
    } else {
      _error = 'Non è stato possibile avviare il riconoscimento vocale';
      _feedbackService.vibrateError();
    }
    
    notifyListeners();
    return success;
  }

  // Interrompi l'ascolto
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _autoStopTimer?.cancel();
    
    // Fornisci feedback sonoro/aptico alla fine dell'ascolto
    await _feedbackService.playListeningStopSound();
    await _feedbackService.vibrateStop();
    
    await _speechService.stopListening();
    _isListening = false;
    
    // Se abbiamo una trascrizione, elaborala
    if (_speechService.transcription.isNotEmpty && !_isProcessing) {
      await _processCurrentTranscription();
    }
    
    notifyListeners();
  }

  // Elabora la trascrizione corrente
  Future<void> _processCurrentTranscription() async {
    final transcription = _speechService.transcription;
    _isProcessing = true;
    notifyListeners();
    
    try {
      if (transcription.isEmpty) {
        // Nessun testo riconosciuto
        _error = 'Non è stato riconosciuto alcun testo. Prova a parlare più chiaramente.';
        await _feedbackService.playErrorSound();
        await _feedbackService.vibrateError();
        return; // Esci dal metodo senza creare una VoiceEntry
      }
      
      // Processa l'input vocale con il data processor
      final entry = await _dataProcessor.processVoiceInput(transcription);
      
      if (entry != null && entry.isValid()) {
        // Feedback positivo
        await _feedbackService.playSuccessSound();
        await _feedbackService.vibrateSuccess();
        
        // Aggiungi al batch corrente
        _currentBatch.add(entry);
        
        // Cancella la trascrizione
        _speechService.clearTranscription();
        
        // Riavvio automatico in modalità batch
        if (_isBatchMode) {
          // Piccolo ritardo per consentire all'utente di prepararsi per il prossimo input
          Future.delayed(Duration(milliseconds: 1500), () {
            if (_isBatchMode) {
              startListening(batchMode: true);
            }
          });
        }
      } else {
        _error = 'Non è stato possibile interpretare il comando vocale';
        await _feedbackService.playErrorSound();
        await _feedbackService.vibrateError();
      }
    } catch (e) {
      _error = 'Errore nel processamento: $e';
      await _feedbackService.playErrorSound();
      await _feedbackService.vibrateError();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// Inizia un nuovo batch di voci vocali
  void startNewBatch() {
    _currentBatch = VoiceEntryBatch();
    notifyListeners();
  }
  
  /// Aggiungi una nuova voce al batch corrente
  void addToBatch(VoiceEntry entry) {
    _currentBatch.add(entry);
    notifyListeners();
  }
  
  /// Rimuovi una voce dal batch corrente
  void removeFromBatch(int index) {
    _currentBatch.remove(index);
    notifyListeners();
  }
  
  /// Cancella il batch corrente
  void clearBatch() {
    _currentBatch.clear();
    notifyListeners();
  }
  
  /// Cancella l'errore corrente
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Ottieni l'ultima trascrizione
  String getTranscription() {
    return _speechService.transcription;
  }
  
  /// Ottieni le trascrizioni parziali (utile per il debug)
  List<String> getPartialTranscripts() {
    return _speechService.partialTranscripts;
  }
  
  /// Cancella la trascrizione corrente
  void clearTranscription() {
    _speechService.clearTranscription();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _speechService.removeListener(_onSpeechServiceChanged);
    _dataProcessor.removeListener(_onDataProcessorChanged);
    _autoStopTimer?.cancel();
    super.dispose();
  }
}