// lib/provider_setup_updated.dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/mcp_service.dart';
import 'services/chat_service.dart';
// Importa i nuovi servizi
import 'services/google_speech_recognition_service.dart';
import 'services/voice_data_processor.dart';
import 'services/voice_input_manager_google.dart';
import 'services/voice_feedback_service_updated.dart';
import 'services/audio_service.dart';

List<SingleChildWidget> providers = [
  // Servizio di storage (indipendente)
  Provider<StorageService>(
    create: (_) => StorageService(),
  ),
  
  // Servizio di autenticazione (indipendente, modificato per non usare StorageService)
  ChangeNotifierProvider<AuthService>(
    create: (_) => AuthService(),
  ),
  
  // Servizio API (dipende da auth)
  ProxyProvider<AuthService, ApiService>(
    update: (_, authService, __) => ApiService(authService),
  ),
  
  // Servizio di sincronizzazione (dipende da API e storage)
  ProxyProvider2<ApiService, StorageService, SyncService>(
    update: (_, apiService, storageService, __) => 
        SyncService(apiService, storageService),
  ),
  
  // Servizio MCP (dipende da API)
  ProxyProvider<ApiService, MCPService>(
    update: (_, apiService, __) => MCPService(apiService),
  ),
  
  // Audio Service (indipendente)
  Provider<AudioService>(
    create: (_) => AudioService(),
    dispose: (_, service) => service.dispose(),
  ),
  
  // Servizio di feedback vocale (indipendente)
  Provider<VoiceFeedbackService>(
    create: (_) => VoiceFeedbackService(),
  ),

  // Servizio Chat (dipende da API e MCP)
  ChangeNotifierProxyProvider2<ApiService, MCPService, ChatService>(
    create: (context) => ChatService(
      Provider.of<ApiService>(context, listen: false),
      Provider.of<MCPService>(context, listen: false),
      '0' // Default user ID, will be updated
    ),
    update: (context, apiService, mcpService, previousChat) {
      // Ottieni l'ID utente dal servizio di autenticazione
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id.toString() ?? '0';
      
      // Se esiste un servizio precedente, aggiorna solo l'userId
      if (previousChat != null) {
        return previousChat;
      }
      
      // Altrimenti crea una nuova istanza
      return ChatService(apiService, mcpService, userId);
    },
  ),
  
  // NUOVI SERVIZI PER INPUT VOCALE GOOGLE
  
  // Servizio di riconoscimento vocale Google (indipendente)
  ChangeNotifierProvider<GoogleSpeechRecognitionService>(
    create: (_) => GoogleSpeechRecognitionService(),
  ),
  
  // Servizio di elaborazione dati vocali (dipende da API)
  ChangeNotifierProxyProvider<ApiService, VoiceDataProcessor>(
    create: (context) => VoiceDataProcessor(
      Provider.of<ApiService>(context, listen: false)
    ),
    update: (_, apiService, previousProcessor) {
      if (previousProcessor != null) {
        return previousProcessor;
      }
      return VoiceDataProcessor(apiService);
    },
  ),
  
  // Gestore input vocale (dipende da riconoscimento e processamento)
  ChangeNotifierProxyProvider2<GoogleSpeechRecognitionService, VoiceDataProcessor, VoiceInputManagerGoogle>(
    create: (context) => VoiceInputManagerGoogle(
      Provider.of<GoogleSpeechRecognitionService>(context, listen: false),
      Provider.of<VoiceDataProcessor>(context, listen: false)
    ),
    update: (_, speechService, dataProcessor, previousManager) {
      if (previousManager != null) {
        return previousManager;
      }
      return VoiceInputManagerGoogle(speechService, dataProcessor);
    },
  ),
];

// Puoi anche aggiungere configurazioni per test e mock se necessario
List<SingleChildWidget> testProviders = [
  // Mock dei servizi per testing
];