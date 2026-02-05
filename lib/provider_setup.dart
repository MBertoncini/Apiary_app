// lib/provider_setup.dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/mcp_service.dart';
import 'services/chat_service.dart';
// Import services
import 'services/wit_speech_recognition_service.dart';
import 'services/wit_data_processor.dart';
import 'services/voice_input_manager.dart'; // Updated to use the new class
import 'services/voice_feedback_service.dart';
import 'services/audio_service.dart';

List<SingleChildWidget> providers = [
  // Storage service (independent)
  Provider<StorageService>(
    create: (_) => StorageService(),
  ),

  // Authentication service (independent)
  ChangeNotifierProvider<AuthService>(
    create: (_) => AuthService(),
  ),

  // API service (depends on auth)
  ProxyProvider<AuthService, ApiService>(
    update: (_, authService, __) => ApiService(authService),
  ),

  // Sync service (depends on API and storage) - periodic sync NOT auto-started
  ProxyProvider2<ApiService, StorageService, SyncService>(
    update: (_, apiService, storageService, __) =>
        SyncService(apiService, storageService),
  ),

  // MCP service (depends on API)
  ProxyProvider<ApiService, MCPService>(
    update: (_, apiService, __) => MCPService(apiService),
  ),

  // Audio Service (independent, lazy)
  Provider<AudioService>(
    create: (_) => AudioService(),
    lazy: true,
    dispose: (_, service) => service.dispose(),
  ),

  // Voice feedback service (independent, lazy)
  Provider<VoiceFeedbackService>(
    create: (_) => VoiceFeedbackService(),
    lazy: true,
  ),

  // Chat Service (depends on API and MCP) - lazy, created on first access
  ChangeNotifierProxyProvider2<ApiService, MCPService, ChatService>(
    create: (context) => ChatService(
      Provider.of<ApiService>(context, listen: false),
      Provider.of<MCPService>(context, listen: false),
      '0',
    ),
    lazy: true,
    update: (context, apiService, mcpService, previousChat) {
      if (previousChat != null) {
        return previousChat;
      }
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id.toString() ?? '0';
      return ChatService(apiService, mcpService, userId);
    },
  ),

  // Wit.ai speech recognition service (lazy - only initialized when voice features used)
  ChangeNotifierProvider<WitSpeechRecognitionService>(
    create: (_) => WitSpeechRecognitionService(),
    lazy: true,
  ),

  // Wit.ai data processor (lazy)
  ChangeNotifierProvider<WitDataProcessor>(
    create: (_) => WitDataProcessor(),
    lazy: true,
  ),

  // Voice input manager (lazy)
  ChangeNotifierProxyProvider2<WitSpeechRecognitionService, WitDataProcessor, VoiceInputManager>(
    create: (context) => VoiceInputManager(
      Provider.of<WitSpeechRecognitionService>(context, listen: false),
      Provider.of<WitDataProcessor>(context, listen: false),
    ),
    lazy: true,
    update: (_, speechService, dataProcessor, previousManager) {
      if (previousManager != null) {
        return previousManager;
      }
      return VoiceInputManager(speechService, dataProcessor);
    },
  ),
];

// You can also add configurations for tests and mocks if needed
List<SingleChildWidget> testProviders = [
  // Mock services for testing
];