// lib/widgets/voice_input_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../services/platform_voice_input_manager.dart';
import '../services/voice_feedback_service.dart';
import '../models/voice_entry.dart';
import 'voice_animations.dart';
import 'corrected_transcription_widget.dart';

/// Widget for voice input that can be added to any screen
class VoiceInputWidget extends StatefulWidget {
  final Function(VoiceEntryBatch)? onEntriesReady;
  /// Called with raw transcriptions BEFORE AI processing.
  /// When provided, replaces the default behaviour of calling
  /// [processPendingBatch] directly from the "Verifica" button.
  final Function(List<String>)? onTranscriptionsReady;
  final bool showBatchMode;
  final bool showDebugInfo;

  const VoiceInputWidget({
    Key? key,
    this.onEntriesReady,
    this.onTranscriptionsReady,
    this.showBatchMode = true,
    this.showDebugInfo = false,
  }) : super(key: key);
  
  @override
  _VoiceInputWidgetState createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  @override
  Widget build(BuildContext context) {
    // Get services from provider
    late PlatformVoiceInputManager voiceManager;
    late VoiceFeedbackService feedbackService;

    try {
      voiceManager = Provider.of<PlatformVoiceInputManager>(context);
      feedbackService = Provider.of<VoiceFeedbackService>(context, listen: false);
    } catch (e) {
      // Case where provider is not available
      return _buildServiceUnavailableWidget(e.toString());
    }
    
    void toggleListening() {
      if (voiceManager.isListening) {
        voiceManager.stopListening();
      } else {
        voiceManager.startListening(batchMode: voiceManager.isBatchMode);
      }
    }

    final transcription = voiceManager.getTranscription();
    final showTranscriptionBox = !voiceManager.isAwaitingTrigger &&
        (voiceManager.isListening ||
            voiceManager.isProcessing ||
            transcription.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Status row ──────────────────────────────────────────
          Row(
            children: [
              _StatusIcon(voiceManager: voiceManager),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getStatusText(voiceManager),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: voiceManager.error != null
                        ? Colors.red.shade700
                        : ThemeConstants.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Central area: trigger standby or mic button ──────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: voiceManager.isAwaitingTrigger
                ? _TriggerWaitingUI(
                    key: const ValueKey('trigger'),
                    onStartNow: () =>
                        voiceManager.startListening(batchMode: true),
                    onCancelBatch: voiceManager.cancelTriggerMode,
                  )
                : SizedBox(
                    key: const ValueKey('mic'),
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VoicePulsingRings(isActive: voiceManager.isListening),
                        VoiceMicButton(
                          isListening: voiceManager.isListening,
                          isProcessing: voiceManager.isProcessing,
                          onPressed: toggleListening,
                        ),
                      ],
                    ),
                  ),
          ),

          // ── Waveform (smooth expand/collapse) ───────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: voiceManager.isListening && !voiceManager.isAwaitingTrigger
                ? Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: VoiceWaveform(isActive: voiceManager.isListening),
                  )
                : const SizedBox(width: double.infinity),
          ),

          // ── Transcription box (smooth expand/collapse) ───────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: showTranscriptionBox
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: voiceManager.isProcessing
                            ? Colors.orange.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: voiceManager.isProcessing
                              ? Colors.orange.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
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
                                        Colors.orange.shade700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                    child: Text('Elaborazione in corso...',
                                        style: TextStyle(fontSize: 14))),
                              ],
                            )
                          : transcription.isEmpty
                              ? Text(
                                  'Parla ora…',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: Colors.grey.shade400,
                                  ),
                                )
                              : CorrectedTranscriptionWidget(
                                  rawText: transcription,
                                  baseStyle: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: ThemeConstants.textPrimaryColor,
                                  ),
                                ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),

          // ── Batch queue badge ────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: voiceManager.isBatchMode &&
                    voiceManager.pendingTranscriptions.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.mic_outlined,
                              size: 16,
                              color: ThemeConstants.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${voiceManager.pendingTranscriptions.length} '
                              'arni${voiceManager.pendingTranscriptions.length == 1 ? 'a' : 'e'} registrata/e',
                              style: TextStyle(
                                color: ThemeConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),

          // ── Debug panel ──────────────────────────────────────────
          if (widget.showDebugInfo && voiceManager.error != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Error: ${voiceManager.error}',
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
            ),

          // ── Action buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (voiceManager.isListening)
                    ElevatedButton.icon(
                      onPressed: () {
                        voiceManager.stopListening();
                        voiceManager.clearTranscription();
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Annulla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  if (!voiceManager.isListening &&
                      !voiceManager.isProcessing &&
                      !voiceManager.isAwaitingTrigger &&
                      voiceManager.isBatchMode &&
                      voiceManager.pendingTranscriptions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (widget.onTranscriptionsReady != null) {
                            // New flow: review screen before AI processing
                            widget.onTranscriptionsReady!(
                              List<String>.from(
                                  voiceManager.pendingTranscriptions),
                            );
                          } else {
                            // Legacy fallback: process directly
                            final batch =
                                await voiceManager.processPendingBatch();
                            if (batch.length > 0 &&
                                widget.onEntriesReady != null) {
                              widget.onEntriesReady!(batch);
                            }
                          }
                        },
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: Text(
                          'Rivedi '
                          '(${voiceManager.pendingTranscriptions.length})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Pulisci trascrizioni'),
                            content: const Text(
                              'Verranno eliminate tutte le trascrizioni '
                              'non ancora inviate in revisione. '
                              'Questa operazione non è reversibile.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Annulla'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Elimina tutto'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) voiceManager.clearBatch();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18,
                          color: Colors.red),
                      label: const Text('Pulisci',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  // Processing indicator during Gemini batch call
                  if (voiceManager.isProcessing &&
                      voiceManager.isBatchMode &&
                      !voiceManager.isListening)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Gemini sta elaborando...'),
                        ],
                      ),
                    ),
                  if (voiceManager.error != null && !voiceManager.isListening)
                    TextButton.icon(
                      onPressed: voiceManager.clearError,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset'),
                    ),
                  if (!voiceManager.isListening && !voiceManager.isProcessing)
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Impostazioni riconoscimento vocale',
                      onPressed: () =>
                          _showVoiceSettingsDialog(context, feedbackService),
                    ),
                ],
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 16),
          Text(
            'Servizio di voce non disponibile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
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
  
  String _getStatusText(PlatformVoiceInputManager voiceManager) {
    if (voiceManager.error != null) return voiceManager.error!;
    if (voiceManager.isProcessing) return 'Elaborazione...';
    if (voiceManager.isAwaitingTrigger) return 'In attesa del segnale vocale';
    if (voiceManager.isListening) {
      return 'In ascolto – modalità multipla';
    }
    return 'Premi per inserimento multiplo';
  }
}

