import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DetectedObject {
  final int classIndex;
  final String className;
  final double confidence;
  final List<double> bbox; // [x1, y1, x2, y2] in original image coords

  DetectedObject({
    required this.classIndex,
    required this.className,
    required this.confidence,
    required this.bbox,
  });
}

class DetectionResult {
  final int bees;
  final int queenBees;
  final int drones;
  final int royalCells;
  final double averageConfidence;
  final List<DetectedObject> detections;

  DetectionResult({
    required this.bees,
    required this.queenBees,
    required this.drones,
    required this.royalCells,
    required this.averageConfidence,
    required this.detections,
  });
}

class BeeDetectionService {
  static const String _modelPath = 'assets/models/bee_detector.tflite';
  static const int _inputSize = 640;
  static const double _confidenceThreshold = 0.25;
  static const double _iouThreshold = 0.45;
  // Class order: {0: bees, 1: drone, 2: queenbees, 3: royal cell}
  static const List<String> _classNames = ['bees', 'drone', 'queenbees', 'royal cell'];
  static const int _numClasses = 4;

  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Detected at runtime: true = [1, features, detections], false = [1, detections, features]
  bool _featuresFirst = true;
  int _numDetections = 8400;
  int _numFeatures = 40;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      // allocateTensors() is called automatically in Interpreter._() constructor,
      // but calling it explicitly is harmless and documents the intent.
      _interpreter!.allocateTensors();

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('BeeDetectionService: model loaded, output shape=$outputShape');

      if (outputShape.length < 3) {
        throw Exception('Formato output non supportato: shape=$outputShape (atteso rank 3)');
      }

      // Detect output tensor orientation at runtime.
      // Features dim is always the small one (e.g. 40 = 4bbox + 4cls + 32mask),
      // detections dim is the large one (e.g. 8400 anchor candidates).
      final dim1 = outputShape[1];
      final dim2 = outputShape[2];
      _featuresFirst = dim1 < dim2;
      _numFeatures   = _featuresFirst ? dim1 : dim2;
      _numDetections = _featuresFirst ? dim2 : dim1;

      debugPrint(
        'BeeDetectionService: featuresFirst=$_featuresFirst '
        'numFeatures=$_numFeatures numDetections=$_numDetections',
      );

