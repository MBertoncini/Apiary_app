// lib/services/platform_voice_input_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/voice_entry.dart';
import 'platform_speech_service.dart';
import 'voice_data_processor.dart';
import 'voice_feedback_service.dart';
import 'bee_vocabulary_corrector.dart';

/// Gestore di input vocale che utilizza il riconoscimento vocale nativo della piattaforma
class PlatformVoiceInputManager with ChangeNotifier {
  final PlatformSpeechService _speechService;
  final VoiceDataProcessor _dataProcessor;
  final VoiceFeedbackService _feedbackService;
  
  VoiceEntryBatch _currentBatch = VoiceEntryBatch();
  /// Raw transcriptions collected during a batch session.
  /// Gemini is called only when the user explicitly presses "Verifica".
  final List<String> _pendingTranscriptions = [];
  /// Transcriptions that could not be processed in the last batch run
  /// (rate limit, network error, or invalid Gemini response).
  /// The caller should save these to the offline queue.
  final List<String> _lastBatchFailedTranscriptions = [];
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isBatchMode = false;
  bool _isAwaitingTrigger = false;
  bool _batchStopRequested = false;
  String? _error;
  String? _failedTranscription; // preserves text when Gemini fails in single mode
  Timer? _autoStopTimer;
  Timer? _triggerRestartTimer;

  // ── Continuous listening buffer ──────────────────────────────────────────
  // On Android the OS speech engine has a hard ~1.5 s VAD that ignores
  // pauseFor.  We accumulate chunks here and restart the engine silently
  // until the user presses stop or two consecutive sessions return silence.
  String _continuousBuffer = '';
  int _silentRestartCount = 0;
  static const int _maxSilentRestarts = 2;
  bool _handlingEngineStop = false; // debounce guard

  /// Words that activate the next recording in batch mode.
  static const List<String> _triggerWords = [
    'avanti', 'prossima', 'ok', 'okay', 'vai', 'continua',
    'registra', 'pronto', 'sì', 'si', 'inizia', 'next',
  ];

  /// Words that end the current batch entirely.
  static const List<String> _stopWords = [
    'stop', 'fine', 'finito', 'basta', 'termina', 'ho finito',
  ];

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isBatchMode => _isBatchMode;
  bool get isAwaitingTrigger => _isAwaitingTrigger;
  bool get batchStopRequested => _batchStopRequested;
  VoiceEntryBatch get currentBatch => _currentBatch;
  List<String> get pendingTranscriptions =>
      List.unmodifiable(_pendingTranscriptions);
  /// Transcriptions that failed in the last [processPendingBatch] call.
  /// Non-empty when Gemini returned null for some items (rate limit, network
  /// error, or unparseable response). The caller must save these to the
  /// offline queue to prevent data loss.
  List<String> get lastBatchFailedTranscriptions =>
      List.unmodifiable(_lastBatchFailedTranscriptions);
  String? get error => _error;
  
  // Constructor
  PlatformVoiceInputManager(
    this._speechService, 
    this._dataProcessor, {
    VoiceFeedbackService? feedbackService
  }) : _feedbackService = feedbackService ?? VoiceFeedbackService() {
    // Setup listeners
    _speechService.addListener(_onSpeechServiceChanged);
    _dataProcessor.addListener(_onDataProcessorChanged);
  }

  // ── Speech service change listener ───────────────────────────────────────

  void _onSpeechServiceChanged() {
    // Trigger mode: listening for a wake word only
    if (_isAwaitingTrigger) {
      _handleTriggerStateChange();
      return;
    }

    // Error — abort continuous session
    if (_speechService.error != null) {
      _error = _speechService.error;
      _isListening = false;
      _continuousBuffer = '';
      _silentRestartCount = 0;
      _handlingEngineStop = false;
      notifyListeners();
      return;
    }

    // Continuous mode: engine stopped while manager still wants to listen
    if (_isListening && !_speechService.isListening && !_isProcessing &&
        !_handlingEngineStop) {
      _handlingEngineStop = true;
      Future.microtask(_onEngineStoppedWhileListening);
      return;
    }

    notifyListeners();
  }

  // ── Continuous listening ──────────────────────────────────────────────────

