// lib/screens/voice_command_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/voice_input_manager_google.dart';
import '../services/wit_data_processor.dart';
import '../widgets/google_voice_input_widget.dart';
import 'voice_entry_verification_screen.dart';
import '../constants/theme_constants.dart';
import '../services/wit_speech_recognition_service.dart';
import '../services/voice_feedback_service.dart';

class VoiceCommandScreenUpdated extends StatefulWidget {
  @override
  _VoiceCommandScreenUpdatedState createState() => _VoiceCommandScreenUpdatedState();
}

class _VoiceCommandScreenUpdatedState extends State<VoiceCommandScreenUpdated> {
  bool _showGuide = true;
  late VoiceInputManagerGoogle _voiceManager;
  
  @override
  void initState() {
    super.initState();
    // Inizializza i servizi qui invece di usare Provider.of
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    final speechService = Provider.of<WitSpeechRecognitionService>(context, listen: false);
    final dataProcessor = Provider.of<WitDataProcessor>(context, listen: false);
    final feedbackService = VoiceFeedbackService();
    
    // Crea il VoiceInputManagerGoogle localmente
    _voiceManager = VoiceInputManagerGoogle(
      speechService,
      dataProcessor,
      feedbackService: feedbackService
    );
  }
    
  @override
  Widget build(BuildContext context) {
    // Ottieni solo ApiService dal provider
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Inserimento vocale (Wit.ai)'),
        actions: [
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
      // Avvolgi tutto il body in un SingleChildScrollView per evitare overflow verticale
      body: SingleChildScrollView(
        // Imposta physics a AlwaysScrollableScrollPhysics per garantire scorrimento anche con poco contenuto
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          // Questo garantisce che il contenuto occupi almeno l'altezza dello schermo
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                      AppBar().preferredSize.height - 
                      MediaQuery.of(context).padding.top,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Importante per evitare overflow verticale
            children: [
              // Sezione guida
              if (_showGuide)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    // Già usa SingleChildScrollView, assicuriamo che funzioni correttamente
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
                          SizedBox(height: 16),
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
                          SizedBox(height: 8),
                          Divider(),
                          SizedBox(height: 8),
                          Text(
                            'Comandi supportati:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildCommandExample(
                            '"Apiario Montagna arnia 3, regina presente, vista, nessuna cella reale, 4 telaini di covata, 3 di scorte"'
                          ),
                          _buildCommandExample(
                            '"Apiario Centrale arnia 7, covata scarsa, problemi sanitari, covata calcificata"'
                          ),
                          _buildCommandExample(
                            '"Arnia 2, ispezione del 20 maggio 2025, 7 telaini totali, famiglia forte"'
                          ),
                          SizedBox(height: 8),
                          Divider(),
                          SizedBox(height: 8),
                          Text(
                            'Suggerimenti:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('• Parla chiaramente e a un ritmo normale'),
                          Text('• Menziona sempre il numero dell\'apiario e dell\'arnia'),
                          Text('• In modalità multipla, puoi effettuare registrazioni consecutive'),
                          Text('• Verifica i dati prima di salvarli definitivamente'),
                          SizedBox(height: 12),
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
                                    'Questa versione utilizza Wit.ai per un riconoscimento vocale più intelligente',
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
              
              // Widget per l'input vocale
              ChangeNotifierProvider<VoiceInputManagerGoogle>.value(
                value: _voiceManager,
                child: Container(
                  height: 250, // Altezza fissa per l'area di input vocale
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: GoogleVoiceInputWidget(
                      onEntriesReady: _handleEntriesReady,
                      showBatchMode: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                SizedBox(height: 4),
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
    // Assicurati di rilasciare le risorse
    super.dispose();
  }
}