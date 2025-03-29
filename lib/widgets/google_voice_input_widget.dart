// lib/widgets/google_voice_input_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../services/voice_input_manager_google.dart';
import '../services/voice_feedback_service.dart';
import '../models/voice_entry.dart';

/// Widget per l'input vocale che utilizza Google Speech API
class GoogleVoiceInputWidget extends StatefulWidget {
  final Function(VoiceEntryBatch)? onEntriesReady;
  final bool showBatchMode;
  
  const GoogleVoiceInputWidget({
    Key? key,
    this.onEntriesReady,
    this.showBatchMode = true,
  }) : super(key: key);
  
  @override
  _GoogleVoiceInputWidgetState createState() => _GoogleVoiceInputWidgetState();
}

class _GoogleVoiceInputWidgetState extends State<GoogleVoiceInputWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Inizializza l'animazione
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Ottieni i servizi dal provider
    late VoiceInputManagerGoogle voiceManager;
    late VoiceFeedbackService feedbackService;
    
    try {
      voiceManager = Provider.of<VoiceInputManagerGoogle>(context);
      feedbackService = Provider.of<VoiceFeedbackService>(context, listen: false);
    } catch (e) {
      // Caso dove il provider non è disponibile
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Servizio di voce non disponibile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Controlla che il servizio di voce sia correttamente inizializzato.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Avvolgiamo tutto in un SingleChildScrollView per gestire qualsiasi overflow
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 150,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stato dell'input vocale e controlli
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stato e controlli
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Testo di stato
                      Expanded(
                        child: Text(
                          _getStatusText(voiceManager),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: voiceManager.error != null
                                ? Colors.red
                                : ThemeConstants.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      
                      // Pulsante modalità batch
                      if (widget.showBatchMode)
                        Container(
                          width: 180, // Larghezza fissa
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Inserimento multiplo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ThemeConstants.textSecondaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Switch(
                                value: voiceManager.isBatchMode,
                                onChanged: (value) {
                                  if (voiceManager.isListening) {
                                    voiceManager.stopListening();
                                  }
                                  if (value) {
                                    voiceManager.startListening(batchMode: true);
                                  }
                                },
                                activeColor: ThemeConstants.primaryColor,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  // Visualizzazione dell'animazione di pulsazione
                  if (voiceManager.isListening)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animazione di pulsazione
                        feedbackService.buildPulsingAnimation(voiceManager.isListening),
                        
                        // Pulsante del microfono al centro
                        feedbackService.buildAnimatedMicButton(
                          isListening: voiceManager.isListening,
                          isProcessing: voiceManager.isProcessing,
                          onPressed: () {
                            if (voiceManager.isListening) {
                              voiceManager.stopListening();
                            } else {
                              voiceManager.startListening(
                                batchMode: voiceManager.isBatchMode,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  
                  // Se non stiamo ascoltando, mostra solo il pulsante
                  if (!voiceManager.isListening)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: feedbackService.buildAnimatedMicButton(
                        isListening: voiceManager.isListening,
                        isProcessing: voiceManager.isProcessing,
                        onPressed: () {
                          if (voiceManager.isListening) {
                            voiceManager.stopListening();
                          } else {
                            voiceManager.startListening(
                              batchMode: voiceManager.isBatchMode,
                            );
                          }
                        },
                      ),
                    ),
                  
                  // Visualizzazione dell'animazione della forma d'onda
                  if (voiceManager.isListening)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: feedbackService.buildWaveformAnimation(voiceManager.isListening),
                    ),
                  
                  // Visualizzazione della trascrizione
                  if (voiceManager.isListening || voiceManager.isProcessing || voiceManager.getTranscription().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: voiceManager.isProcessing 
                                ? Colors.orange.withOpacity(0.5) 
                                : Colors.grey.withOpacity(0.2)
                          ),
                        ),
                        child: voiceManager.isProcessing
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ThemeConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('Elaborazione in corso...')),
                                ],
                              )
                            : Text(
                                voiceManager.getTranscription(),
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                      ),
                    ),
                  
                  // Stato del batch - utilizzo più compatto
                  if (voiceManager.isBatchMode && voiceManager.currentBatch.length > 0)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 16,
                            color: ThemeConstants.primaryColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${voiceManager.currentBatch.length} registrazione/i in attesa',
                              style: TextStyle(
                                color: ThemeConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Controlli e azioni
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Pulsante di annullamento (solo durante l'ascolto)
                          if (voiceManager.isListening)
                            ElevatedButton.icon(
                              onPressed: () {
                                voiceManager.stopListening();
                                // La trascrizione verrà scartata
                                voiceManager.clearTranscription();
                              },
                              icon: Icon(Icons.close, size: 16),
                              label: Text('Annulla'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          
                          // Pulsante di revisione (solo in modalità batch con voci)
                          if (!voiceManager.isListening && 
                              voiceManager.isBatchMode && 
                              voiceManager.currentBatch.length > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (widget.onEntriesReady != null) {
                                    widget.onEntriesReady!(voiceManager.currentBatch);
                                  }
                                },
                                icon: Icon(Icons.check_circle, size: 18),
                                label: Text('Verifica'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ThemeConstants.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            
                          // Pulsante di pulizia (solo in modalità batch con voci)
                          if (!voiceManager.isListening && 
                              voiceManager.isBatchMode && 
                              voiceManager.currentBatch.length > 0)
                            TextButton.icon(
                              onPressed: () {
                                voiceManager.clearBatch();
                              },
                              icon: Icon(Icons.delete_outline, size: 18),
                              label: Text('Pulisci'),
                            ),
                            
                          // Configurazione
                          if (!voiceManager.isListening && !voiceManager.isProcessing)
                            IconButton(
                              icon: Icon(Icons.settings),
                              tooltip: 'Impostazioni riconoscimento vocale',
                              onPressed: () {
                                // Mostra dialog di configurazione
                                _showVoiceSettingsDialog(context, feedbackService);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Dialog per impostazioni riconoscimento vocale
  void _showVoiceSettingsDialog(BuildContext context, VoiceFeedbackService feedbackService) {
    // Crea delle copie locali delle impostazioni attuali
    bool vibrationEnabled = feedbackService.vibrationEnabled;
    bool soundEnabled = feedbackService.soundEnabled;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Impostazioni input vocale'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text('Vibrazione'),
                  subtitle: Text('Feedback aptico durante il riconoscimento'),
                  value: vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      vibrationEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: Text('Suoni'),
                  subtitle: Text('Feedback sonoro durante il riconoscimento'),
                  value: soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      soundEnabled = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Applica le modifiche
                  feedbackService.vibrationEnabled = vibrationEnabled;
                  feedbackService.soundEnabled = soundEnabled;
                  Navigator.of(context).pop();
                },
                child: Text('Applica'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  String _getStatusText(VoiceInputManagerGoogle voiceManager) {
    if (voiceManager.error != null) {
      return 'Errore: ${voiceManager.error}';
    }
    
    if (voiceManager.isProcessing) {
      return 'Elaborazione comando vocale...';
    }
    
    if (voiceManager.isListening) {
      return voiceManager.isBatchMode
          ? 'Sto ascoltando... Parla chiaramente (modalità multipla)'
          : 'Sto ascoltando... Parla chiaramente';
    }
    
    return voiceManager.isBatchMode
        ? 'Premi il pulsante per l\'inserimento multiplo'
        : 'Premi il pulsante per iniziare a parlare';
  }
}