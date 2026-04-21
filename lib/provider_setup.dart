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
import 'services/ai_quota_service.dart';
// Import services
import 'services/language_service.dart';
import 'services/voice_feedback_service.dart';
import 'services/audio_service.dart';
import 'services/bee_detection_service.dart';
import 'services/analisi_telaino_service.dart';
import 'services/subscription_service.dart';

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

  // Subscription service (RevenueCat) — independent, eager init
  ChangeNotifierProvider<SubscriptionService>(
    create: (_) => SubscriptionService(),
  ),

  // AI Quota service (depends on API + Auth) — single source of truth per i
  // limiti AI (chat / voice / stats). Deve essere registrato PRIMA di
  // ChatService e degli screen/widget che lo consumano. Propaga il tier
  // corrente ogni volta che AuthService notifica un nuovo utente.
  ChangeNotifierProxyProvider2<ApiService, AuthService, AiQuotaService>(
    create: (context) => AiQuotaService(
      Provider.of<ApiService>(context, listen: false),
    ),
    update: (context, apiService, authService, previous) {
      final service = previous ?? AiQuotaService(apiService);
      final user = authService.currentUser;
      if (user != null) {
        service.setTier(user.aiTier);
        // Propaga il flag chiave Gemini personale: consente al gating di
        // saltare il tier limit quando l'utente paga Google direttamente.
        service.setHasPersonalGeminiKey(user.geminiApiKey.isNotEmpty);
        // Dopo login/profile refresh riallinea al backend se i dati di
        // quota sono vecchi (o non ancora caricati).
        service.refreshIfStale();
      }
      return service;
    },
  ),

  // Chat Service (depends on API + AiQuotaService) - lazy
  ChangeNotifierProxyProvider2<ApiService, AiQuotaService, ChatService>(
    create: (context) => ChatService(
      Provider.of<ApiService>(context, listen: false),
      Provider.of<AiQuotaService>(context, listen: false),
    ),
    lazy: true,
    update: (context, apiService, quotaService, previousChat) =>
        previousChat ?? ChatService(apiService, quotaService),
  ),

];

// You can also add configurations for tests and mocks if needed
List<SingleChildWidget> testProviders = [
  // Mock services for testing
];