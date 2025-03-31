// lib/services/wit_speech_recognition_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class WitSpeechRecognitionService with ChangeNotifier {
  // Constants
  static const String _witApiUrl = 'https://api.wit.ai/speech';
  static const String _witApiToken = '2NJ4OP6FZXEWAJ56GC7PET2KOKXIXJZM';
  static const int _minAudioDuration = 1000; // Minimum ms for a valid recording
  
  // Flutter Sound recorder
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  // Current state
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _transcription = '';
  String _languageCode = 'it-IT';
  double _confidence = 0.0;
  List<String> _partialTranscripts = [];
  String? _recordingPath;
  DateTime? _recordingStartTime;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get transcription => _transcription;
  String get languageCode => _languageCode;
  double get confidence => _confidence;
  List<String> get partialTranscripts => _partialTranscripts;
  
  // Constructor
  WitSpeechRecognitionService() {
    _initRecorder();
  }
  
  // Initialize the audio recorder
  Future<bool> _initRecorder() async {
    if (_isInitialized) return true;
    
    try {
      debugPrint('[WitSpeech] Initializing Recorder...');
      
      // Set up recorder with logging
      await _recorder.openRecorder();
      
      // Set subscription for dbPeakProgress to monitor audio levels
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      _recorder.onProgress?.listen((e) {
        if (e.decibels != null) {
          debugPrint('[WitSpeech] Audio level: ${e.decibels} dB');
        }
      });
      
      debugPrint('[WitSpeech] Recorder Initialized successfully.');
      
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[WitSpeech] Error initializing recorder: $e');
      debugPrint('[WitSpeech] Stack trace: $stackTrace');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }
  
  // Check and request microphone permissions
  Future<bool> hasMicrophonePermission() async {
    var status = await Permission.microphone.status;
    debugPrint('[WitSpeech] Microphone permission status: $status');
    
    if (status.isGranted) return true;
    
    debugPrint('[WitSpeech] Requesting microphone permission...');
    status = await Permission.microphone.request();
    debugPrint('[WitSpeech] Microphone permission status after request: $status');
    
    if (status.isPermanentlyDenied) {
      debugPrint('[WitSpeech] Microphone permission permanently denied. Please enable in settings.');
    }
    
    return status.isGranted;
  }
  
  // Start listening
  Future<bool> startListening() async {
    if (_isListening) {
      debugPrint('[WitSpeech] Already listening.');
      return true;
    }
    
    // Make sure the recorder is initialized
    if (!_isInitialized) {
      debugPrint('[WitSpeech] Speech service not initialized. Initializing...');
      final initialized = await _initRecorder();
      if (!initialized) {
        debugPrint('[WitSpeech] Failed to initialize speech service. Cannot start listening.');
        return false;
      }
    }
    
    // Check permissions
    final hasPermission = await hasMicrophonePermission();
    if (!hasPermission) {
      debugPrint('[WitSpeech] Microphone permission denied. Cannot start listening.');
      return false;
    }
    
    // Reset state
    _transcription = '';
    _partialTranscripts.clear();
    _confidence = 0.0;
    notifyListeners();
    
    debugPrint('[WitSpeech] Starting listening...');
    
    try {
      // Prepare recording path
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/temp_recording.wav';
      debugPrint('[WitSpeech] Recording path: $_recordingPath');
      
      // Make sure there's no previous recording in progress
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
        await Future.delayed(Duration(milliseconds: 300));
      }
      
      // Delete any existing file at the recording path
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[WitSpeech] Deleted existing recording file');
      }
      
      // Begin recording with better parameters
      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000, // Wit.ai prefers 16kHz
        bitRate: 16000, // Ensure we're using 16 bits
        numChannels: 1, // Mono recording
      );
      
      _recordingStartTime = DateTime.now();
      debugPrint('[WitSpeech] Recording started at: $_recordingStartTime');
      
      _isListening = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[WitSpeech] Error starting recording: $e');
      return false;
    }
  }
  
  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) {
      debugPrint('[WitSpeech] Not currently listening.');
      return;
    }
    
    debugPrint('[WitSpeech] Stopping listening...');
    try {
      // Calculate recording duration
      final recordingDuration = _recordingStartTime != null 
          ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
          : 0;
      
      debugPrint('[WitSpeech] Recording duration: ${recordingDuration}ms');
      
      // If the recording is too short, add a small delay to ensure it's valid
      if (recordingDuration < _minAudioDuration) {
        debugPrint('[WitSpeech] Recording too short, adding delay to ensure valid data');
        await Future.delayed(Duration(milliseconds: _minAudioDuration - recordingDuration));
      }
      
      // Stop the recording
      final recordingResult = await _recorder.stopRecorder();
      _isListening = false;
      notifyListeners();
      
      if (recordingResult != null && recordingResult.isNotEmpty) {
        // Check file size
        final file = File(recordingResult);
        final fileSize = await file.length();
        debugPrint('[WitSpeech] Recorded file size: $fileSize bytes');
        
        if (fileSize < 1000) { // Minimum reasonable file size for speech
          debugPrint('[WitSpeech] Warning: Audio file is very small ($fileSize bytes)');
        }
        
        if (fileSize > 100) { // Only process if there's some data
          _isProcessing = true;
          notifyListeners();
          
          await _processAudioWithWit(recordingResult);
          
          _isProcessing = false;
          notifyListeners();
        } else {
          debugPrint('[WitSpeech] Audio file too small to process: $fileSize bytes');
          _transcription = ''; // Clear any previous transcription
          notifyListeners();
        }
      }
      
      debugPrint('[WitSpeech] Listening stopped successfully.');
    } catch (e, stackTrace) {
      debugPrint('[WitSpeech] Error stopping recording: $e');
      debugPrint('[WitSpeech] Stack trace: $stackTrace');
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Process audio with Wit.ai
  Future<void> _processAudioWithWit(String audioFilePath) async {
    try {
      debugPrint('[WitSpeech] Processing audio with Wit.ai: $audioFilePath');
      
      // Read the audio file
      final file = File(audioFilePath);
      if (!await file.exists()) {
        debugPrint('[WitSpeech] Audio file does not exist: $audioFilePath');
        return;
      }
      
      final fileSize = await file.length();
      if (fileSize < 100) {
        debugPrint('[WitSpeech] Audio file is too small (${fileSize} bytes), likely empty recording');
        return;
      }
      
      final audioBytes = await file.readAsBytes();
      debugPrint('[WitSpeech] Read ${audioBytes.length} bytes from audio file');
      
      // Prepare HTTP request
      final uri = Uri.parse('$_witApiUrl');
      final request = http.Request('POST', uri);
      
      // Set headers
      request.headers.addAll({
        'Authorization': 'Bearer $_witApiToken',
        'Content-Type': 'audio/wav',
        'Accept': 'application/json',
      });
      
      // Set request body with audio bytes
      request.bodyBytes = audioBytes;
      
      // Send request
      final httpClient = http.Client();
      try {
        debugPrint('[WitSpeech] Sending request to Wit.ai...');
        final streamedResponse = await httpClient.send(request).timeout(
          Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Request to Wit.ai timed out');
          }
        );
        
        final response = await http.Response.fromStream(streamedResponse);
        
        debugPrint('[WitSpeech] Wit.ai API response code: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          await _saveResponseToDebugFile(response.body);
          
          try {
            // Extract the first JSON object from response
            final firstJsonObject = _extractFirstJsonObject(response.body);
            debugPrint('[WitSpeech] First JSON object length: ${firstJsonObject?.length ?? 0}');
            
            if (firstJsonObject != null) {
              final responseJson = jsonDecode(firstJsonObject);
              
              // Extract the transcribed text
              _transcription = responseJson['text'] ?? '';
              
              // If no text in first object, try the second
              if (_transcription.isEmpty) {
                final secondJsonObject = _extractSecondJsonObject(response.body);
                if (secondJsonObject != null) {
                  final secondJson = jsonDecode(secondJsonObject);
                  _transcription = secondJson['text'] ?? '';
                }
              }
              
              // Update confidence - CORRECTED TO HANDLE BOTH INT AND DOUBLE
              if (responseJson['speech'] != null && responseJson['speech']['confidence'] != null) {
                var confidenceValue = responseJson['speech']['confidence'];
                if (confidenceValue is int) {
                  _confidence = confidenceValue.toDouble();
                } else {
                  _confidence = confidenceValue as double? ?? 0.0;
                }
              } else {
                _confidence = _transcription.isNotEmpty ? 0.8 : 0.0;
              }
              
              if (_transcription.isNotEmpty) {
                debugPrint('[WitSpeech] Transcription: "$_transcription"');
                _partialTranscripts.add(_transcription);
                if (_partialTranscripts.length > 10) {
                  _partialTranscripts.removeAt(0);
                }
              } else {
                debugPrint('[WitSpeech] Wit.ai did not recognize any text in the audio');
              }
            } else {
              debugPrint('[WitSpeech] Unable to extract a valid JSON object from response');
            }
            
            notifyListeners();
          } catch (parseError) {
            debugPrint('[WitSpeech] Error decoding JSON from Wit.ai: $parseError');
            _transcription = '';
            notifyListeners();
          }
        } else {
          debugPrint('[WitSpeech] Error from Wit.ai API: ${response.statusCode} - ${response.body}');
        }
      } finally {
        httpClient.close();
      }
    } catch (e, stackTrace) {
      debugPrint('[WitSpeech] Error processing audio with Wit.ai: $e');
      debugPrint('[WitSpeech] Stack trace: $stackTrace');
    }
  }

  // Method to extract the first JSON object from the response
  String? _extractFirstJsonObject(String text) {
    final firstOpenBrace = text.indexOf('{');
    if (firstOpenBrace < 0) return null;
    
    int depth = 0;
    for (int i = firstOpenBrace; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(firstOpenBrace, i + 1);
        }
      }
    }
    
    return null; // No valid JSON object found
  }

  // Method to extract the second JSON object from the response
  String? _extractSecondJsonObject(String text) {
    // Find the first complete JSON object
    final firstJson = _extractFirstJsonObject(text);
    if (firstJson == null) return null;
    
    // Look for the next '{' after the first object
    final startPos = text.indexOf(firstJson) + firstJson.length;
    final secondOpenBrace = text.indexOf('{', startPos);
    if (secondOpenBrace < 0) return null;
    
    int depth = 0;
    for (int i = secondOpenBrace; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(secondOpenBrace, i + 1);
        }
      }
    }
    
    return null; // No second JSON object found
  }

  // Method to save response for debugging
  Future<void> _saveResponseToDebugFile(String responseBody) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/wit_response_debug.txt');
      await file.writeAsString(responseBody);
      debugPrint('[WitSpeech] Response saved to: ${file.path}');
    } catch (e) {
      debugPrint('[WitSpeech] Error saving debug file: $e');
    }
  }

  // Set the language for recognition (note: Wit.ai is already configured for language)
  void setLanguageCode(String languageCode) {
    if (_languageCode != languageCode) {
      debugPrint('[WitSpeech] Setting language code to: $languageCode');
      _languageCode = languageCode;
      notifyListeners();
    }
  }
  
  // Clear the current transcription and history
  void clearTranscription() {
    debugPrint('[WitSpeech] Clearing transcription and history.');
    _transcription = '';
    _confidence = 0.0;
    _partialTranscripts.clear();
    notifyListeners();
  }
  
  // Reset recording engine - useful for troubleshooting
  Future<void> resetRecorder() async {
    debugPrint('[WitSpeech] Resetting recorder...');
    if (_isListening) {
      await stopListening();
    }
    
    // Close and reopen recorder
    await _recorder.closeRecorder();
    _isInitialized = false;
    notifyListeners();
    
    // Reinitialize
    await _initRecorder();
    debugPrint('[WitSpeech] Recorder reset complete.');
  }
  
  // Dispose resources
  @override
  void dispose() {
    debugPrint('[WitSpeech] Disposing WitSpeechRecognitionService...');
    _recorder.closeRecorder();
    _isListening = false;
    debugPrint('[WitSpeech] WitSpeechRecognitionService disposed.');
    super.dispose();
  }
}