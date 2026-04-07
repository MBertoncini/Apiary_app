// lib/widgets/audio_input_widget.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../models/voice_entry.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_queue_service.dart';
import '../services/gemini_audio_processor.dart';
import '../services/storage_service.dart';

/// Widget per la modalità "Registra audio → Gemini multimodale" con supporto
/// per inserimento multiplo (multi-arnia).
///
/// Flusso per ogni arnia:
///   1. Premi ● Registra → parla → premi ■ Stop
///   2. **Riascolta** (opzionale) o invia direttamente a Gemini
///   3. "Invia a Gemini" → analisi → entry aggiunta al batch
///   4. In caso di errore: riprova, salva in coda (solo offline/rate-limit)
///      o scarta la registrazione
///   5. Ripeti per ogni arnia; "STOP – Rivedi" manda il batch alla verifica
///   6. "Annulla sessione" elimina tutto con conferma
class AudioInputWidget extends StatefulWidget {
  final GeminiAudioProcessor processor;
  final Function(VoiceEntryBatch) onEntriesReady;
  final int? contextApiarioId;
  final String? contextApiarioNome;

  const AudioInputWidget({
    Key? key,
    required this.processor,
    required this.onEntriesReady,
    this.contextApiarioId,
    this.contextApiarioNome,
  }) : super(key: key);

  @override
  State<AudioInputWidget> createState() => _AudioInputWidgetState();
}

enum _RecState { idle, recording, recorded, extending, processing, processingQueue, error }

class _AudioInputWidgetState extends State<AudioInputWidget> {
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioQueueService _audioQueue = AudioQueueService();
  final AudioPlayer _player = AudioPlayer();

  final List<VoiceEntry> _entries = [];
  _RecState _state = _RecState.idle;
  String? _error;

  // Durata registrazione corrente (in secondi)
  int _seconds = 0;
  // Durata dell'ultima registrazione completata (mostrata nello stato recorded)
  int _recordedSeconds = 0;
  Timer? _durationTimer;

  // File corrente registrato, non ancora elaborato da Gemini
  String? _pendingFilePath;

  // Playback
  PlayerState _playerState = PlayerState.stopped;
  Duration _playerPosition = Duration.zero;
  Duration _playerDuration = Duration.zero;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  // Coda audio offline
  int _queueCount = 0;
  int _queueProcessedCount = 0;
  int _queueTotalCount = 0;
  List<Map<String, dynamic>> _queueItems = [];
  String? _playingQueueItemId;

  // Entry parziale: Gemini ha estratto dati ma il numero arnia è assente
  VoiceEntry? _partialEntry;
  List<Map<String, dynamic>> _availableArnie = [];