  Future<void> _onEngineStoppedWhileListening() async {
    // Do NOT reset _handlingEngineStop here — keep it true until this
    // function is done (including restart) so that late results arriving
    // from the old session cannot trigger a second concurrent invocation.
    if (!_isListening || _isProcessing) {
      _handlingEngineStop = false;
      return; // state changed while pending
    }

    // Android often delivers the last partial/final result a few milliseconds
    // AFTER the engine fires its stop/timeout event.  Waiting here gives the
    // platform channel time to flush that pending result into _transcription
    // before we read it, preventing the last word from being silently dropped.
    await Future.delayed(const Duration(milliseconds: 250));
    if (!_isListening || _isProcessing) {
      _handlingEngineStop = false;
      return; // re-check after the wait
    }

    final chunk = _speechService.transcription.trim();

    if (chunk.isNotEmpty) {
      // Got a speech chunk — accumulate and restart engine silently
      _continuousBuffer =
          _continuousBuffer.isEmpty ? chunk : '$_continuousBuffer $chunk';
      _speechService.clearTranscription();
      _silentRestartCount = 0;
      notifyListeners(); // update transcription box in real-time
      debugPrint('[VoiceManager] Chunk: "$chunk" | buffer: "$_continuousBuffer"');
      // Small delay so Android engine fully shuts down before re-opening
      // (avoids error_client on rapid restart)
      await Future.delayed(const Duration(milliseconds: 400));
      _handlingEngineStop = false; // allow next stop event to be handled
      if (_isListening) await _speechService.startListening();
    } else {
      // Silence — check if user is done
      _silentRestartCount++;
      debugPrint('[VoiceManager] Silent restart #$_silentRestartCount');
      if (_silentRestartCount <= _maxSilentRestarts) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 400));
        _handlingEngineStop = false;
        if (_isListening) await _speechService.startListening();
      } else {
        _handlingEngineStop = false;
        await _finalizeListeningSession();
      }
    }
  }

  Future<void> _finalizeListeningSession() async {
    final accumulated = _continuousBuffer.trim();
    _isListening = false;
    _continuousBuffer = '';
    _silentRestartCount = 0;
    notifyListeners();

    if (accumulated.isNotEmpty && !_isProcessing) {
      await _processText(accumulated);
    } else if (accumulated.isEmpty && !_isProcessing) {
      _error = 'Non è stato riconosciuto alcun testo. Prova a parlare più chiaramente.';
      try {
        await _feedbackService.playErrorSound();
        await _feedbackService.vibrateError();
      } catch (_) {}
      notifyListeners();
    }
  }

  // ── Trigger-word detection ────────────────────────────────────────────────

  void _handleTriggerStateChange() {
    final text = _speechService.transcription.toLowerCase().trim();

    // Check stop words first — ends the batch entirely
    if (text.isNotEmpty && _stopWords.any((w) => text.contains(w))) {
      debugPrint('[VoiceManager] Stop word detected: "$text"');
      _isAwaitingTrigger = false;
      _isBatchMode = false;
      _batchStopRequested = true;
      _triggerRestartTimer?.cancel();
      _speechService.stopListening();
      _speechService.clearTranscription();
      notifyListeners();
      return;
    }

    // Check next-trigger words — start recording the next arnia
    if (text.isNotEmpty && _triggerWords.any((w) => text.contains(w))) {
      debugPrint('[VoiceManager] Trigger detected: "$text"');
      _isAwaitingTrigger = false;
      _triggerRestartTimer?.cancel();
      _speechService.stopListening();
      _speechService.clearTranscription();
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!_isAwaitingTrigger && _isBatchMode) startListening(batchMode: true);
      });
      return;
    }

    // Session ended without a recognised word — restart trigger listen
    if (!_speechService.isListening) {
      _speechService.clearTranscription();
      _triggerRestartTimer?.cancel();
      _triggerRestartTimer = Timer(const Duration(milliseconds: 700), () {
        if (_isAwaitingTrigger && _isBatchMode) _doTriggerListen();
      });
      notifyListeners();
    }
  }

  Future<void> _doTriggerListen() async {
    if (!_isAwaitingTrigger || !_isBatchMode) return;
    try {
      await _speechService.startListeningForTrigger();
    } catch (e) {
      debugPrint('[VoiceManager] Error starting trigger listen: $e');
      _triggerRestartTimer = Timer(const Duration(seconds: 2), () {
        if (_isAwaitingTrigger) _doTriggerListen();
      });
    }
  }

  void _startTriggerMode() {
    if (!_isBatchMode) return;
    _isAwaitingTrigger = true;
    notifyListeners();
    // Small pause to let feedback sounds finish before opening the mic
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_isAwaitingTrigger) _doTriggerListen();
    });
  }

  /// Cancel trigger mode (e.g. user wants to stop the batch entirely).
  void cancelTriggerMode() {
    _isAwaitingTrigger = false;
    _triggerRestartTimer?.cancel();
    if (_speechService.isListening) _speechService.stopListening();
    notifyListeners();
  }

  /// Disable batch mode and stop any active listening/trigger session.
  void exitBatchMode() {
    _isBatchMode = false;
    _isAwaitingTrigger = false;
    _triggerRestartTimer?.cancel();
    if (_isListening || _speechService.isListening) _speechService.stopListening();
    _isListening = false;
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

    // If we were waiting for a trigger word, cancel that session first
    if (_isAwaitingTrigger) {
      _isAwaitingTrigger = false;
      _triggerRestartTimer?.cancel();
      if (_speechService.isListening) {
        await _speechService.stopListening();
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    // Check and request microphone permission
    if (!await _speechService.hasMicrophonePermission()) {
      _error = 'Permesso microfono non concesso';
      notifyListeners();
      try {
        await _feedbackService.vibrateError();
      } catch (e) {
        debugPrint('Errore durante la vibrazione: $e');
      }
      return false;
    }
    
    // Clear any previous errors, continuous buffer and preserved failure text
    _error = null;
    _continuousBuffer = '';
    _silentRestartCount = 0;
    _failedTranscription = null;
    _isBatchMode = batchMode;

    // Start batch if in batch mode
    if (batchMode && _currentBatch.isEmpty) {
      _currentBatch = VoiceEntryBatch();
    }
    
    // Provide audio/haptic feedback when starting listening
    try {
      await _feedbackService.playListeningStartSound();
      await _feedbackService.vibrateStart();
    } catch (e) {
      debugPrint('Errore durante il feedback: $e');
      // Continue even if feedback fails
    }
    
    // Start listening
    final success = await _speechService.startListening();
    
    if (success) {
      _isListening = true;
      
      // In standard mode, set a timeout to auto-stop after 30 seconds
      if (!batchMode) {
        _autoStopTimer?.cancel();
        _autoStopTimer = Timer(Duration(seconds: 30), () {
          if (_isListening) {
            stopListening();
          }
        });
      }
    } else {
      _error = _speechService.error ?? 'Non è stato possibile avviare il riconoscimento vocale';
      try {
        await _feedbackService.vibrateError();
      } catch (e) {
        debugPrint('Errore durante la vibrazione: $e');
      }
    }
    
    notifyListeners();
    return success;
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isAwaitingTrigger) {
      cancelTriggerMode();
      return;
    }
    if (!_isListening) return;

    _autoStopTimer?.cancel();
    _isListening = false;
    _handlingEngineStop = false;

    try {
      await _feedbackService.playListeningStopSound();
      await _feedbackService.vibrateStop();
    } catch (e) {
      debugPrint('Errore durante il feedback di stop: $e');
    }

    await _speechService.stopListening();

    // Give the engine a brief moment to deliver the final result after stop().
    // On Android the last word is often still "in flight" when stop() returns.
    await Future.delayed(const Duration(milliseconds: 300));

    // Combine whatever was in the buffer with any in-flight transcription
    final current = _speechService.transcription.trim();
    final accumulated = _continuousBuffer.isEmpty
        ? current
        : current.isEmpty
            ? _continuousBuffer
            : '$_continuousBuffer $current';
    _continuousBuffer = '';
    _silentRestartCount = 0;

    if (accumulated.isNotEmpty && !_isProcessing) {
      await _processText(accumulated);
    } else if (accumulated.isEmpty) {
      _error = 'Non è stato riconosciuto alcun testo. Prova a parlare più chiaramente.';
      try {
        await _feedbackService.playErrorSound();
        await _feedbackService.vibrateError();
      } catch (e) {
        debugPrint('Errore durante il feedback di errore: $e');
      }
      notifyListeners();
    }
  }

  /// Route a completed transcription either to the pending queue (batch mode)
  /// or directly to Gemini (single mode).
  Future<void> _processText(String transcription) async {
    if (transcription.isEmpty) return;

    // Apply vocabulary correction before any downstream processing.
    final corrected = BeeVocabularyCorrector().correctText(transcription);

    if (_isBatchMode) {
      // ── Batch mode: queue corrected text, no Gemini call yet ────────────
      _pendingTranscriptions.add(corrected);
      _speechService.clearTranscription();
      debugPrint('[VoiceManager] Queued transcription #${_pendingTranscriptions.length}: "$transcription"');
      try {
        await _feedbackService.playSuccessSound();
        await _feedbackService.vibrateSuccess();
      } catch (_) {}
      notifyListeners();
      _startTriggerMode();
      return;
    }

    // ── Single mode: process immediately through Gemini ──────────────────
    _isProcessing = true;
    notifyListeners();

    try {
      final entry = await _dataProcessor.processVoiceInput(corrected);

      if (entry != null && entry.isValid()) {
        try {
          await _feedbackService.playSuccessSound();
          await _feedbackService.vibrateSuccess();
        } catch (_) {}
        _currentBatch.add(entry);
        _failedTranscription = null;
        _speechService.clearTranscription();
      } else {
        // Preserve corrected transcription so "Salva per dopo" can access it
        _failedTranscription = corrected;
        _error ??= 'Non è stato possibile interpretare il comando vocale';
        try {
          await _feedbackService.playErrorSound();
          await _feedbackService.vibrateError();
        } catch (_) {}
      }
    } catch (e) {
      // Preserve corrected transcription so "Salva per dopo" can access it
      _failedTranscription = corrected;
      _error = 'Errore nel processamento: $e';
      try {
        await _feedbackService.playErrorSound();
        await _feedbackService.vibrateError();
      } catch (_) {}
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Process all queued batch transcriptions through Gemini.
  /// Returns the populated [VoiceEntryBatch] for navigation to the
  /// verification screen.
  ///
  /// After this call, check [lastBatchFailedTranscriptions]: if non-empty,
  /// those items could not be processed (rate limit / network / bad response)
  /// and MUST be saved to the offline queue by the caller to avoid data loss.
  Future<VoiceEntryBatch> processPendingBatch() async {
    if (_pendingTranscriptions.isEmpty) return _currentBatch;

    final toProcess = List<String>.from(_pendingTranscriptions);
    _pendingTranscriptions.clear();
    _lastBatchFailedTranscriptions.clear();
    _isProcessing = true;
    notifyListeners();

    try {
      for (int i = 0; i < toProcess.length; i++) {
        final text = toProcess[i];
        if (text.isEmpty) continue;
        try {
          final entry = await _dataProcessor.processVoiceInput(text);
          if (entry != null && entry.isValid()) {
            _currentBatch.add(entry);
          } else {
            // Gemini returned null: preserve for offline queue
            _lastBatchFailedTranscriptions.add(text);
            debugPrint('[VoiceManager] Gemini returned null for "$text"');
          }
          // On rate-limit or network error stop immediately and save all
          // remaining items — do not silently discard them.
          if (_dataProcessor.lastCallWasRateLimit ||
              _dataProcessor.lastCallWasNetworkError) {
            for (int j = i + 1; j < toProcess.length; j++) {
              if (toProcess[j].isNotEmpty) {
                _lastBatchFailedTranscriptions.add(toProcess[j]);
              }
            }
            debugPrint(
                '[VoiceManager] Batch stopped early at $i/${toProcess.length - 1}. '
                '${_lastBatchFailedTranscriptions.length} items saved as failed.');
            break;
          }
        } catch (e) {
          debugPrint('[VoiceManager] Gemini error for "$text": $e');
          _lastBatchFailedTranscriptions.add(text);
        }
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }

    // Return a snapshot so that clearBatch() called by the caller cannot
    // retroactively empty the batch that was just handed over.
    final snapshot = VoiceEntryBatch();
    for (final e in _currentBatch.entries) {
      snapshot.add(e);
    }
    return snapshot;
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
  
  /// Clear the current batch and any queued transcriptions
  void clearBatch() {
    _currentBatch.clear();
    _pendingTranscriptions.clear();
    notifyListeners();
  }
  
  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Acknowledge that the batch-stop event was handled by the UI.
  void clearBatchStop() {
    _batchStopRequested = false;
    notifyListeners();
  }

  /// Replace the pending transcriptions list (used by the review screen
  /// after the user edits / merges entries before sending to Gemini).
  void setPendingTranscriptions(List<String> texts) {
    _pendingTranscriptions.clear();
    _pendingTranscriptions.addAll(texts);
    notifyListeners();
  }
  
  /// Returns the full accumulated transcription (buffer + current engine chunk).
  /// If both are empty and a previous single-mode Gemini call failed,
  /// returns the preserved text so the "Salva per dopo" button stays visible.
  String getTranscription() {
    final current = _speechService.transcription;
    if (_continuousBuffer.isEmpty && current.isEmpty) {
      return _failedTranscription ?? '';
    }
    if (_continuousBuffer.isEmpty) return current;
    if (current.isEmpty) return _continuousBuffer;
    return '$_continuousBuffer $current';
  }
  
  /// Get partial transcripts (useful for debugging)
  List<String> getRecognitionHistory() {
    return _speechService.recognitionHistory;
  }
  
  /// Clear the current transcription, continuous buffer and any preserved failure text.
  void clearTranscription() {
    _continuousBuffer = '';
    _silentRestartCount = 0;
    _failedTranscription = null;
    _speechService.clearTranscription();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _speechService.removeListener(_onSpeechServiceChanged);
    _dataProcessor.removeListener(_onDataProcessorChanged);
    _autoStopTimer?.cancel();
    _triggerRestartTimer?.cancel();
    super.dispose();
  }
}