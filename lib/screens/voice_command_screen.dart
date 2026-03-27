// lib/screens/voice_command_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/platform_voice_input_manager.dart';
import '../services/platform_speech_service.dart';
import '../services/gemini_data_processor.dart';
import '../services/gemini_audio_processor.dart';
import '../services/voice_settings_service.dart';
import '../services/voice_queue_service.dart';
import '../services/connectivity_service.dart';
import '../services/voice_feedback_service.dart';
import '../widgets/voice_input_widget.dart';
import '../widgets/voice_context_banner.dart';
import 'voice_entry_verification_screen.dart';
import 'voice_transcript_review_screen.dart';
import '../constants/theme_constants.dart';
import '../constants/app_constants.dart';
import '../models/voice_entry.dart';
import '../widgets/audio_input_widget.dart';
import '../widgets/drawer_widget.dart';
import '../services/auth_service.dart';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  static const _tutorialShownKey = 'voice_tutorial_shown';

  bool _showGuide = false;
  late PlatformVoiceInputManager _voiceManager;
  late PlatformSpeechService _speechService;
  late GeminiDataProcessor _dataProcessor;
  late GeminiAudioProcessor _audioProcessor;
  final VoiceQueueService _queueService = VoiceQueueService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final VoiceSettingsService _voiceSettings = VoiceSettingsService();

  int _pendingQueueCount = 0;
  bool _isOnline = true;
  String _voiceMode = VoiceSettingsService.modeStt;

  // Contesto sessione corrente
  int? _contextApiarioId;
  String? _contextApiarioNome;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _refreshQueueCount();
    _checkConnectivity();
    _voiceManager.addListener(_onVoiceManagerChanged);
    // Carica la modalità vocale e applica la chiave personale.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null && user.geminiApiKey.isNotEmpty) {
        _dataProcessor.setPersonalKey(user.geminiApiKey);
        _audioProcessor.setPersonalKey(user.geminiApiKey);
      }
      final mode = await _voiceSettings.getMode();
      if (mounted) setState(() => _voiceMode = mode);
      await _restoreVerificationDraft();
      await _restoreDraft();
      await _checkAndShowTutorial();
    });
  }

  void _onVoiceManagerChanged() {
    // Auto-save pending transcriptions as a crash-recovery draft.
    if (_voiceManager.isBatchMode) {
      if (_voiceManager.pendingTranscriptions.isNotEmpty) {
        // Fire-and-forget: SharedPreferences write is fast.
        _queueService.saveDraft(
          _voiceManager.pendingTranscriptions,
          _contextApiarioId,
          _contextApiarioNome,
        );
      } else {
        _queueService.clearDraft();
      }
    }

    if (_voiceManager.batchStopRequested) {
      _voiceManager.clearBatchStop();
      final transcriptions =
          List<String>.from(_voiceManager.pendingTranscriptions);
      if (transcriptions.isNotEmpty) {
        _handleTranscriptionsReady(transcriptions);
      }
    }
  }

  /// If the app was killed during a batch session, move the draft to the
  /// offline queue and notify the user via a snackbar.
  Future<void> _restoreDraft() async {
    final draft = await _queueService.loadDraft();
    if (draft == null) return;
    final raw = draft['transcriptions'] as List<dynamic>? ?? [];
    final transcriptions =
        raw.cast<String>().where((t) => t.isNotEmpty).toList();
    if (transcriptions.isEmpty) {
      await _queueService.clearDraft();
      return;
    }
    // Move to the offline queue so the user can process them at any time.
    await _queueService.clearDraft();
    await _queueService.addBatchToQueue(
      transcriptions,
      draft['apiario_id'] as int?,
      draft['apiario_nome'] as String?,
    );
    await _refreshQueueCount();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${transcriptions.length} trascrizioni recuperate dalla sessione precedente. '
          'Premi la coda per elaborarle.',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// If the app was killed during the verification step (Gemini tokens already
  /// spent), reload the draft and navigate straight to the verification screen.
  Future<void> _restoreVerificationDraft() async {
    final entries = await _queueService.loadVerificationDraft();
    if (entries.isEmpty) return;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Dati non salvati trovati'),
        content: Text(
          'Sono presenti ${entries.length} schede di controllo elaborate da Gemini '
          'che non sono state salvate. Vuoi riprenderle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('SCARTA'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('RIPRENDI'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      await _queueService.clearVerificationDraft();
      return;
    }

    if (!mounted) return;
    final batch = VoiceEntryBatch();
    for (final e in entries) batch.add(e);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceEntryVerificationScreen(
          batch: batch,
          onSuccess: (results) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dati recuperati e salvati (${results.length} record)'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_tutorialShownKey) ?? false;
    if (shown || !mounted) return;
    await prefs.setBool(_tutorialShownKey, true);
    await _showTutorialSheet();
  }

  Future<void> _showTutorialSheet() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoiceTutorialSheet(
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _initializeServices() {
    _speechService = PlatformSpeechService();
    _dataProcessor = GeminiDataProcessor();
    _audioProcessor = GeminiAudioProcessor();
    final feedbackService = VoiceFeedbackService();

    _voiceManager = PlatformVoiceInputManager(
      _speechService,
      _dataProcessor,
      feedbackService: feedbackService,
    );
  }

  Future<void> _checkConnectivity() async {
    final online = await _connectivityService.isConnected();
    if (mounted) {
      setState(() => _isOnline = online);
    }
  }

  Future<void> _refreshQueueCount() async {
    final count = await _queueService.getQueueCount();
    if (mounted) {
      setState(() => _pendingQueueCount = count);
    }
  }

  void _onApiarioSelected(int id, String nome) {
    setState(() {
      _contextApiarioId = id;
      _contextApiarioNome = nome;
    });
    _dataProcessor.setContext(id, nome);
    _audioProcessor.setContext(id, nome);
  }

  Future<void> _saveToOfflineQueue() async {
    final transcription = _voiceManager.getTranscription();
    if (transcription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna trascrizione da salvare')),
      );
      return;
    }
    await _queueService.addToQueue(
        transcription, _contextApiarioId, _contextApiarioNome);
    _voiceManager.clearError();
    await _refreshQueueCount();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trascrizione salvata in coda ($_pendingQueueCount in attesa)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _processOfflineQueue() async {
    final queue = await _queueService.getQueue();
    if (queue.isEmpty) return;
    if (!mounted) return;

    final transcriptions = queue
        .map((item) => item['transcription'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
    final allIds = queue
        .map((item) => item['id'] as String? ?? '')
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceTranscriptReviewScreen(
          initialTranscriptions: transcriptions,
          onLeave: (remaining) {
            // Replace the offline queue with whatever the user kept.
            _queueService.removeItemsFromQueue(allIds).then((_) async {
              for (final text in remaining) {
                // Reuse first original item's context as best effort.
                final ctx = queue.isNotEmpty ? queue[0] : null;
                await _queueService.addToQueue(
                  text,
                  ctx?['apiario_id'] as int?,
                  ctx?['apiario_nome'] as String?,
                );
              }
              _refreshQueueCount();
            });
          },
          onSendToAI: (editedTranscriptions) async {
            final entries = <VoiceEntry>[];
            // Track the index up to which items have been successfully
            // dispatched to Gemini so we can re-queue the rest on early stop.
            int firstUnprocessedIndex = 0;
            for (int i = 0; i < editedTranscriptions.length; i++) {
              final text = editedTranscriptions[i];
              if (text.isEmpty) {
                firstUnprocessedIndex = i + 1;
                continue;
              }
              // Best-effort: use stored per-item context by original index.
              if (i < queue.length) {
                _dataProcessor.setContext(
                  queue[i]['apiario_id'] as int?,
                  queue[i]['apiario_nome'] as String?,
                );
              } else {
                _dataProcessor.setContext(
                    _contextApiarioId, _contextApiarioNome);
              }
              final entry = await _dataProcessor.processVoiceInput(text);
              if (entry != null) entries.add(entry);
              if (_dataProcessor.lastCallWasRateLimit ||
                  _dataProcessor.lastCallWasNetworkError) break;
              // Only advance past this item when it was handled without
              // a hard stop — so a rate-limited item stays in "unprocessed".
              firstUnprocessedIndex = i + 1;
              if (i < editedTranscriptions.length - 1) {
                await Future.delayed(const Duration(seconds: 5));
              }
            }
            _dataProcessor.setContext(_contextApiarioId, _contextApiarioNome);

            if (entries.isEmpty) {
              // Nothing succeeded — leave original items in queue as-is.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_dataProcessor.error != null
                        ? 'Gemini: ${_dataProcessor.error}'
                        : 'Nessuna entry valida estratta dalla coda'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 6),
                  ),
                );
              }
              return false; // screen stays visible
            }

            // Some items succeeded: remove all originals (they have been
            // consumed into the edited transcriptions flow).
            await _queueService.removeItemsFromQueue(allIds);
            // Re-queue any edited transcriptions that were never reached due
            // to rate-limit / network error — preserving the user's edits.
            final unprocessed = editedTranscriptions
                .sublist(firstUnprocessedIndex)
                .where((t) => t.isNotEmpty)
                .toList();
            if (unprocessed.isNotEmpty) {
              final ctx = queue.isNotEmpty ? queue[0] : null;
              await _queueService.addBatchToQueue(
                unprocessed,
                ctx?['apiario_id'] as int?,
                ctx?['apiario_nome'] as String?,
              );
            }
            await _refreshQueueCount();

            if (!mounted) return false;
            Navigator.of(context).pop(); // close review screen

            final batch = VoiceEntryBatch();
            for (final e in entries) batch.add(e);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VoiceEntryVerificationScreen(
                  batch: batch,
                  onSuccess: (results) {
                    Navigator.of(context).pop();
                    final msg = unprocessed.isEmpty
                        ? 'Dati dalla coda salvati (${results.length} record)'
                        : 'Dati salvati (${results.length} record). '
                            '${unprocessed.length} trascrizioni rimaste in coda.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(msg),
                          backgroundColor: Colors.green),
                    );
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            );
            return true; // screen was popped

          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: AppConstants.voiceCommandRoute),
      appBar: AppBar(
        title: const Text('Inserimento vocale'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        actions: [
          // Badge coda offline
          if (_pendingQueueCount > 0)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.queue),
                  onPressed: _processOfflineQueue,
                  tooltip: 'Elabora coda offline',
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_pendingQueueCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          // Tutorial / guide toggle
          IconButton(
            icon: Icon(_showGuide ? Icons.help : Icons.help_outline),
            onPressed: () async {
              if (!_showGuide) {
                // Se la guida è nascosta, mostrare il tutorial bottom sheet
                // (permette di rivedere il tutorial in modo completo)
                await _showTutorialSheet();
              } else {
                setState(() => _showGuide = false);
              }
            },
            tooltip: _showGuide ? 'Nascondi guida' : 'Rivedi tutorial',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Context banner
              VoiceContextBanner(
                onApiarioSelected: _onApiarioSelected,
                isOnline: _isOnline,
              ),

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
                            icon: Icons.hive,
                            title: 'Seleziona apiario',
                            description:
                                'Tocca il banner in cima per scegliere l\'apiario. Poi basta dire solo il numero arnia.',
                          ),
                          _buildGuideItem(
                            icon: Icons.mic,
                            title: 'Inizia a parlare',
                            description:
                                'Premi il pulsante microfono e parla chiaramente',
                          ),
                          _buildGuideItem(
                            icon: Icons.check_circle,
                            title: 'Verifica e salva',
                            description:
                                'Controlla i dati riconosciuti da Gemini prima di salvarli',
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Esempi:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildCommandExample(
                              '"Arnia 3, regina presente, vista, 4 telaini di covata, 3 scorte"'),
                          _buildCommandExample(
                              '"Arnia 7, famiglia forte, problemi sanitari, varroa"'),
                          _buildCommandExample(
                              '"Arnia 2, 7 telaini totali, celle reali 2, rischio sciamatura"'),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 4),
                          const Text(
                            'Parole chiave modalità multipla:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          _buildCommandExample(
                              '"avanti" / "ok" / "vai" / "continua" → registra arnia successiva'),
                          _buildCommandExample(
                              '"stop" / "fine" / "basta" / "finito" → termina il batch e vai alla revisione'),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Senza connessione: usa "Salva per dopo" e riprendi quando sei online.',
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

              // Voice input widget (STT) o Audio input widget
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _voiceMode == VoiceSettingsService.modeAudio
                    ? AudioInputWidget(
                        processor: _audioProcessor,
                        onEntriesReady: _handleEntriesReady,
                        contextApiarioId: _contextApiarioId,
                        contextApiarioNome: _contextApiarioNome,
                      )
                    : ChangeNotifierProvider<PlatformVoiceInputManager>.value(
                        value: _voiceManager,
                        child: Column(
                          children: [
                            VoiceInputWidget(
                              onEntriesReady: _handleEntriesReady,
                              onTranscriptionsReady:
                                  _handleTranscriptionsReady,
                            ),
                            // Mostra "Salva per dopo" se c'è un errore di rete
                            ListenableBuilder(
                              listenable: _voiceManager,
                              builder: (context, _) {
                                final hasError = _voiceManager.error != null;
                                final hasTranscription = _voiceManager
                                    .getTranscription()
                                    .isNotEmpty;
                                if (!hasError || !hasTranscription) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.save_outlined,
                                        color: Colors.orange),
                                    label: const Text(
                                      'Salva per dopo',
                                      style:
                                          TextStyle(color: Colors.orange),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Colors.orange),
                                    ),
                                    onPressed: _saveToOfflineQueue,
                                  ),
                                );
                              },
                            ),
                          ],
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ThemeConstants.primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                        color: ThemeConstants.textSecondaryColor)),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          example,
          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
        ),
      ),
    );
  }

  /// Called when batch transcriptions are ready for review
  /// (either via "Rivedi" button or "stop" trigger word).
  void _handleTranscriptionsReady(List<String> transcriptions) {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceTranscriptReviewScreen(
          initialTranscriptions: transcriptions,
          onLeave: (remaining) {
            // Always clear the manager's pending list regardless.
            _voiceManager.clearBatch();
            // If the user kept some items, save them to the offline queue.
            if (remaining.isNotEmpty) {
              _queueService
                  .addBatchToQueue(
                      remaining, _contextApiarioId, _contextApiarioNome)
                  .then((_) => _refreshQueueCount());
            }
          },
          onSendToAI: (editedTranscriptions) async {
            _voiceManager.setPendingTranscriptions(editedTranscriptions);
            final batch = await _voiceManager.processPendingBatch();

            if (!mounted) return false;

            final failed = _voiceManager.lastBatchFailedTranscriptions;

            if (batch.entries.isEmpty) {
              // Full failure: screen stays open so the user can see the
              // transcriptions and retry. When they press back, onLeave
              // will save them to the offline queue.
              final errDetail = _dataProcessor.error;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    errDetail != null
                        ? 'Gemini: $errDetail'
                        : 'Nessun dato valido estratto. '
                            'Controlla le trascrizioni e riprova.',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 6),
                ),
              );
              return false; // screen stays visible, _processingComplete = false
            }

            // Partial or full success: save any items Gemini couldn't process
            // to the offline queue BEFORE popping (onLeave won't be called).
            if (failed.isNotEmpty) {
              await _queueService.addBatchToQueue(
                  failed, _contextApiarioId, _contextApiarioNome);
              await _refreshQueueCount();
            }

            Navigator.of(context).pop();

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VoiceEntryVerificationScreen(
                  batch: batch,
                  onSuccess: (results) {
                    _voiceManager.clearBatch();
                    Navigator.of(context).pop();
                    final msg = failed.isEmpty
                        ? 'Dati salvati (${results.length} record)'
                        : 'Dati salvati (${results.length} record). '
                            '${failed.length} trascrizioni in coda.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(msg),
                          backgroundColor: Colors.green),
                    );
                  },
                  onCancel: () {
                    _voiceManager.clearBatch();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
            return true; // screen was popped, _processingComplete = true
          },
        ),
      ),
    );
  }

  void _handleEntriesReady(batch) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceEntryVerificationScreen(
          batch: batch,
          onSuccess: (results) {
            Navigator.of(context).pop();
            _voiceManager.clearBatch();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Dati salvati con successo (${results.length} record)'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceManager.removeListener(_onVoiceManagerChanged);
    _voiceManager.dispose();
    _speechService.dispose();
    _dataProcessor.dispose();
    _audioProcessor.dispose();
    _connectivityService.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Tutorial bottom sheet — primo accesso e richiamabile dall'AppBar
// ---------------------------------------------------------------------------
class _VoiceTutorialSheet extends StatelessWidget {
  final VoidCallback onDismiss;

  const _VoiceTutorialSheet({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mic,
                          color: ThemeConstants.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inserimento vocale',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.primaryColor,
                            ),
                          ),
                          const Text(
                            'Come registrare un\'ispezione a mani libere',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _tutorialSection(
                      step: '1',
                      icon: Icons.hive,
                      title: 'Seleziona l\'apiario',
                      body:
                          'Tocca il banner arancione in cima e scegli l\'apiario su cui stai lavorando. '
                          'Da quel momento basterà dire solo il numero dell\'arnia — non serve ripeterlo ogni volta.',
                      color: Colors.orange,
                    ),
                    _tutorialSection(
                      step: '2',
                      icon: Icons.mic,
                      title: 'Parla chiaramente',
                      body:
                          'Premi il pulsante microfono e descrivi l\'ispezione come faresti con un collega. '
                          'Non serve una sintassi precisa: l\'AI capisce il linguaggio naturale.',
                      color: ThemeConstants.primaryColor,
                    ),
                    _tutorialSection(
                      step: '3',
                      icon: Icons.auto_awesome,
                      title: 'Gemini interpreta il testo',
                      body:
                          'Il testo riconosciuto viene inviato a Gemini AI che estrae automaticamente: '
                          'numero arnia, telaini, stato regina, problemi sanitari e altro ancora.',
                      color: Colors.deepPurple,
                    ),
                    _tutorialSection(
                      step: '4',
                      icon: Icons.check_circle_outline,
                      title: 'Verifica e salva',
                      body:
                          'Controlla i dati interpretati nella schermata di verifica, '
                          'modifica eventuali errori e premi Salva.',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    // Esempi
                    _sectionTitle('Esempi di frasi'),
                    const SizedBox(height: 8),
                    _exampleChip(
                        '"Arnia 3, regina presente, vista, 4 telaini di covata, 3 scorte"'),
                    _exampleChip(
                        '"Arnia 7, famiglia forte, problemi sanitari, varroa"'),
                    _exampleChip(
                        '"Arnia 2, 7 telaini totali, 2 celle reali, rischio sciamatura"'),
                    const SizedBox(height: 16),
                    // Modalità multipla
                    _sectionTitle('Modalità multipla (più arnie di seguito)'),
                    const SizedBox(height: 8),
                    _infoRow(
                        Icons.skip_next,
                        '"avanti" / "ok" / "vai" / "continua"',
                        'registra l\'arnia successiva'),
                    _infoRow(
                        Icons.stop_circle_outlined,
                        '"stop" / "fine" / "basta" / "finito"',
                        'termina il batch e vai alla revisione'),
                    const SizedBox(height: 16),
                    // Offline
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Senza connessione usa "Salva per dopo": le trascrizioni vengono '
                              'messe in coda e puoi elaborarle non appena torni online.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // CTA
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.mic),
                        label: const Text('Inizia a registrare'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ThemeConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onDismiss,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tutorialSection({
    required String step,
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: ThemeConstants.primaryColor,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _exampleChip(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
      ),
    );
  }

  Widget _infoRow(IconData icon, String keyword, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: keyword,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' → $description'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
