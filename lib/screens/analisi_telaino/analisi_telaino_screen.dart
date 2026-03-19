import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/analisi_telaino.dart';
import '../../services/bee_detection_service.dart';
import '../../services/analisi_telaino_service.dart';
import '../../services/controllo_service.dart';
import '../../services/api_service.dart';
import '../../utils/telaini_utils.dart';
import '../../widgets/contextual_hint.dart';

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

/// Represents one physical frame slot in the hive as recorded by the latest
/// controllo. Only non-'vuoto' positions become slots.
class _TelainoSlot {
  final int numero; // 1-based position
  final String tipo; // covata | scorte | diaframma | nutritore

  const _TelainoSlot({required this.numero, required this.tipo});

  String get label {
    switch (tipo) {
      case 'covata':       return 'Covata';
      case 'scorte':       return 'Scorte';
      case 'foglio_cereo': return 'F. Cereo';
      case 'diaframma':    return 'Diaframma';
      case 'nutritore':    return 'Nutritore';
      default:             return tipo;
    }
  }

  Color get color {
    switch (tipo) {
      case 'covata':       return Colors.red.shade700;
      case 'scorte':       return Colors.amber.shade700;
      case 'foglio_cereo': return const Color(0xFF8FBC5A);
      case 'diaframma':    return Colors.grey.shade800;
      case 'nutritore':    return const Color(0xFFA0785A);
      default:             return Colors.blueGrey;
    }
  }

  IconData get icon {
    switch (tipo) {
      case 'covata':       return Icons.grid_4x4;
      case 'scorte':       return Icons.hexagon_outlined;
      case 'foglio_cereo': return Icons.description_outlined;
      case 'diaframma':    return Icons.vertical_split;
      case 'nutritore':    return Icons.coffee;
      default:             return Icons.help_outline;
    }
  }
}

/// A diagnostic warning produced after detection, relative to the frame type.
class _DetectionWarning {
  final String message;
  final Color color;
  final IconData icon;

  const _DetectionWarning(this.message, this.color, this.icon);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AnalisiTelainoScreen extends StatefulWidget {
  final int arniaId;

  const AnalisiTelainoScreen({required this.arniaId});

  @override
  _AnalisiTelainoScreenState createState() => _AnalisiTelainoScreenState();
}

class _AnalisiTelainoScreenState extends State<AnalisiTelainoScreen> {
  // Step: 0=config, 1=analyzing, 2=results
  int _step = 0;

  // Telaino selection – from controllo-driven slots when available
  List<_TelainoSlot> _telainoSlots = [];
  _TelainoSlot? _selectedSlot;
  bool _loadingControllo = true;
  String? _lastControlloDate;

  // Fallback manual selection (used when no controllo is found)
  int _numeroTelaino = 1;
  String _facciata = 'A';

  File?   _imageFile;
  int     _imageWidth  = 0;
  int     _imageHeight = 0;
  DetectionResult? _result;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  final _picker = ImagePicker();