      _isInitialized = true;
    } catch (e) {
      // Clean up so a retry attempt can start fresh.
      _interpreter?.close();
      _interpreter = null;
      debugPrint('BeeDetectionService: failed to load model – $e');
      rethrow;
    }
  }

  Future<DetectionResult> detectFromFile(File imageFile) async {
    await _initialize();

    // Decode image
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception("Impossibile decodificare l'immagine");
    }

    // Letterbox-resize to 640×640 and produce a flat Float32List [H*W*3].
    final letterboxResult = _letterboxResize(originalImage, _inputSize, _inputSize);
    final Float32List inputFlat  = letterboxResult.tensor;
    final double       scaleX    = letterboxResult.scaleX;
    final double       scaleY    = letterboxResult.scaleY;
    final double       padX      = letterboxResult.padX;
    final double       padY      = letterboxResult.padY;

    // THE FIX: do NOT use run() or runForMultipleInputs().
    //
    // Both ultimately call:
    //   for (var i = 0; i < outputTensors.length; i++) {
    //     outputTensors[i].copyTo(outputs[i]!);   // ← outputs[1] == null for seg models → CRASH
    //   }
    //
    // YOLOv8-seg has TWO output tensors (detections + mask prototypes).
    // The outputs map only has key 0, so outputs[1]! throws
    // "Null check operator used on a null value".
    //
    // Solution: use runInference() which only runs inference (no output copy loop),
    // then manually copy only the tensor we need via getOutputTensor(0).copyTo().

    // Pass input as raw Uint8List – the most efficient path in ByteConversionUtils
    // (returned as-is without any allocation/traversal).
    final inputBytes = inputFlat.buffer.asUint8List();
    _interpreter!.runInference([inputBytes]);

    // Copy output tensor 0 into a Uint8List, then reinterpret as Float32.
    final outTensor = _interpreter!.getOutputTensor(0);
    final outBytes  = Uint8List(outTensor.numBytes());
    outTensor.copyTo(outBytes);
    final floatData = outBytes.buffer.asFloat32List();

    // Parse detections.
    // Layout helper: feature at featureIdx for detection detIdx.
    double getVal(int featureIdx, int detIdx) {
      if (_featuresFirst) {
        // floatData[featureIdx * numDetections + detIdx]
        return floatData[featureIdx * _numDetections + detIdx];
      } else {
        // floatData[detIdx * numFeatures + featureIdx]
        return floatData[detIdx * _numFeatures + featureIdx];
      }
    }

    final rawDetections = <DetectedObject>[];
    for (int d = 0; d < _numDetections; d++) {
      // Find the class with highest confidence (features 4 … 4+numClasses-1).
      double maxConf = 0;
      int bestClass = 0;
      for (int c = 0; c < _numClasses; c++) {
        final conf = getVal(4 + c, d);
        if (conf > maxConf) {
          maxConf  = conf;
          bestClass = c;
        }
      }
      if (maxConf < _confidenceThreshold) continue;

      // Features 0-3: cx, cy, w, h in letterboxed 640×640 space.
      final cx = getVal(0, d);
      final cy = getVal(1, d);
      final w  = getVal(2, d);
      final h  = getVal(3, d);

      final x1 = cx - w / 2;
      final y1 = cy - h / 2;
      final x2 = cx + w / 2;
      final y2 = cy + h / 2;

      // Map back to original image coordinates.
      rawDetections.add(DetectedObject(
        classIndex: bestClass,
        className: bestClass < _classNames.length ? _classNames[bestClass] : 'unknown',
        confidence: maxConf,
        bbox: [
          (x1 - padX) / scaleX,
          (y1 - padY) / scaleY,
          (x2 - padX) / scaleX,
          (y2 - padY) / scaleY,
        ],
      ));
    }

    final filtered = _nms(rawDetections, _iouThreshold);

    int bees = 0, queenBees = 0, drones = 0, royalCells = 0;
    double totalConf = 0;
    for (final det in filtered) {
      totalConf += det.confidence;
      switch (det.classIndex) {
        case 0: bees++;       break;
        case 1: drones++;     break;
        case 2: queenBees++;  break;
        case 3: royalCells++; break;
      }
    }

    return DetectionResult(
      bees: bees,
      queenBees: queenBees,
      drones: drones,
      royalCells: royalCells,
      averageConfidence: filtered.isEmpty ? 0 : totalConf / filtered.length,
      detections: filtered,
    );
  }

  // ---------------------------------------------------------------------------
  // Preprocessing
  // ---------------------------------------------------------------------------

  _LetterboxResult _letterboxResize(img.Image image, int targetW, int targetH) {
    final origW = image.width;
    final origH = image.height;

    final scale  = min(targetW / origW, targetH / origH);
    final newW   = (origW * scale).round();
    final newH   = (origH * scale).round();

    final resized = img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    final padX    = (targetW - newW) / 2.0;
    final padY    = (targetH - newH) / 2.0;
    final padXInt = padX.round();
    final padYInt = padY.round();

    // Flat Float32List in HWC order, filled with grey (114/255 ≈ 0.447).
    final tensor   = Float32List(targetH * targetW * 3);
    const grayVal  = 114.0 / 255.0;
    for (int i = 0; i < tensor.length; i++) {
      tensor[i] = grayVal;
    }

    for (int y = 0; y < newH; y++) {
      for (int x = 0; x < newW; x++) {
        final pixel = resized.getPixel(x, y);
        final ty    = y + padYInt;
        final tx    = x + padXInt;
        if (tx >= 0 && tx < targetW && ty >= 0 && ty < targetH) {
          final idx  = (ty * targetW + tx) * 3;
          tensor[idx]     = pixel.r / 255.0;
          tensor[idx + 1] = pixel.g / 255.0;
          tensor[idx + 2] = pixel.b / 255.0;
        }
      }
    }

    return _LetterboxResult(
      tensor: tensor,
      scaleX: scale.toDouble(),
      scaleY: scale.toDouble(),
      padX: padX,
      padY: padY,
    );
  }

  // ---------------------------------------------------------------------------
  // NMS
  // ---------------------------------------------------------------------------

  List<DetectedObject> _nms(List<DetectedObject> detections, double iouThreshold) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final selected   = <DetectedObject>[];
    final suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      selected.add(detections[i]);
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (detections[i].classIndex != detections[j].classIndex) continue;
        if (_computeIoU(detections[i].bbox, detections[j].bbox) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return selected;
  }

  double _computeIoU(List<double> a, List<double> b) {
    final x1 = max(a[0], b[0]);
    final y1 = max(a[1], b[1]);
    final x2 = min(a[2], b[2]);
    final y2 = min(a[3], b[3]);

    final intersection = max(0.0, x2 - x1) * max(0.0, y2 - y1);
    final areaA = (a[2] - a[0]) * (a[3] - a[1]);
    final areaB = (b[2] - b[0]) * (b[3] - b[1]);
    final union = areaA + areaB - intersection;
    return union > 0 ? intersection / union : 0;
  }

  // ---------------------------------------------------------------------------

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

class _LetterboxResult {
  final Float32List tensor;
  final double scaleX;
  final double scaleY;
  final double padX;
  final double padY;

  const _LetterboxResult({
    required this.tensor,
    required this.scaleX,
    required this.scaleY,
    required this.padX,
    required this.padY,
  });
}
