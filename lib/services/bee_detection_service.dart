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
  static const List<String> _classNames = ['bees', 'queenbees', 'drone', 'royal cell'];

  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isInitialized = true;
      debugPrint('BeeDetectionService: model loaded successfully');
    } catch (e) {
      debugPrint('BeeDetectionService: failed to load model: $e');
      rethrow;
    }
  }

  Future<DetectionResult> detectFromFile(File imageFile) async {
    await _initialize();

    // Decode image
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception('Impossibile decodificare l\'immagine');
    }

    // Letterbox resize to 640x640
    final preprocessed = _letterboxResize(originalImage, _inputSize, _inputSize);
    final inputTensor = preprocessed['tensor'] as Float32List;
    final scaleX = preprocessed['scaleX'] as double;
    final scaleY = preprocessed['scaleY'] as double;
    final padX = preprocessed['padX'] as double;
    final padY = preprocessed['padY'] as double;

    // Reshape input: [1, 640, 640, 3]
    final input = inputTensor.reshape([1, _inputSize, _inputSize, 3]);

    // Get output shape from interpreter
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    // YOLO11 output shape: [1, numFeatures, numDetections]
    // where numFeatures = 4 (bbox) + numClasses
    final numFeatures = outputShape[1];
    final numDetections = outputShape[2];

    // Allocate output buffer
    final output = List.generate(
      1,
      (_) => List.generate(
        numFeatures,
        (_) => List.filled(numDetections, 0.0),
      ),
    );

    // Run inference
    _interpreter!.run(input, output);

    // Post-process: parse detections
    final rawDetections = <DetectedObject>[];
    final numClasses = numFeatures - 4;

    for (int d = 0; d < numDetections; d++) {
      // Find best class
      double maxConf = 0;
      int bestClass = 0;
      for (int c = 0; c < numClasses; c++) {
        final conf = output[0][4 + c][d];
        if (conf > maxConf) {
          maxConf = conf;
          bestClass = c;
        }
      }

      if (maxConf < _confidenceThreshold) continue;

      // YOLO outputs cx, cy, w, h
      final cx = output[0][0][d];
      final cy = output[0][1][d];
      final w = output[0][2][d];
      final h = output[0][3][d];

      // Convert to x1, y1, x2, y2 in letterboxed space
      final x1 = cx - w / 2;
      final y1 = cy - h / 2;
      final x2 = cx + w / 2;
      final y2 = cy + h / 2;

      // Convert back to original image coordinates
      final origX1 = (x1 - padX) / scaleX;
      final origY1 = (y1 - padY) / scaleY;
      final origX2 = (x2 - padX) / scaleX;
      final origY2 = (y2 - padY) / scaleY;

      rawDetections.add(DetectedObject(
        classIndex: bestClass,
        className: bestClass < _classNames.length ? _classNames[bestClass] : 'unknown',
        confidence: maxConf,
        bbox: [origX1, origY1, origX2, origY2],
      ));
    }

    // Apply NMS
    final filtered = _nms(rawDetections, _iouThreshold);

    // Count per class
    int bees = 0, queenBees = 0, drones = 0, royalCells = 0;
    double totalConf = 0;
    for (final det in filtered) {
      totalConf += det.confidence;
      switch (det.classIndex) {
        case 0:
          bees++;
          break;
        case 1:
          queenBees++;
          break;
        case 2:
          drones++;
          break;
        case 3:
          royalCells++;
          break;
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

  Map<String, dynamic> _letterboxResize(img.Image image, int targetW, int targetH) {
    final origW = image.width;
    final origH = image.height;

    final scale = min(targetW / origW, targetH / origH);
    final newW = (origW * scale).round();
    final newH = (origH * scale).round();

    final resized = img.copyResize(image, width: newW, height: newH, interpolation: img.Interpolation.linear);

    // Create padded image with gray (114, 114, 114)
    final padX = (targetW - newW) / 2.0;
    final padY = (targetH - newH) / 2.0;
    final padXInt = padX.round();
    final padYInt = padY.round();

    final tensor = Float32List(targetW * targetH * 3);
    // Fill with gray (114/255)
    final grayVal = 114.0 / 255.0;
    for (int i = 0; i < tensor.length; i++) {
      tensor[i] = grayVal;
    }

    // Copy resized image into tensor
    for (int y = 0; y < newH; y++) {
      for (int x = 0; x < newW; x++) {
        final pixel = resized.getPixel(x, y);
        final tx = x + padXInt;
        final ty = y + padYInt;
        if (tx >= 0 && tx < targetW && ty >= 0 && ty < targetH) {
          final idx = (ty * targetW + tx) * 3;
          tensor[idx] = pixel.r / 255.0;
          tensor[idx + 1] = pixel.g / 255.0;
          tensor[idx + 2] = pixel.b / 255.0;
        }
      }
    }

    return {
      'tensor': tensor,
      'scaleX': scale.toDouble(),
      'scaleY': scale.toDouble(),
      'padX': padX,
      'padY': padY,
    };
  }

  List<DetectedObject> _nms(List<DetectedObject> detections, double iouThreshold) {
    // Sort by confidence descending
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final selected = <DetectedObject>[];
    final suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      selected.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (detections[i].classIndex != detections[j].classIndex) continue;

        final iou = _computeIoU(detections[i].bbox, detections[j].bbox);
        if (iou > iouThreshold) {
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

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
