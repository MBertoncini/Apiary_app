// lib/screens/voice_command_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/platform_voice_input_manager.dart';
import '../services/platform_speech_service.dart';
import '../services/gemini_data_processor.dart';
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
import '../widgets/drawer_widget.dart';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  bool _showGuide = false;
  late PlatformVoiceInputManager _voiceManager;
  late PlatformSpeechService _speechService;
  late GeminiDataProcessor _dataProcessor;
  final VoiceQueueService _queueService = VoiceQueueService();
  final ConnectivityService _connectivityService = ConnectivityService();

  int _pendingQueueCount = 0;
  bool _isOnline = true;

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
  }

  void _onVoiceManagerChanged() {
    if (_voiceManager.batchStopRequested) {
      _voiceManager.clearBatchStop();
      final transcriptions =
          List<String>.from(_voiceManager.pendingTranscriptions);
      if (transcriptions.isNotEmpty) {
        _handleTranscriptionsReady(transcriptions);
      }
    }
  }

  void _initializeServices() {
    _speechService = PlatformSpeechService();
    _dataProcessor = GeminiDataProcessor();
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
            for (int i = 0; i < editedTranscriptions.length; i++) {
              final text = editedTranscriptions[i];
              if (text.isEmpty) continue;
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
              if (i < editedTranscriptions.length - 1) {
                await Future.delayed(const Duration(seconds: 5));
              }
            }
            _dataProcessor.setContext(_contextApiarioId, _contextApiarioNome);

            if (entries.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_dataProcessor.error != null
                        ? 'Errore: ${_dataProcessor.error}'
                        : 'Nessuna entry valida estratta dalla coda'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // On success: remove the processed items from the queue.
            await _queueService.removeItemsFromQueue(allIds);
            await _refreshQueueCount();

            if (!mounted) return;
            Navigator.of(context).pop(); // close review screen

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
                        content: Text(
                            'Dati dalla coda salvati (${results.length} record)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            );
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
          // Guide toggle
          IconButton(
            icon: Icon(_showGuide ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showGuide = !_showGuide),
            tooltip: _showGuide ? 'Nascondi guida' : 'Mostra guida',
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

              // Voice input widget + pulsante "Salva per dopo"
              ChangeNotifierProvider<PlatformVoiceInputManager>.value(
                value: _voiceManager,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      VoiceInputWidget(
                        onEntriesReady: _handleEntriesReady,
                        onTranscriptionsReady: _handleTranscriptionsReady,
                      ),
                      // Mostra "Salva per dopo" se c'è un errore di rete
                      ListenableBuilder(
                        listenable: _voiceManager,
                        builder: (context, _) {
                          final hasError = _voiceManager.error != null;
                          final hasTranscription =
                              _voiceManager.getTranscription().isNotEmpty;
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
                                style: TextStyle(color: Colors.orange),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
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

            if (!mounted) return;
            if (batch.entries.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Nessun dato valido estratto. Controlla le trascrizioni.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.of(context).pop();
            _voiceManager.clearBatch();

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VoiceEntryVerificationScreen(
                  batch: batch,
                  onSuccess: (results) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dati salvati (${results.length} record)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            );
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
    _connectivityService.dispose();
    super.dispose();
  }
}
