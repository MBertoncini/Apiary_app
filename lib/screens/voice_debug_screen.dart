// lib/screens/voice_debug_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../services/simple_record_service.dart';
import '../services/simple_voice_input_manager.dart';
import '../services/wit_data_processor.dart';
import '../services/voice_feedback_service.dart';
import '../constants/theme_constants.dart';

class VoiceDebugScreen extends StatefulWidget {
  @override
  _VoiceDebugScreenState createState() => _VoiceDebugScreenState();
}

class _VoiceDebugScreenState extends State<VoiceDebugScreen> {
  SimpleRecordService? _recordService;
  SimpleVoiceInputManager? _voiceManager;
  String _logContent = '';
  String _systemInfo = '';
  bool _isRecording = false;
  double _currentAmplitude = 0;
  bool _hasPermission = false;
  bool _canWriteToTemp = false;

  @override
  void initState() {
    super.initState();
    _initServices();
    _getSystemInfo();
    _checkTempDirectory();
  }

  Future<void> _initServices() async {
    // Crea i servizi necessari
    final dataProcessor = WitDataProcessor();
    final feedbackService = VoiceFeedbackService();
    
    // Crea il servizio di registrazione
    _recordService = SimpleRecordService();
    
    // Crea il gestore di input vocale
    _voiceManager = SimpleVoiceInputManager(
      _recordService!,
      dataProcessor,
      feedbackService: feedbackService
    );
    
    // Imposta listener per aggiornare l'UI
    _recordService!.addListener(() {
      if (mounted) {
        setState(() {
          _isRecording = _recordService!.isListening;
        });
      }
    });
    
    // Verifica permessi
    _hasPermission = await _recordService!.hasMicrophonePermission();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _getSystemInfo() async {
    try {
      final String platform = Platform.operatingSystem;
      final String version = Platform.operatingSystemVersion;
      
      _systemInfo = 'Platform: $platform\nVersion: $version';
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _systemInfo = 'Error getting system info: $e';
    }
  }

  Future<void> _checkTempDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _logContent += 'Temp directory: ${tempDir.path}\n';
      
      try {
        final testFile = File('${tempDir.path}/test_write_debug.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
        _canWriteToTemp = true;
        _logContent += 'Can write to temp directory: YES\n';
      } catch (e) {
        _canWriteToTemp = false;
        _logContent += 'Can write to temp directory: NO - $e\n';
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _logContent += 'Error checking temp directory: $e\n';
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _startRecording() async {
    if (_recordService == null) return;
    
    setState(() {
      _logContent += 'Starting recording...\n';
    });
    
    final success = await _recordService!.startListening();
    
    setState(() {
      _logContent += 'Recording started: $success\n';
      if (!success && _recordService!.error != null) {
        _logContent += 'Error: ${_recordService!.error}\n';
      }
    });
  }

  Future<void> _stopRecording() async {
    if (_recordService == null) return;
    
    setState(() {
      _logContent += 'Stopping recording...\n';
    });
    
    await _recordService!.stopListening();
    
    setState(() {
      _logContent += 'Recording stopped\n';
      if (_recordService!.error != null) {
        _logContent += 'Error: ${_recordService!.error}\n';
      }
      if (_recordService!.transcription.isNotEmpty) {
        _logContent += 'Transcription: "${_recordService!.transcription}"\n';
      } else {
        _logContent += 'No transcription received\n';
      }
    });
  }

  Future<void> _checkPermission() async {
    if (_recordService == null) return;
    
    setState(() {
      _logContent += 'Checking permission...\n';
    });
    
    final hasPermission = await _recordService!.hasMicrophonePermission();
    
    setState(() {
      _hasPermission = hasPermission;
      _logContent += 'Microphone permission: $hasPermission\n';
    });
  }

  void _clearLog() {
    setState(() {
      _logContent = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Riconoscimento Vocale'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearLog,
            tooltip: 'Pulisci log',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informazioni Sistema',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_systemInfo),
                    Divider(),
                    Row(
                      children: [
                        Icon(
                          _hasPermission ? Icons.check_circle : Icons.cancel,
                          color: _hasPermission ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Permesso Microfono: ${_hasPermission ? "Concesso" : "Negato"}',
                          ),
                        ),
                        TextButton(
                          onPressed: _checkPermission,
                          child: Text('Verifica'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          _canWriteToTemp ? Icons.check_circle : Icons.cancel,
                          color: _canWriteToTemp ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Accesso Cartella Temp: ${_canWriteToTemp ? "OK" : "ERRORE"}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Registrazione',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(_isRecording ? 'Stop Registrazione' : 'Inizia Registrazione'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? Colors.red : ThemeConstants.primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isRecording)
                      Center(
                        child: Column(
                          children: [
                            Text('Registrazione in corso...'),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: null,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    if (_recordService != null && _recordService!.transcription.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trascrizione:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _recordService!.transcription,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_recordService != null && _recordService!.error != null)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Errore:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _recordService!.error!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.content_copy),
                          onPressed: () {
                            // Copia il log negli appunti
                          },
                          tooltip: 'Copia log',
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      height: 200,
                      child: SingleChildScrollView(
                        child: Text(
                          _logContent,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_voiceManager != null) {
      _voiceManager!.dispose();
    }
    super.dispose();
  }
}