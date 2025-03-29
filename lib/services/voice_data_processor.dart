// lib/services/voice_data_processor.dart
import 'package:flutter/foundation.dart';
import '../models/voice_entry.dart';

// Define the abstract mixin for voice data processing
mixin VoiceDataProcessor on ChangeNotifier {
  // Abstract method that all implementers must provide
  Future<VoiceEntry?> processVoiceInput(String text);
  
  // Getter for error state
  String? get error;
}