// lib/screens/voice_command_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/platform_voice_input_manager.dart';
import '../services/platform_speech_service.dart';
import '../services/wit_data_processor.dart';
import '../widgets/voice_input_widget.dart';
import 'voice_entry_verification_screen.dart';
import '../constants/theme_constants.dart';
import '../services/voice_feedback_service.dart';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  bool _showGuide = true;
  bool _showDebugPanel = false;
  late PlatformVoiceInputManager _voiceManager;
  late PlatformSpeechService _speechService;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() {
    // Crea i servizi necessari
    _speechService = PlatformSpeechService();
    final dataProcessor = WitDataProcessor();
    final feedbackService = VoiceFeedbackService();
    
    // Crea il VoiceInputManager
    _voiceManager = PlatformVoiceInputManager(
      _speechService,
      dataProcessor,
      feedbackService: feedbackService
    );
  }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inserimento vocale'),
        actions: [
          // Debug toggle button
          IconButton(
            icon: Icon(_showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDebugPanel = !_showDebugPanel;
              });
            },
            tooltip: _showDebugPanel ? 'Nascondi debug' : 'Mostra debug',
          ),
          // Guide toggle button
          IconButton(
            icon: Icon(_showGuide ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showGuide = !_showGuide;
              });
            },
            tooltip: _showGuide ? 'Nascondi guida' : 'Mostra guida',
          ),
        ],
      ),
      // Wrap the entire body in a SingleChildScrollView to avoid vertical overflow
      body: SingleChildScrollView(
        // Set physics to AlwaysScrollableScrollPhysics to ensure scrolling even with little content
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          // This ensures the content occupies at least the screen height
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                      AppBar().preferredSize.height - 
                      MediaQuery.of(context).padding.top,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important to avoid vertical overflow
            children: [
              // Guide section
              if (_showGuide)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Come funziona l\'inserimento vocale',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGuideItem(
                            icon: Icons.mic,
                            title: 'Inizia a parlare',
                            description: 'Premi il pulsante del microfono e inizia a parlare chiaramente',
                          ),
                          _buildGuideItem(
                            icon: Icons.hive,
                            title: 'Specifica apiario e arnia',
                            description: 'Es: "Apiario Montagna, arnia 5, regina presente, 3 telaini di covata"',
                          ),
                          _buildGuideItem(
                            icon: Icons.check_circle,
                            title: 'Verifica e salva',
                            description: 'Controlla i dati riconosciuti prima di salvarli nel database',
                          ),
                          const SizedBox(height: 8),
                          Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Comandi supportati:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCommandExample(
                            '"Apiario Montagna arnia 3, regina presente, vista, nessuna cella reale, 4 telaini di covata, 3 di scorte"'
                          ),
                          _buildCommandExample(
                            '"Apiario Centrale arnia 7, covata scarsa, problemi sanitari, covata calcificata"'
                          ),
                          _buildCommandExample(
                            '"Arnia 2, ispezione del 20 maggio 2025, 7 telaini totali, famiglia forte"'
                          ),
                          const SizedBox(height: 8),
                          Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Suggerimenti:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('• Parla chiaramente e a un ritmo normale'),
                          Text('• Menziona sempre il numero dell\'apiario e dell\'arnia'),
                          Text('• In modalità multipla, puoi effettuare registrazioni consecutive'),
                          Text('• Verifica i dati prima di salvarli definitivamente'),
                          const SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Questa versione utilizza il riconoscimento vocale integrato nel tuo dispositivo',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Debug panel
              if (_showDebugPanel)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug Panel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Divider(),
                          Text('Nuovo metodo di riconoscimento vocale:'),
                          const SizedBox(height: 4),
                          Text('• Utilizza API di riconoscimento vocale native'),
                          Text('• Richiede connessione internet'),
                          Text('• Supporta l\'italiano tramite il sistema operativo'),
                          const SizedBox(height: 8),
                          ListenableBuilder(
                            listenable: _voiceManager,
                            builder: (context, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stato: ${_voiceManager.isListening ? "Ascolto" : "Inattivo"}'),
                                  if (_voiceManager.error != null)
                                    Text('Errore: ${_voiceManager.error}', 
                                      style: TextStyle(color: Colors.red)),
                                  if (_voiceManager.getTranscription().isNotEmpty)
                                    Text('Trascrizione: "${_voiceManager.getTranscription()}"',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: Icon(Icons.refresh),
                                label: Text('Reset'),
                                onPressed: () {
                                  _speechService.clearTranscription();
                                  _voiceManager.clearError();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Servizio vocale ripristinato'))
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Voice input widget
              ChangeNotifierProvider<PlatformVoiceInputManager>.value(
                value: _voiceManager,
                child: Container(
                  height: 250, // Fixed height for voice input area
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: _buildCustomVoiceInputWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a custom voice input widget since we can't use the standard one
  // because it expects VoiceInputManager, not PlatformVoiceInputManager
  Widget _buildCustomVoiceInputWidget() {
    return ListenableBuilder(
      listenable: _voiceManager,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status text
            Text(
              _getStatusText(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _voiceManager.error != null
                    ? Colors.red
                    : ThemeConstants.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Microphone button
            InkWell(
              onTap: () {
                if (_voiceManager.isListening) {
                  _voiceManager.stopListening();
                } else {
                  _voiceManager.startListening(batchMode: _voiceManager.isBatchMode);
                }
              },
              child: Container(
                width: _voiceManager.isListening ? 100 : 80,
                height: _voiceManager.isListening ? 100 : 80,
                decoration: BoxDecoration(
                  color: _voiceManager.isProcessing 
                    ? Colors.orange 
                    : (_voiceManager.isListening ? Colors.red : ThemeConstants.primaryColor),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _voiceManager.isListening 
                        ? Colors.red.withOpacity(0.5) 
                        : ThemeConstants.primaryColor.withOpacity(0.3),
                      spreadRadius: _voiceManager.isListening ? 4 : 2,
                      blurRadius: _voiceManager.isListening ? 8 : 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: _voiceManager.isProcessing
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      )
                    : Icon(
                        _voiceManager.isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: _voiceManager.isListening ? 40 : 32,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Batch mode switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Inserimento multiplo'),
                Switch(
                  value: _voiceManager.isBatchMode,
                  onChanged: (value) {
                    if (_voiceManager.isListening) {
                      _voiceManager.stopListening();
                    }
                    if (value) {
                      _voiceManager.startListening(batchMode: true);
                    }
                  },
                  activeColor: ThemeConstants.primaryColor,
                ),
              ],
            ),
            
            // Transcription
            if (_voiceManager.getTranscription().isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(_voiceManager.getTranscription()),
              ),
              
            // Batch status
            if (_voiceManager.currentBatch.length > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${_voiceManager.currentBatch.length} registrazioni in attesa'),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _handleEntriesReady(_voiceManager.currentBatch);
                      },
                      child: Text('Verifica'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _getStatusText() {
    if (_voiceManager.error != null) {
      return 'Errore: ${_voiceManager.error}';
    }
    
    if (_voiceManager.isProcessing) {
      return 'Elaborazione comando vocale...';
    }
    
    if (_voiceManager.isListening) {
      return _voiceManager.isBatchMode
          ? 'Sto ascoltando... Parla chiaramente (modalità multipla)'
          : 'Sto ascoltando... Parla chiaramente';
    }
    
    return _voiceManager.isBatchMode
        ? 'Premi il pulsante per l\'inserimento multiplo'
        : 'Premi il pulsante per iniziare a parlare';
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: ThemeConstants.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommandExample(String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          example,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  void _handleEntriesReady(batch) {
    // Navigate to verification screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoiceEntryVerificationScreen(
          batch: batch,
          onSuccess: (results) {
            // Return to previous screen and clear batch
            Navigator.of(context).pop();
            
            // Clear the batch
            _voiceManager.clearBatch();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dati salvati con successo (${results.length} record)'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onCancel: () {
            // Just return to previous screen
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _voiceManager.dispose();
    _speechService.dispose();
    super.dispose();
  }
}