// ── Small helper widgets ────────────────────────────────────────────────────

/// Shown in batch mode while waiting for the user to say a trigger word.
class _TriggerWaitingUI extends StatelessWidget {
  final VoidCallback onStartNow;
  final VoidCallback onCancelBatch;

  const _TriggerWaitingUI({
    Key? key,
    required this.onStartNow,
    required this.onCancelBatch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VoiceTriggerIndicator(),
          const SizedBox(height: 16),
          Text(
            'Dì "avanti" per la prossima arnia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"ok" • "vai" • "continua" • "prossima"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Dì "stop" / "fine" / "basta" per terminare',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onStartNow,
                icon: const Icon(Icons.mic, size: 16),
                label: const Text('Inizia subito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onCancelBatch,
                icon: const Icon(Icons.stop_circle_outlined, size: 16),
                label: const Text('Fine batch'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final PlatformVoiceInputManager voiceManager;
  const _StatusIcon({required this.voiceManager});

  @override
  Widget build(BuildContext context) {
    if (voiceManager.error != null) {
      return Icon(Icons.error_outline, size: 18, color: Colors.red.shade600);
    }
    if (voiceManager.isProcessing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor:
              AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
        ),
      );
    }
    if (voiceManager.isAwaitingTrigger) {
      return Icon(Icons.hearing, size: 18, color: ThemeConstants.primaryColor);
    }
    if (voiceManager.isListening) {
      return Icon(Icons.graphic_eq, size: 18, color: Colors.red.shade600);
    }
    return Icon(Icons.mic_none,
        size: 18, color: ThemeConstants.textSecondaryColor);
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