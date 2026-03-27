// lib/provider_setup.dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/mcp_service.dart';
import 'services/chat_service.dart';
// Import services
import 'services/language_service.dart';
import 'services/voice_feedback_service.dart';
import 'services/audio_service.dart';
import 'services/bee_detection_service.dart';
import 'services/analisi_telaino_service.dart';

List<SingleChildWidget> providers = [
  // Language service (independent) — must be first so MaterialApp can read it
  ChangeNotifierProvider<LanguageService>(
    create: (_) => LanguageService(),
  ),

  // Connectivity service (independent)
  Provider<ConnectivityService>(
    create: (_) => ConnectivityService(),
    dispose: (_, service) => service.dispose(),
  ),

  // Storage service (independent)
  Provider<StorageService>(
    create: (_) => StorageService(),
  ),

  // Authentication service (independent)
  ChangeNotifierProvider<AuthService>(
    create: (_) => AuthService(),
  ),

  // API service (depends on auth) - reuse existing instance; AuthService is held
  // by reference so the same ApiService always sees the latest token.
  ProxyProvider<AuthService, ApiService>(
    update: (_, authService, prev) => prev ?? ApiService(authService),
  ),

  // Sync service (depends on API and storage) - periodic sync NOT auto-started
  ProxyProvider2<ApiService, StorageService, SyncService>(
    update: (_, apiService, storageService, prev) =>
        prev ?? SyncService(apiService, storageService),
    dispose: (_, service) => service.dispose(),
  ),

  // MCP service (depends on API)
  ProxyProvider<ApiService, MCPService>(
    update: (_, apiService, prev) => prev ?? MCPService(apiService),
  ),

  // Bee Detection Service (independent, lazy)
  Provider<BeeDetectionService>(
    create: (_) => BeeDetectionService(),
    lazy: true,
    dispose: (_, service) => service.dispose(),
  ),

  // Analisi Telaino Service (depends on API)
  ProxyProvider<ApiService, AnalisiTelainoService>(
    update: (_, apiService, prev) => prev ?? AnalisiTelainoService(apiService),
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

  // Chat Service (depends on API) - lazy, created on first access
  ChangeNotifierProxyProvider<ApiService, ChatService>(
    create: (context) => ChatService(
      Provider.of<ApiService>(context, listen: false),
    ),
    lazy: true,
    update: (context, apiService, previousChat) => previousChat ?? ChatService(apiService),
  ),

];

// You can also add configurations for tests and mocks if needed
List<SingleChildWidget> testProviders = [
  // Mock services for testing
];