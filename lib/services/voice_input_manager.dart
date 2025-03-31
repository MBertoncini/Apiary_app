// lib/services/voice_input_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/voice_entry.dart';
import 'wit_speech_recognition_service.dart';
import 'voice_data_processor.dart';
import 'voice_feedback_service.dart';

/// Service that coordinates speech recognition and data processing
class VoiceInputManager with ChangeNotifier {
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
  VoiceInputManager(
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
    // If the speech service stopped listening and we were listening,
    // process the transcription
    if (!_speechService.isListening && _isListening && !_isProcessing && 
        _speechService.transcription.isNotEmpty) {
      _processCurrentTranscription();
    }
    
    // Update our listening state
    _isListening = _speechService.isListening;
    notifyListeners();
  }
  
  // Listen for changes in the data processor
  void _onDataProcessorChanged() {
    // Update our error state from the data processor
    if (_dataProcessor.error != null) {
      _error = _dataProcessor.error;
      notifyListeners();
    }
  }

  // Start listening
  Future<bool> startListening({bool batchMode = false}) async {
    if (_isListening) return true;
    
    // Check and request microphone permission
    if (!await _speechService.hasMicrophonePermission()) {
      _error = 'Permesso microfono non concesso';
      notifyListeners();
      _feedbackService.vibrateError();
      return false;
    }
    
    // Clear any previous errors
    _error = null;
    _isBatchMode = batchMode;
    
    // Start batch if in batch mode
    if (batchMode && _currentBatch.isEmpty) {
      _currentBatch = VoiceEntryBatch();
    }
    
    // Provide audio/haptic feedback when starting listening
    await _feedbackService.playListeningStartSound();
    await _feedbackService.vibrateStart();
    
    // Start listening
    final success = await _speechService.startListening();
    
    if (success) {
      _isListening = true;
      
      // In standard mode, set a timeout to auto-stop after 60 seconds
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

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _autoStopTimer?.cancel();
    
    // Provide audio/haptic feedback when stopping listening
    await _feedbackService.playListeningStopSound();
    await _feedbackService.vibrateStop();
    
    await _speechService.stopListening();
    _isListening = false;
    
    // If we have a transcription, process it
    if (_speechService.transcription.isNotEmpty && !_isProcessing) {
      await _processCurrentTranscription();
    } else if (_speechService.transcription.isEmpty) {
      // No text recognized
      _error = 'Non è stato riconosciuto alcun testo. Prova a parlare più chiaramente.';
      await _feedbackService.playErrorSound();
      await _feedbackService.vibrateError();
      notifyListeners();
    }
  }

  // Process the current transcription
  Future<void> _processCurrentTranscription() async {
    final transcription = _speechService.transcription;
    _isProcessing = true;
    notifyListeners();
    
    try {
      if (transcription.isEmpty) {
        // No recognized text
        _error = 'Non è stato riconosciuto alcun testo. Prova a parlare più chiaramente.';
        await _feedbackService.playErrorSound();
        await _feedbackService.vibrateError();
        _isProcessing = false;
        notifyListeners();
        return; // Exit the method without creating a VoiceEntry
      }
      
      // Process voice input with data processor
      final entry = await _dataProcessor.processVoiceInput(transcription);
      
      if (entry != null && entry.isValid()) {
        // Positive feedback
        await _feedbackService.playSuccessSound();
        await _feedbackService.vibrateSuccess();
        
        // Add to current batch
        _currentBatch.add(entry);
        
        // Clear transcription
        _speechService.clearTranscription();
        
        // Automatic restart in batch mode
        if (_isBatchMode) {
          // Small delay to allow user to prepare for next input
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
  
  /// Begin a new batch of voice entries
  void startNewBatch() {
    _currentBatch = VoiceEntryBatch();
    notifyListeners();
  }
  
  /// Add a new entry to the current batch
  void addToBatch(VoiceEntry entry) {
    _currentBatch.add(entry);
    notifyListeners();
  }
  
  /// Remove an entry from the current batch
  void removeFromBatch(int index) {
    _currentBatch.remove(index);
    notifyListeners();
  }
  
  /// Clear the current batch
  void clearBatch() {
    _currentBatch.clear();
    notifyListeners();
  }
  
  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Get the latest transcription
  String getTranscription() {
    return _speechService.transcription;
  }
  
  /// Get partial transcripts (useful for debugging)
  List<String> getPartialTranscripts() {
    return _speechService.partialTranscripts;
  }
  
  /// Clear the current transcription
  void clearTranscription() {
    _speechService.clearTranscription();
    notifyListeners();
  }
  
  // Try to recover from errors by resetting the speech service
  Future<void> resetSpeechService() async {
    try {
      _isListening = false;
      _isProcessing = false;
      _error = null;
      
      // Try to reset the speech service
      if (_speechService is WitSpeechRecognitionService) {
        await (_speechService as WitSpeechRecognitionService).resetRecorder();
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Errore nel reset del servizio vocale: $e';
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _speechService.removeListener(_onSpeechServiceChanged);
    _dataProcessor.removeListener(_onDataProcessorChanged);
    _autoStopTimer?.cancel();
    super.dispose();
  }
}