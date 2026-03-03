import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../models/analisi_telaino.dart';
import '../../services/bee_detection_service.dart';
import '../../services/analisi_telaino_service.dart';

class AnalisiTelainoScreen extends StatefulWidget {
  final int arniaId;

  const AnalisiTelainoScreen({required this.arniaId});

  @override
  _AnalisiTelainoScreenState createState() => _AnalisiTelainoScreenState();
}

class _AnalisiTelainoScreenState extends State<AnalisiTelainoScreen> {
  // Step: 0=config, 1=analyzing, 2=results
  int _step = 0;

  int _numeroTelaino = 1;
  String _facciata = 'A';
  File? _imageFile;
  int _imageWidth = 0;
  int _imageHeight = 0;
  DetectionResult? _result;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1280);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      _runAnalysis();
    }
  }

  Future<void> _runAnalysis() async {
    if (_imageFile == null) return;
    setState(() => _step = 1);

    try {
      // Get image dimensions
      final bytes = await _imageFile!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        _imageWidth = decoded.width;
        _imageHeight = decoded.height;
      }

      final detector = Provider.of<BeeDetectionService>(context, listen: false);
      final result = await detector.detectFromFile(_imageFile!);
      setState(() {
        _result = result;
        _step = 2;
      });
    } catch (e) {
      setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'analisi: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (_result == null) return;
    setState(() => _isSaving = true);

    try {
      final service = Provider.of<AnalisiTelainoService>(context, listen: false);
      final analisi = AnalisiTelaino(
        arnia: widget.arniaId,
        numeroTelaino: _numeroTelaino,
        facciata: _facciata,
        conteggioApi: _result!.bees,
        conteggioRegine: _result!.queenBees,
        conteggioFuchi: _result!.drones,
        conteggioCelleReali: _result!.royalCells,
        confidenceMedia: _result!.averageConfidence,
        note: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await service.saveAnalisi(analisi, imageFile: _imageFile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analisi salvata con successo')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _retry() {
    setState(() {
      _step = 0;
      _imageFile = null;
      _result = null;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisi Telaino'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildConfigStep();
      case 1:
        return _buildAnalyzingStep();
      case 2:
        return _buildResultsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildConfigStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configurazione',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Telaino number
                  Row(
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
                  ),
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
          ),
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

  Widget _buildAnalyzingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _imageFile!,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Analisi in corso...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_result == null) return const SizedBox();

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
                        detections: _result!.detections,
                        imageWidth: _imageWidth,
                        imageHeight: _imageHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telaino $_numeroTelaino - Facciata $_facciata',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildCountRow('Api', _result!.bees, Icons.bug_report, Colors.orange),
                  _buildCountRow('Regine', _result!.queenBees, Icons.star, Colors.purple),
                  _buildCountRow('Fuchi', _result!.drones, Icons.circle, Colors.blue),
                  _buildCountRow('Celle Reali', _result!.royalCells, Icons.hexagon_outlined, Colors.amber),
                  const Divider(),
                  // Confidence bar
                  Row(
                    children: [
                      const Text('Confidenza media: '),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _result!.averageConfidence,
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
          const SizedBox(height: 16),

          // Notes field
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

          // Action buttons
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
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
    Colors.purple, // queenbees
    Colors.blue,   // drone
    Colors.amber,  // royal cell
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (final det in detections) {
      final color = det.classIndex < _classColors.length
          ? _classColors[det.classIndex]
          : Colors.red;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final rect = Rect.fromLTRB(
        det.bbox[0] * scaleX,
        det.bbox[1] * scaleY,
        det.bbox[2] * scaleX,
        det.bbox[3] * scaleY,
      );
      canvas.drawRect(rect, paint);

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${det.className} ${(det.confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgPaint = Paint()..color = Colors.black54;
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top - 14, textPainter.width + 4, 14),
        bgPaint,
      );
      textPainter.paint(canvas, Offset(rect.left + 2, rect.top - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
