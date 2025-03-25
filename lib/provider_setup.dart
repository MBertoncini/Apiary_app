// lib/provider_setup.dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/mcp_service.dart';
import 'services/chat_service.dart';

List<SingleChildWidget> providers = [
  // Servizio di storage (indipendente)
  Provider<StorageService>(
    create: (_) => StorageService(),
  ),
  
  // Servizio di autenticazione (dipende da storage)
  ProxyProvider<StorageService, AuthService>(
    update: (_, storageService, __) => AuthService(storageService),
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
  
    // Servizio Chat (dipende da API e MCP)
    ChangeNotifierProxyProvider2<ApiService, MCPService, ChatService>(
    update: (context, apiService, mcpService, previousChatService) {
        // Ottieni l'ID utente dal servizio di autenticazione
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.id.toString() ?? '0';
        
        // Return the previous instance if it exists, or create a new one
        return previousChatService ?? ChatService(apiService, mcpService, userId);
    },
    ),

// Puoi anche aggiungere configurazioni per test e mock se necessario
List<SingleChildWidget> testProviders = [
  // Mock dei servizi per testing
];