  @override
  void initState() {
    super.initState();
    _refreshQueueCount();
    _playerStateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() {
        _playerState = s;
        if (s == PlayerState.stopped || s == PlayerState.completed) {
          _playingQueueItemId = null;
        }
      });
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _playerPosition = p);
    });
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _playerDuration = d);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    // Pulisce i file pendenti non ancora salvati né processati
    if (_pendingFilePath != null) {
      AudioQueueService.deleteFile(_pendingFilePath!);
    }
    if (_partialEntry?.audioFilePath != null &&
        _partialEntry!.audioFilePath != _pendingFilePath) {
      AudioQueueService.deleteFile(_partialEntry!.audioFilePath!);
    }
    super.dispose();
  }

  Future<void> _refreshQueueCount() async {
    final items = await _audioQueue.getQueue();
    if (mounted) setState(() {
      _queueItems = items;
      _queueCount = items.length;
    });
  }

  Future<void> _playQueueItem(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final filePath = item['file_path'] as String?;
    if (filePath == null) return;
    if (_playingQueueItemId == id && _playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      _playingQueueItemId = id;
      await _player.play(DeviceFileSource(filePath));
    }
  }

  Future<void> _deleteQueueItem(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final filePath = item['file_path'] as String?;
    if (_playingQueueItemId == id) await _player.stop();
    await _audioQueue.removeFromQueue(id);
    if (filePath != null) await AudioQueueService.deleteFile(filePath);
    await _refreshQueueCount();
  }

  // ── Registrazione ─────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_playerState == PlayerState.playing) await _player.stop();
    final ok = await _recorder.startRecording();
    if (!ok) {
      setState(() {
        _state = _RecState.error;
        _error = 'Impossibile avviare la registrazione. '
            'Verifica il permesso microfono.';
      });
      return;
    }
    _durationTimer?.cancel();
    _seconds = 0;
    _durationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    setState(() {
      _state = _RecState.recording;
      _error = null;
      _pendingFilePath = null;
    });
  }

  /// Ferma la registrazione e passa allo stato [_RecState.recorded]
  /// senza inviare subito a Gemini, dando all'utente la possibilità
  /// di riascoltare prima.
  Future<void> _stopRecording() async {
    _durationTimer?.cancel();
    final path = await _recorder.stopRecording();
    if (path == null) {
      setState(() {
        _state = _RecState.error;
        _error = 'Registrazione non valida. Riprova.';
      });
      return;
    }
    _pendingFilePath = path;
    _recordedSeconds = _seconds;
    _playerPosition = Duration.zero;
    _playerDuration = Duration.zero;
    await _saveToQueue();
  }

  // ── Estensione registrazione ──────────────────────────────────────────────

  /// Avvia una nuova registrazione da aggiungere in coda a quella esistente.
  Future<void> _startExtending() async {
    if (_playerState == PlayerState.playing) await _player.stop();
    final ok = await _recorder.startRecording();
    if (!ok) {
      setState(() {
        _state = _RecState.error;
        _error = 'Impossibile avviare la registrazione. '
            'Verifica il permesso microfono.';
      });
      return;
    }
    _durationTimer?.cancel();
    _seconds = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    setState(() {
      _state = _RecState.extending;
      _error = null;
    });
  }

  /// Ferma l'estensione e concatena il nuovo segmento all'audio esistente.
  Future<void> _stopExtending() async {
    _durationTimer?.cancel();
    final newPath = await _recorder.stopRecording();
    if (newPath == null) {
      setState(() {
        _state = _RecState.error;
        _error = 'Estensione non valida. Riprova.';
      });
      return;
    }

    if (_pendingFilePath != null && _pendingFilePath != newPath) {
      final merged = await _appendAudioFiles(_pendingFilePath!, newPath);
      if (merged == null) {
        // fallback: usa solo il nuovo segmento
        await AudioQueueService.deleteFile(_pendingFilePath!);
        _pendingFilePath = newPath;
      }
      // se merged != null, _pendingFilePath è già aggiornato in-place
    } else {
      _pendingFilePath = newPath;
    }

    _recordedSeconds += _seconds;
    _playerPosition = Duration.zero;
    _playerDuration = Duration.zero;
    await _saveToQueue();
  }

  /// Concatena due file AAC-ADTS in-place (il formato ADTS è self-framing,
  /// la concatenazione diretta dei byte produce un file riproduble).
  Future<String?> _appendAudioFiles(
      String basePath, String appendPath) async {
    try {
      final baseFile = File(basePath);
      final appendFile = File(appendPath);
      if (!baseFile.existsSync() || !appendFile.existsSync()) return null;

      final baseBytes = await baseFile.readAsBytes();
      final appendBytes = await appendFile.readAsBytes();

      final merged = Uint8List(baseBytes.length + appendBytes.length);
      merged.setAll(0, baseBytes);
      merged.setAll(baseBytes.length, appendBytes);

      await baseFile.writeAsBytes(merged, flush: true);
      await appendFile.delete();
      return basePath;
    } catch (e) {
      debugPrint('[AudioInputWidget] _appendAudioFiles error: $e');
      return null;
    }
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  Future<void> _togglePlayback() async {
    if (_pendingFilePath == null) return;
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(_pendingFilePath!));
    }
  }

  // ── Gemini ────────────────────────────────────────────────────────────────

  Future<void> _sendToGemini() async {
    if (_pendingFilePath == null) return;
    if (_playerState == PlayerState.playing) await _player.stop();
    final path = _pendingFilePath!;
    setState(() => _state = _RecState.processing);
    await _processFile(path);
  }

  Future<bool> _processFile(String filePath) async {
    final entry = await widget.processor.processAudioInput(filePath);
    if (entry != null && entry.isValid()) {
      final entryWithAudio = entry.copyWith(audioFilePath: filePath);
      setState(() {
        _entries.add(entryWithAudio);
        _partialEntry = null;
        _availableArnie = [];
        _state = _RecState.idle;
        _error = null;
        _pendingFilePath = null;
      });
      return true;
    } else if (entry != null && !entry.isValid()) {
      // Gemini ha estratto dati utili ma manca il numero/id arnia: mostra picker
      await _loadArnieForPicker();
      setState(() {
        _partialEntry = entry.copyWith(audioFilePath: filePath);
        _state = _RecState.error;
        _error = 'Numero arnia non rilevato dall\'audio. '
            'Seleziona l\'arnia dal menu oppure aggiungi audio con il numero.';
        // _pendingFilePath rimane per "Continua registrazione"
      });
      return false;
    } else {
      setState(() {
        _partialEntry = null;
        _availableArnie = [];
        _state = _RecState.error;
        _error = widget.processor.error ??
            'Non è stato possibile estrarre dati dall\'audio. Riprova.';
        // _pendingFilePath rimane valorizzato per "Riprova"
      });
      return false;
    }
  }

  /// Carica le arnie disponibili da cache locale, filtrate per apiario se
  /// il contesto di sessione è impostato.
  Future<void> _loadArnieForPicker() async {
    if (!mounted) return;
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final allArnie = await storageService.getStoredData('arnie');
      final filtered = widget.contextApiarioId != null
          ? allArnie
              .where((a) => a['apiario'] == widget.contextApiarioId)
              .cast<Map<String, dynamic>>()
              .toList()
          : List<Map<String, dynamic>>.from(allArnie);
      filtered.sort((a, b) =>
          (a['numero'] as int? ?? 0).compareTo(b['numero'] as int? ?? 0));
      if (mounted) setState(() => _availableArnie = filtered);
    } catch (_) {
      // StorageService non disponibile: il picker mostrerà lista vuota
    }
  }

  /// Completa l'entry parziale assegnando l'arnia selezionata dal picker.
  void _confirmWithArnia(Map<String, dynamic> arnia) {
    if (_partialEntry == null) return;
    var completed = _partialEntry!.copyWith(
      arniaId: arnia['id'] as int?,
      arniaNumero: arnia['numero'] as int?,
      apiarioId:
          (arnia['apiario'] as int?) ?? _partialEntry!.apiarioId,
    );
    if (_pendingFilePath != null &&
        _partialEntry!.audioFilePath != _pendingFilePath) {
      // Il file audio è stato esteso dopo l'errore: aggiorna il path
      completed = completed.copyWith(audioFilePath: _pendingFilePath);
    }
    setState(() {
      _entries.add(completed);
      _partialEntry = null;
      _availableArnie = [];
      _state = _RecState.idle;
      _error = null;
      _pendingFilePath = null;
    });
  }

  // ── Scarto / Annulla ──────────────────────────────────────────────────────

  Future<void> _discardRecording() async {
    if (_playerState == PlayerState.playing) await _player.stop();
    if (_pendingFilePath != null) {
      await AudioQueueService.deleteFile(_pendingFilePath!);
      _pendingFilePath = null;
    }
    setState(() {
      _partialEntry = null;
      _availableArnie = [];
      _state = _RecState.idle;
      _error = null;
    });
  }

  Future<void> _abandonSession() async {
    final hasData = _entries.isNotEmpty || _pendingFilePath != null;
    if (!hasData) return;

    final count = _entries.length + _queueCount;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annulla sessione?'),
        content: Text(
          count == 0
              ? 'La registrazione corrente verrà eliminata.'
              : 'Verranno eliminate tutte le $count registrazione/i '
                  'della sessione.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('INDIETRO'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINA TUTTO',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    if (_playerState == PlayerState.playing) await _player.stop();
    if (_pendingFilePath != null) {
      await AudioQueueService.deleteFile(_pendingFilePath!);
      _pendingFilePath = null;
    }
    for (final entry in _entries) {
      if (entry.audioFilePath != null) {
        await AudioQueueService.deleteFile(entry.audioFilePath!);
      }
    }
    await _audioQueue.clearQueueAndFiles();
    await _refreshQueueCount();
    setState(() {
      _entries.clear();
      _state = _RecState.idle;
      _error = null;
    });
  }

  // ── Coda audio offline ────────────────────────────────────────────────────

  Future<void> _saveToQueue() async {
    if (_pendingFilePath == null) return;
    await _audioQueue.addToQueue(
      filePath: _pendingFilePath!,
      apiarioId: widget.contextApiarioId,
      apiarioNome: widget.contextApiarioNome,
      recordingDurationSeconds: _recordedSeconds,
    );
    _pendingFilePath = null;
    await _refreshQueueCount();
    setState(() {
      _state = _RecState.idle;
      _error = null;
    });
  }

  Future<void> _processQueue() async {
    final queue = await _audioQueue.getQueue();
    if (queue.isEmpty) return;

    setState(() {
      _state = _RecState.processingQueue;
      _queueTotalCount = queue.length;
      _queueProcessedCount = 0;
      _error = null;
    });

    for (int i = 0; i < queue.length; i++) {
      final item = queue[i];
      final id = item['id'] as String;
      final filePath = item['file_path'] as String?;
      final apiarioId = item['apiario_id'] as int?;
      final apiarioNome = item['apiario_nome'] as String?;

      if (filePath == null) {
        await _audioQueue.removeFromQueue(id);
        continue;
      }

      widget.processor.setContext(apiarioId, apiarioNome);
      final entry = await widget.processor.processAudioInput(filePath);

      if (entry != null && entry.isValid()) {
        await _audioQueue.removeFromQueue(id);
        final entryWithAudio = entry.copyWith(audioFilePath: filePath);
        setState(() {
          _entries.add(entryWithAudio);
          _queueProcessedCount++;
        });
      } else if (entry != null && !entry.isValid()) {
        // Gemini ha estratto dati ma manca il numero arnia:
        // sposta la registrazione come pendente per il picker manuale
        await _audioQueue.removeFromQueue(id);
        await _loadArnieForPicker();
        setState(() {
          _partialEntry = entry.copyWith(audioFilePath: filePath);
          _pendingFilePath = filePath;
          _state = _RecState.error;
          _error = 'Numero arnia non rilevato in una registrazione. '
              'Seleziona l\'arnia dal menu oppure aggiungi audio con il numero.';
          _queueProcessedCount++;
        });
        break; // attende la risoluzione manuale prima di continuare
      } else {
        if (widget.processor.lastCallWasRateLimit ||
            widget.processor.lastCallWasNetworkError) break;
        // Errore non recuperabile: informa l'utente prima di eliminare
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registrazione ${i + 1}/${ queue.length} non elaborata: '
                '${widget.processor.error ?? 'errore sconosciuto'}',
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        await _audioQueue.removeFromQueue(id);
        await AudioQueueService.deleteFile(filePath);
        setState(() => _queueProcessedCount++);
      }

      if (i < queue.length - 1 &&
          !widget.processor.lastCallWasRateLimit &&
          !widget.processor.lastCallWasNetworkError) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    widget.processor.setContext(
        widget.contextApiarioId, widget.contextApiarioNome);
    await _refreshQueueCount();
    setState(() => _state = _RecState.idle);

    if (_entries.isNotEmpty) {
      _goToVerification();
    }
  }

  // ── Navigazione ───────────────────────────────────────────────────────────

  void _goToVerification() {
    if (_entries.isEmpty) return;
    final batch = VoiceEntryBatch();
    for (final e in _entries) batch.add(e);
    setState(() => _entries.clear());
    widget.onEntriesReady(batch);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool get _hasActiveSession =>
      _entries.isNotEmpty || _pendingFilePath != null || _queueCount > 0;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusText(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _state == _RecState.error
                        ? Colors.red.shade700
                        : ThemeConstants.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          const Color(0xFF4285F4).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 12, color: Color(0xFF4285F4)),
                    SizedBox(width: 4),
                    Text('Audio AI',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Area centrale ─────────────────────────────────────────────────
          _buildCentralArea(),

          // ── Messaggio errore ──────────────────────────────────────────────
          if (_state == _RecState.error && _error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _partialEntry != null
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _partialEntry != null
                        ? Colors.orange.shade200
                        : Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _partialEntry != null
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    size: 16,
                    color: _partialEntry != null
                        ? Colors.orange.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                          fontSize: 13,
                          color: _partialEntry != null
                              ? Colors.orange.shade800
                              : Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
            if (_partialEntry != null && _availableArnie.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildArniaPickerSection(),
            ],
          ],

          // ── Lista batch arnie ─────────────────────────────────────────────
          if (_entries.isNotEmpty) _buildBatchList(),

          // ── Lista registrazioni in sessione ──────────────────────────
          if (_queueItems.isNotEmpty) _buildSessionQueueList(),

          // ── Bottoni ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  // ── Area centrale per stato ───────────────────────────────────────────────

  Widget _buildCentralArea() {
    switch (_state) {
      case _RecState.processing:
      case _RecState.processingQueue:
        return SizedBox(
          width: 160,
          height: 160,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 14),
                Text(
                  _state == _RecState.processingQueue
                      ? 'Coda: $_queueProcessedCount/$_queueTotalCount…'
                      : 'Gemini sta elaborando…',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        );

      case _RecState.recorded:
        return _buildPlaybackCircle();

      case _RecState.recording:
      case _RecState.extending:
        final isExtending = _state == _RecState.extending;
        final circleColor =
            isExtending ? Colors.amber.shade700 : Colors.red.shade600;
        final glowColor = isExtending
            ? Colors.amber.withValues(alpha: 0.40)
            : Colors.red.withValues(alpha: 0.40);
        return GestureDetector(
          onTap: isExtending ? _stopExtending : _stopRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 22,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stop, color: Colors.white, size: 52),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_seconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (isExtending) ...[
                  const SizedBox(height: 2),
                  const Text(
                    '+',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

      case _RecState.idle:
      case _RecState.error:
        final active = _state == _RecState.idle;
        return GestureDetector(
          onTap: active ? _startRecording : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? ThemeConstants.primaryColor
                  : Colors.grey.shade300,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: ThemeConstants.primaryColor
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.mic,
              color:
                  active ? Colors.white : Colors.grey.shade500,
              size: 64,
            ),
          ),
        );
    }
  }

  /// Cerchio di playback (stato `recorded`)
  Widget _buildPlaybackCircle() {
    final isPlaying = _playerState == PlayerState.playing;
    final hasProgress = _playerDuration.inMilliseconds > 0;
    final progress = hasProgress
        ? _playerPosition.inMilliseconds / _playerDuration.inMilliseconds
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cerchio con progress ring
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: hasProgress ? progress.clamp(0.0, 1.0) : 0.0,
                strokeWidth: 4,
                backgroundColor: Colors.indigo.shade100,
                valueColor:
                    AlwaysStoppedAnimation(Colors.indigo.shade400),
              ),
            ),
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.shade50,
                border: Border.all(
                    color: Colors.indigo.shade200, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Durata o posizione
                  Text(
                    hasProgress && isPlaying
                        ? _formatDur(_playerPosition)
                        : _formatDuration(_recordedSeconds),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (hasProgress)
                    Text(
                      '/ ${_formatDur(_playerDuration)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.indigo.shade400),
                    ),
                  const SizedBox(height: 8),
                  // Bottone play/pause
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.indigo.shade600,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isPlaying ? 'In ascolto…' : 'Ascolta prima di inviare',
          style: TextStyle(
              fontSize: 12, color: Colors.indigo.shade400),
        ),
      ],
    );
  }

  // ── Picker arnia (quando numero non rilevato dall'audio) ─────────────────

  Widget _buildArniaPickerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona arnia:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: null,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.amber.shade400)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.amber.shade400)),
            ),
            hint: const Text('Scegli arnia…',
                style: TextStyle(fontSize: 13)),
            items: _availableArnie.map((a) {
              final num = a['numero'] as int? ?? 0;
              return DropdownMenuItem<Map<String, dynamic>>(
                value: a,
                child: Text('Arnia $num',
                    style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (arnia) {
              if (arnia != null) _confirmWithArnia(arnia);
            },
          ),
        ],
      ),
    );
  }

  // ── Lista batch (chips arnie) ─────────────────────────────────────────────

  Widget _buildBatchList() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_add_check,
                  size: 15, color: ThemeConstants.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Batch: ${_entries.length} arni${_entries.length == 1 ? 'a' : 'e'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _entries.asMap().entries.map((e) {
                final entry = e.value;
                final label = entry.arniaNumero != null
                    ? 'Arnia ${entry.arniaNumero}'
                    : 'Entry ${e.key + 1}';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    label: Text(label,
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: ThemeConstants.primaryColor
                        .withValues(alpha: 0.10),
                    side: BorderSide(
                        color: ThemeConstants.primaryColor
                            .withValues(alpha: 0.35)),
                    avatar: Icon(Icons.hive,
                        size: 14,
                        color: ThemeConstants.primaryColor),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista registrazioni salvate in sessione ───────────────────────────────

  Widget _buildSessionQueueList() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.queue_music,
                  size: 15, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Text(
                'Sessione: ${_queueItems.length} registrazione/i da inviare',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_queueItems.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final id = item['id'] as String;
            final filePath = item['file_path'] as String?;
            final ts = item['timestamp'] as String?;
            final durSec = item['duration_seconds'] as int?;
            final isPlaying = _playingQueueItemId == id &&
                _playerState == PlayerState.playing;
            DateTime? dt;
            if (ts != null) {
              try {
                dt = DateTime.parse(ts);
              } catch (_) {}
            }
            final timeStr = dt != null
                ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                : null;
            final durStr =
                durSec != null ? _formatDuration(durSec) : null;
            final label = [
              'Registrazione ${idx + 1}',
              if (timeStr != null) timeStr,
              if (durStr != null) durStr,
            ].join(' · ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mic,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (filePath != null)
                      GestureDetector(
                        onTap: () => _playQueueItem(item),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.shade700,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _deleteQueueItem(item),
                      child: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red.shade400),
                    ),
                  ],
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  // ── Bottoni contestuali ───────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final buttons = <Widget>[];

    switch (_state) {
      case _RecState.recorded:
        break;

      // ── Error: gestione differenziata in base al tipo di errore ───
      case _RecState.error:
        if (_partialEntry != null && _pendingFilePath != null) {
          // Gemini ha estratto dati ma manca il numero arnia:
          // offri di estendere l'audio o di scartare
          buttons.add(OutlinedButton.icon(
            onPressed: _startExtending,
            icon: const Icon(Icons.mic, size: 16, color: Colors.amber),
            label: const Text('Aggiungi audio con n° arnia',
                style: TextStyle(color: Colors.amber)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber)),
          ));
          buttons.add(OutlinedButton.icon(
            onPressed: _discardRecording,
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.red),
            label: const Text('Scarta',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red)),
          ));
        } else if (_pendingFilePath != null) {
          // Errore Gemini generico: riprova o salva in coda
          buttons.add(ElevatedButton.icon(
            onPressed: () async {
              final path = _pendingFilePath!;
              setState(() => _state = _RecState.processing);
              await _processFile(path);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Riprova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ));
          // "Salva in coda" solo per errori di rete/rate-limit
          if (widget.processor.lastCallWasNetworkError ||
              widget.processor.lastCallWasRateLimit) {
            buttons.add(OutlinedButton.icon(
              onPressed: _saveToQueue,
              icon: const Icon(Icons.save_outlined,
                  color: Colors.orange, size: 16),
              label: const Text('Salva in coda',
                  style: TextStyle(color: Colors.orange)),
              style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: Colors.orange)),
            ));
          }
          buttons.add(OutlinedButton.icon(
            onPressed: _discardRecording,
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.red),
            label: const Text('Scarta',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red)),
          ));
        } else {
          // Nessun file pendente (es. errore permesso microfono)
          buttons.add(ElevatedButton.icon(
            onPressed: () => setState(() {
              _state = _RecState.idle;
              _error = null;
            }),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Riprova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          ));
        }
        break;

      // ── Idle: "Invia tutto a Gemini" se ci sono registrazioni ────
      case _RecState.idle:
        if (_queueCount > 0) {
          buttons.add(ElevatedButton.icon(
            onPressed: _processQueue,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text('Invia tutto a Gemini ($_queueCount)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ));
        }
        break;

      case _RecState.recording:
      case _RecState.extending:
      case _RecState.processing:
      case _RecState.processingQueue:
        break;
    }

    // ── "STOP – Rivedi" (visibile quando c'è batch e non si sta registrando)
    final canReview = _entries.isNotEmpty &&
        _state != _RecState.recording &&
        _state != _RecState.extending &&
        _state != _RecState.processing &&
        _state != _RecState.processingQueue;

    if (canReview) {
      buttons.add(ElevatedButton.icon(
        onPressed: _goToVerification,
        icon: const Icon(Icons.stop_circle_outlined, size: 20),
        label: Text('STOP – Rivedi (${_entries.length})'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ));
    }

    // ── "Annulla sessione" (distruttivo, con conferma) ────────────────
    if (_hasActiveSession &&
        _state != _RecState.recording &&
        _state != _RecState.extending &&
        _state != _RecState.processing &&
        _state != _RecState.processingQueue) {
      buttons.add(OutlinedButton.icon(
        onPressed: _abandonSession,
        icon: Icon(Icons.cancel_outlined,
            size: 16, color: Colors.red.shade400),
        label: Text('Annulla sessione',
            style: TextStyle(color: Colors.red.shade600)),
        style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade300)),
      ));
    }

    if (buttons.isEmpty) {
      // Nessun bottone → hint "Premi per registrare"
      return Text(
        _entries.isEmpty && _queueCount == 0
            ? 'Premi il microfono per iniziare'
            : 'Registra la prossima arnia',
        style: TextStyle(
            fontSize: 13,
            color: ThemeConstants.textSecondaryColor),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }

  // ── Icona e testo di stato ────────────────────────────────────────────────

  Widget _buildStatusIcon() {
    switch (_state) {
      case _RecState.recording:
        return Icon(Icons.fiber_manual_record,
            size: 18, color: Colors.red.shade600);
      case _RecState.extending:
        return Icon(Icons.fiber_manual_record,
            size: 18, color: Colors.amber.shade700);
      case _RecState.processing:
      case _RecState.processingQueue:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                Colors.orange.shade700),
          ),
        );
      case _RecState.error:
        return Icon(Icons.error_outline,
            size: 18, color: Colors.red.shade600);
      case _RecState.recorded:
        return Icon(Icons.graphic_eq,
            size: 18, color: Colors.indigo.shade400);
      case _RecState.idle:
        return Icon(Icons.mic_none,
            size: 18,
            color: ThemeConstants.textSecondaryColor);
    }
  }

  String _statusText() {
    switch (_state) {
      case _RecState.recording:
        return 'Registrazione in corso…';
      case _RecState.extending:
        return 'Aggiunta audio in corso… (+${_formatDuration(_seconds)})';
      case _RecState.processing:
        return 'Invio a Gemini…';
      case _RecState.processingQueue:
        return 'Elaborazione coda: $_queueProcessedCount/$_queueTotalCount…';
      case _RecState.error:
        return 'Errore elaborazione';
      case _RecState.recorded:
        return 'Salvataggio in sessione…';
      case _RecState.idle:
        if (_entries.isNotEmpty) return 'Registra la prossima arnia';
        if (_queueCount > 0)
          return 'Registra le prossime arnie o invia tutto a Gemini';
        return 'Premi per iniziare la registrazione';
    }
  }
}