  // Services
  late ControlloService _controlloService;
  bool _servicesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_servicesReady) {
      _servicesReady = true;
      final api = Provider.of<ApiService>(context, listen: false);
      _controlloService = ControlloService(api);
      _loadTelainoSlots();
    }
  }

  // -------------------------------------------------------------------------
  // Load slots from latest controllo
  // -------------------------------------------------------------------------

  Future<void> _loadTelainoSlots() async {
    try {
      final controlli = await _controlloService.getControlliByArnia(widget.arniaId);
      if (!mounted) return;

      if (controlli.isEmpty) {
        setState(() => _loadingControllo = false);
        return;
      }

      // Sort by date descending (most recent first).
      controlli.sort((a, b) => (b['data'] ?? '').compareTo(a['data'] ?? ''));
      final latest = controlli.first;
      _lastControlloDate = latest['data'] as String?;

      // Parse telaini_config JSON stored by the controllo form.
      List<String> config = List.filled(10, 'vuoto');
      final raw = latest['telaini_config'];
      if (raw != null && raw.toString().isNotEmpty) {
        try {
          config = sortTelaini(List<String>.from(json.decode(raw.toString()) as List));
        } catch (_) {}
      }

      // Build slots for physically present frames (anything that is not 'vuoto').
      final slots = <_TelainoSlot>[
        for (int i = 0; i < config.length; i++)
          if (config[i] != 'vuoto')
            _TelainoSlot(numero: i + 1, tipo: config[i]),
      ];

      setState(() {
        _telainoSlots  = slots;
        _selectedSlot  = slots.isNotEmpty ? slots.first : null;
        _loadingControllo = false;
      });
    } catch (e) {
      debugPrint('AnalisiTelainoScreen: could not load controllo slots – $e');
      if (mounted) setState(() => _loadingControllo = false);
    }
  }

  // -------------------------------------------------------------------------
  // Image & detection
  // -------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1280);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
      _runAnalysis();
    }
  }

  Future<void> _runAnalysis() async {
    if (_imageFile == null) return;
    setState(() => _step = 1);

    try {
      final detector = Provider.of<BeeDetectionService>(context, listen: false);
      final fileBytes = await _imageFile!.readAsBytes();
      final result    = await detector.detectFromFile(_imageFile!);

      _imageWidth  = _readImageWidth(fileBytes);
      _imageHeight = _readImageHeight(fileBytes);

      if (!mounted) return;
      setState(() {
        _result = result;
        _step   = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante l'analisi: $e")),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Warnings
  // -------------------------------------------------------------------------

  List<_DetectionWarning> _computeWarnings(DetectionResult result, _TelainoSlot slot) {
    final w  = <_DetectionWarning>[];
    final hi = Colors.red.shade700;
    final md = Colors.orange.shade700;
    final lo = Colors.amber.shade800;

    switch (slot.tipo) {
      case 'diaframma':
        if (result.bees > 5) {
          w.add(_DetectionWarning(
            'Api rilevate su diaframma (${result.bees}): il divisore non dovrebbe essere colonizzato.',
            hi, Icons.priority_high,
          ));
        }
        if (result.queenBees > 0) {
          w.add(_DetectionWarning(
            'Regina rilevata sul diaframma: situazione anomala, verifica subito.',
            hi, Icons.priority_high,
          ));
        }
        if (result.royalCells > 0) {
          w.add(_DetectionWarning(
            'Celle reali sul diaframma (${result.royalCells}): anomalia grave, intervento necessario.',
            hi, Icons.priority_high,
          ));
        }
        if (result.drones > 10) {
          w.add(_DetectionWarning(
            'Molti fuchi sul diaframma (${result.drones}): la separazione potrebbe non funzionare.',
            md, Icons.warning_amber_rounded,
          ));
        }
        break;

      case 'nutritore':
        if (result.queenBees > 0) {
          w.add(_DetectionWarning(
            'Regina sul nutritore: si è spostata fuori dalla zona covata.',
            md, Icons.warning_amber_rounded,
          ));
        }
        if (result.royalCells > 0) {
          w.add(_DetectionWarning(
            'Celle reali sul nutritore (${result.royalCells}): la colonia potrebbe prepararsi alla sciamatura.',
            md, Icons.warning_amber_rounded,
          ));
        }
        if (result.bees > 80) {
          w.add(_DetectionWarning(
            'Molte api sul nutritore (${result.bees}): verifica che il nutritore non ostacoli il movimento.',
            lo, Icons.info_outline,
          ));
        }
        break;

      case 'covata':
        if (result.royalCells > 3) {
          w.add(_DetectionWarning(
            'Celle reali elevate (${result.royalCells}): probabile preparazione alla sciamatura. Intervieni presto.',
            md, Icons.warning_amber_rounded,
          ));
        } else if (result.royalCells > 0) {
          w.add(_DetectionWarning(
            'Celle reali presenti (${result.royalCells}): monitora la colonia nelle prossime settimane.',
            lo, Icons.info_outline,
          ));
        }
        if (result.queenBees > 1) {
          w.add(_DetectionWarning(
            'Più regine rilevate (${result.queenBees}): anomalia – verifica la presenza di celle reali.',
            hi, Icons.priority_high,
          ));
        }
        if (result.bees == 0) {
          w.add(_DetectionWarning(
            'Nessuna ape su telaino covata: colonia indebolita, sciamata o cella vuota.',
            lo, Icons.warning_amber_rounded,
          ));
        }
        if (result.drones > 30) {
          w.add(_DetectionWarning(
            'Alta presenza di fuchi su covata (${result.drones}): possibile covata da fuche, colonia orfana?',
            md, Icons.warning_amber_rounded,
          ));
        }
        break;

      case 'scorte':
        if (result.queenBees > 0) {
          w.add(_DetectionWarning(
            'Regina su telaino scorte (${result.queenBees}): posizione inusuale, verifica lo spazio covata.',
            md, Icons.warning_amber_rounded,
          ));
        }
        if (result.royalCells > 0) {
          w.add(_DetectionWarning(
            'Celle reali su telaino scorte (${result.royalCells}): segnale di sciamatura o rimpiazzo della regina.',
            md, Icons.warning_amber_rounded,
          ));
        }
        if (result.bees > 200) {
          w.add(_DetectionWarning(
            'Alta densità api su scorte (${result.bees}): possibile accumulo pre-sciamatura.',
            lo, Icons.info_outline,
          ));
        }
        break;
    }

    // Global cross-type alert: extremely high total detections
    final total = result.bees + result.drones;
    if (slot.tipo != 'covata' && total > 300) {
      w.add(_DetectionWarning(
        'Densità altissima (${total} insetti): questo telaino è molto affollato.',
        lo, Icons.info_outline,
      ));
    }

    return w;
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  Future<void> _save() async {
    if (_result == null) return;
    setState(() => _isSaving = true);

    try {
      final service = Provider.of<AnalisiTelainoService>(context, listen: false);
      final numero  = _selectedSlot?.numero ?? _numeroTelaino;

      final analisi = AnalisiTelaino(
        arnia:               widget.arniaId,
        numeroTelaino:       numero,
        facciata:            _facciata,
        conteggioApi:        _result!.bees,
        conteggioRegine:     _result!.queenBees,
        conteggioFuchi:      _result!.drones,
        conteggioCelleReali: _result!.royalCells,
        confidenceMedia:     _result!.averageConfidence,
        note:                _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await service.saveAnalisi(analisi, imageFile: _imageFile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analisi salvata con successo')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _retry() {
    setState(() {
      _step      = 0;
      _imageFile = null;
      _result    = null;
    });
  }

  // -------------------------------------------------------------------------
  // Image dimension helpers (cheap header parse – no full decode)
  // -------------------------------------------------------------------------

  int _readImageWidth(List<int> bytes) {
    try {
      if (_isPng(bytes))  return _pngDim(bytes, 16);
      if (_isJpeg(bytes)) return _jpegDim(bytes)[0];
    } catch (_) {}
    return 0;
  }

  int _readImageHeight(List<int> bytes) {
    try {
      if (_isPng(bytes))  return _pngDim(bytes, 20);
      if (_isJpeg(bytes)) return _jpegDim(bytes)[1];
    } catch (_) {}
    return 0;
  }

  bool _isPng(List<int> b) =>
      b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
  bool _isJpeg(List<int> b) => b.length > 2 && b[0] == 0xFF && b[1] == 0xD8;
  int _pngDim(List<int> b, int o) =>
      (b[o] << 24) | (b[o+1] << 16) | (b[o+2] << 8) | b[o+3];
  List<int> _jpegDim(List<int> b) {
    int i = 2;
    while (i < b.length - 8) {
      if (b[i] != 0xFF) break;
      final marker = b[i + 1];
      final len    = (b[i + 2] << 8) | b[i + 3];
      if (marker == 0xC0 || marker == 0xC2) {
        return [(b[i+7] << 8) | b[i+8], (b[i+5] << 8) | b[i+6]];
      }
      i += 2 + len;
    }
    return [0, 0];
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisi Telaino')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0: return _buildConfigStep();
      case 1: return _buildAnalyzingStep();
      case 2: return _buildResultsStep();
      default: return const SizedBox();
    }
  }

  // -------------------------------------------------------------------------
  // Step 0 – Configuration
  // -------------------------------------------------------------------------

  Widget _buildConfigStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContextualHint(
            prefKey: 'analisi_telaino_v1',
            message: '📷 Per risultati ottimali: usa luce naturale diffusa, tieni il telaio parallelo alla fotocamera a 30–50 cm di distanza. Evita ombre sul telaio.',
          ),
          _buildTelainoCard(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scatta Foto'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Scegli dalla Galleria'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelainoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurazione',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Source label
            if (_loadingControllo)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Caricamento stato arnia...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else if (_telainoSlots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dati dal controllo del ${_lastControlloDate ?? "—"} '
                        '(${_telainoSlots.length} telaini presenti)',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nessun controllo recente trovato – selezione manuale.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Telaino selector
            if (_telainoSlots.isNotEmpty)
              _buildSlotDropdown()
            else
              _buildManualDropdown(),

            const SizedBox(height: 16),

            // Facciata toggle
            Row(
              children: [
                const Text('Facciata'),
                const SizedBox(width: 12),
                Expanded(
                  child: ToggleButtons(
                    isSelected: [_facciata == 'A', _facciata == 'B'],
                    onPressed: (i) => setState(() => _facciata = i == 0 ? 'A' : 'B'),
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('A'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('B'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dropdown populated from controllo telaini_config.
  Widget _buildSlotDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedSlot?.numero,
      items: _telainoSlots.map((slot) {
        return DropdownMenuItem<int>(
          value: slot.numero,
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: slot.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('Telaino ${slot.numero}'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: slot.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: slot.color.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(slot.icon, size: 12, color: slot.color),
                    const SizedBox(width: 3),
                    Text(
                      slot.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: slot.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _selectedSlot = _telainoSlots.firstWhere((s) => s.numero == v);
        });
      },
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(),
        labelText: 'Seleziona telaino',
      ),
    );
  }

  /// Fallback manual 1–10 dropdown (no controllo available).
  Widget _buildManualDropdown() {
    return Row(
      children: [
        const Text('Telaino n.'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _numeroTelaino,
            items: List.generate(10, (i) => i + 1)
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) => setState(() => _numeroTelaino = v!),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Step 1 – Analyzing
  // -------------------------------------------------------------------------

  Widget _buildAnalyzingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Analisi in corso...', style: TextStyle(fontSize: 16)),
          if (_selectedSlot != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_selectedSlot!.icon, color: _selectedSlot!.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Telaino ${_selectedSlot!.numero} – ${_selectedSlot!.label}',
                  style: TextStyle(color: _selectedSlot!.color),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Step 2 – Results
  // -------------------------------------------------------------------------

  Widget _buildResultsStep() {
    if (_result == null) return const SizedBox();

    final warnings = _selectedSlot != null
        ? _computeWarnings(_result!, _selectedSlot!)
        : <_DetectionWarning>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with bounding boxes
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.file(_imageFile!, fit: BoxFit.contain),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BoundingBoxPainter(
                        detections:  _result!.detections,
                        imageWidth:  _imageWidth,
                        imageHeight: _imageHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Frame identity header
          if (_selectedSlot != null)
            _buildFrameIdentityBadge(_selectedSlot!),

          const SizedBox(height: 8),

          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telaino ${_selectedSlot?.numero ?? _numeroTelaino} – Facciata $_facciata',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildCountRow('Api',         _result!.bees,        Icons.bug_report,       Colors.orange),
                  _buildCountRow('Regine',      _result!.queenBees,   Icons.star,             Colors.purple),
                  _buildCountRow('Fuchi',       _result!.drones,      Icons.circle,           Colors.blue),
                  _buildCountRow('Celle Reali', _result!.royalCells,  Icons.hexagon_outlined, Colors.amber),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Confidenza media: '),
                      Expanded(
                        child: LinearProgressIndicator(
                          value:           _result!.averageConfidence,
                          backgroundColor: Colors.grey.shade200,
                          color: _result!.averageConfidence > 0.5 ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(_result!.averageConfidence * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Warnings block
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildWarningsCard(warnings),
          ],

          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Note (opzionale)',
              border: OutlineInputBorder(),
              hintText: 'Aggiungi osservazioni...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ripeti'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Salva'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrameIdentityBadge(_TelainoSlot slot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: slot.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: slot.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(slot.icon, color: slot.color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Telaino ${slot.numero} – ${slot.label}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: slot.color,
                ),
              ),
              Text(
                'Tipo registrato nell\'ultimo controllo (${_lastControlloDate ?? "—"})',
                style: TextStyle(fontSize: 11, color: slot.color.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsCard(List<_DetectionWarning> warnings) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Analisi diagnostica',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(w.icon, color: w.color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w.message,
                      style: TextStyle(color: w.color, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCountRow(String label, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bounding-box overlay painter
// ---------------------------------------------------------------------------

class _BoundingBoxPainter extends CustomPainter {
  final List<DetectedObject> detections;
  final int imageWidth;
  final int imageHeight;

  _BoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  static const _classColors = [
    Colors.orange, // bees
    Colors.blue,   // drone
    Colors.purple, // queenbees
    Colors.amber,  // royal cell
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;

    final scaleX = size.width  / imageWidth;
    final scaleY = size.height / imageHeight;

    for (final det in detections) {
      final color = det.classIndex < _classColors.length
          ? _classColors[det.classIndex]
          : Colors.red;

      final paint = Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final rect = Rect.fromLTRB(
        det.bbox[0] * scaleX, det.bbox[1] * scaleY,
        det.bbox[2] * scaleX, det.bbox[3] * scaleY,
      );
      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${det.className} ${(det.confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top - 14, textPainter.width + 4, 14),
        Paint()..color = Colors.black54,
      );
      textPainter.paint(canvas, Offset(rect.left + 2, rect.top - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
