// lib/services/voice_input_manager_google.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/voice_entry.dart';
import 'google_speech_recognition_service.dart';
import 'voice_data_processor.dart';
import 'voice_feedback_service.dart';

/// Service that coordinates Google speech recognition and data processing
class VoiceInputManagerGoogle with ChangeNotifier {
  final GoogleSpeechRecognitionService _speechService;
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
    await _speechService.stopListening();
    _isListening = false;
    
    // If we have a transcription, process it
    if (_speechService.transcription.isNotEmpty && !_isProcessing) {
      await _processCurrentTranscription();
    }
    
    notifyListeners();
  }

  // Process the current transcription
  Future<void> _processCurrentTranscription() async {
    final transcription = _speechService.transcription;
    if (transcription.isEmpty) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Process voice input with Gemini
      final entry = await _dataProcessor.processVoiceInput(transcription);
      
      if (entry != null && entry.isValid()) {
        // Positive feedback
        _feedbackService.vibrateSuccess();
        
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
        _feedbackService.vibrateError();
      }
    } catch (e) {
      _error = 'Errore nel processamento: $e';
      _feedbackService.vibrateError();
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
  
  @override
  void dispose() {
    _speechService.removeListener(_onSpeechServiceChanged);
    _dataProcessor.removeListener(_onDataProcessorChanged);
    _autoStopTimer?.cancel();
    super.dispose();
  }

    /// Cancella la trascrizione corrente
  void clearTranscription() {
    _speechService.clearTranscription();
    notifyListeners();
  }
}