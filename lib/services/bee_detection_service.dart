import 'dart:io';
// import 'package:tflite_flutter/tflite_flutter.dart'; // Deprecated for now

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
  // static const String _modelPath = 'assets/models/bee_detector.tflite';
  
  // Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    // Deprecated: TFLite not compatible with 16KB page alignment in standard Maven artifacts.
    _isInitialized = true;
  }

  Future<DetectionResult> detectFromFile(File imageFile) async {
    // await _initialize();
    
    // Return empty result as feature is temporarily disabled
    return DetectionResult(
      bees: 0,
      queenBees: 0,
      drones: 0,
      royalCells: 0,
      averageConfidence: 0,
      detections: [],
    );
  }

  void dispose() {
    // _interpreter?.close();
  }
}
