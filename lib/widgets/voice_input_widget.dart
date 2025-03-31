// lib/widgets/voice_input_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../services/voice_input_manager.dart';
import '../services/voice_feedback_service.dart';
import '../models/voice_entry.dart';

/// Widget for voice input that can be added to any screen
class VoiceInputWidget extends StatefulWidget {
  final Function(VoiceEntryBatch)? onEntriesReady;
  final bool showBatchMode;
  final bool showDebugInfo;
  
  const VoiceInputWidget({
    Key? key,
    this.onEntriesReady,
    this.showBatchMode = true,
    this.showDebugInfo = false,
  }) : super(key: key);
  
  @override
  _VoiceInputWidgetState createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation
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
    // Get services from provider
    late VoiceInputManager voiceManager;
    late VoiceFeedbackService feedbackService;
    
    try {
      voiceManager = Provider.of<VoiceInputManager>(context);
      feedbackService = Provider.of<VoiceFeedbackService>(context, listen: false);
    } catch (e) {
      // Case where provider is not available
      return _buildServiceUnavailableWidget(e.toString());
    }
    
    // Wrap everything in a SingleChildScrollView to handle any overflow
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 150,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice input status and controls
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
                  // Status and controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status text
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
                      
                      // Batch mode button
                      if (widget.showBatchMode)
                        Container(
                          width: 180, // Fixed width
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
                  
                  // Display pulsing animation
                  if (voiceManager.isListening)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing animation
                        feedbackService.buildPulsingAnimation(voiceManager.isListening),
                        
                        // Microphone button in the center
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
                  
                  // If not listening, just show the button
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
                  
                  // Display waveform animation
                  if (voiceManager.isListening)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: feedbackService.buildWaveformAnimation(voiceManager.isListening),
                    ),
                  
                  // Display transcription
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
                  
                  // Batch status - more compact layout
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
                  
                  // Debug info panel (only if showDebugInfo is true)
                  if (widget.showDebugInfo && voiceManager.error != null)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug Info:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Error: ${voiceManager.error}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Controls and actions
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Cancel button (only during listening)
                          if (voiceManager.isListening)
                            ElevatedButton.icon(
                              onPressed: () {
                                voiceManager.stopListening();
                                // Transcription will be discarded
                                voiceManager.clearTranscription();
                              },
                              icon: Icon(Icons.close, size: 16),
                              label: Text('Annulla'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          
                          // Review button (only in batch mode with entries)
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
                            
                          // Clear button (only in batch mode with entries)
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
                            
                          // Reset button for error recovery
                          if (voiceManager.error != null && !voiceManager.isListening)
                            TextButton.icon(
                              onPressed: () {
                                voiceManager.resetSpeechService();
                              },
                              icon: Icon(Icons.refresh, size: 18),
                              label: Text('Reset'),
                            ),
                            
                          // Configuration
                          if (!voiceManager.isListening && !voiceManager.isProcessing)
                            IconButton(
                              icon: Icon(Icons.settings),
                              tooltip: 'Impostazioni riconoscimento vocale',
                              onPressed: () {
                                // Show settings dialog
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
  
  // Widget for service unavailable state
  Widget _buildServiceUnavailableWidget(String error) {
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
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Errore: $error',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  // Dialog for voice recognition settings
  void _showVoiceSettingsDialog(BuildContext context, VoiceFeedbackService feedbackService) {
    // Create local copies of current settings
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
                  // Apply changes
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
  
  String _getStatusText(VoiceInputManager voiceManager) {
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

/// Floating action button for quick voice input
class VoiceInputFAB extends StatelessWidget {
  final VoidCallback onPressed;
  
  const VoiceInputFAB({
    Key? key,
    required this.onPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'voice_input_floating_fab',
      onPressed: onPressed,
      backgroundColor: ThemeConstants.primaryColor,
      child: Icon(Icons.mic, color: Colors.white),
      tooltip: 'Input vocale',
    );
  }
}