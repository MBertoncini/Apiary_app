// lib/utils/route_generator.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/apiario/apiario_list_screen.dart';
import '../screens/apiario/apiario_detail_screen.dart';
import '../screens/apiario/apiario_form_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/gruppo/gruppi_list_screen.dart';
import '../screens/gruppo/gruppo_detail_screen.dart';
import '../screens/gruppo/gruppo_form_screen.dart';
import '../screens/gruppo/gruppo_invito_screen.dart';
import '../models/gruppo.dart';
import '../screens/mobile_scanner_wrapper_screen.dart';
import '../screens/arnia/arnia_detail_screen.dart';
import '../screens/arnia/arnia_list_screen.dart';
import '../screens/arnia/arnia_form_screen.dart';
import '../screens/controllo/controllo_form_screen.dart';
import '../screens/regina/regina_list_screen.dart';
import '../screens/regina/regina_detail_screen.dart';
import '../screens/trattamento/trattamenti_screen.dart';
import '../screens/trattamento/trattamento_form_screen.dart';
import '../screens/melario/melari_screen.dart';
import '../screens/mappa/mappa_screen.dart';
import '../screens/pagamento/pagamenti_screen.dart';
import '../screens/pagamento/pagamento_detail_screen.dart';
import '../screens/pagamento/pagamento_form_screen.dart';
import '../screens/pagamento/quote_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/voice_command_screen.dart'; // Updated import - using the correct updated class
import '../screens/attrezzatura/attrezzature_list_screen.dart';
import '../screens/attrezzatura/attrezzatura_detail_screen.dart';
import '../screens/attrezzatura/attrezzatura_form_screen.dart';
import '../screens/attrezzatura/spesa_attrezzatura_form_screen.dart';
import '../screens/attrezzatura/manutenzione_form_screen.dart';
import '../screens/voice_entry_verification_screen.dart';

class RouteGenerator {
 
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Get arguments passed to navigation
    final args = settings.arguments;
        
    switch (settings.name) {
      case '/':
      case AppConstants.splashRoute:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      
      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      
      case AppConstants.registerRoute:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      
      case AppConstants.dashboardRoute:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      
      case AppConstants.apiarioListRoute:
        return MaterialPageRoute(builder: (_) => ApiarioListScreen());
      
      case AppConstants.apiarioDetailRoute:
        // Verify arguments are correct
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ApiarioDetailScreen(apiarioId: args),
          );
        }
        return _errorRoute();
      
      case AppConstants.apiarioCreateRoute:
        return MaterialPageRoute(builder: (_) => ApiarioFormScreen());
      
      case AppConstants.settingsRoute:
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      
      // Routes for group management
      case AppConstants.gruppiListRoute:
        return MaterialPageRoute(builder: (_) => GruppiListScreen());
        
      case AppConstants.gruppoDetailRoute:
        // Verify arguments are correct
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => GruppoDetailScreen(gruppoId: args),
          );
        }
        return _errorRoute();
        
      case AppConstants.gruppoCreateRoute:
        // If args is null, it's a creation, otherwise it's a modification
        return MaterialPageRoute(
          builder: (_) => GruppoFormScreen(gruppo: args as Gruppo?),
        );
        
      case AppConstants.gruppoInvitoRoute:
        // Verify arguments are correct
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => GruppoInvitoScreen(gruppoId: args),
          );
        }
        return _errorRoute();

      case AppConstants.qrScannerRoute:
        return MaterialPageRoute(builder: (_) => MobileScannerWrapperScreen());

      // Routes for hive management
      case AppConstants.arniaListRoute:
        return MaterialPageRoute(builder: (_) => ArniaListScreen());
            
      case AppConstants.arniaDetailRoute:
        // Verify arguments are correct
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ArniaDetailScreen(arniaId: args),
          );
        }
        return _errorRoute();
        
      case AppConstants.creaArniaRoute:
        // Check if an apiary is specified
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ArniaFormScreen(apiarioId: args),
          );
        }
        return MaterialPageRoute(builder: (_) => ArniaFormScreen());

      // Routes for inspection management
      case AppConstants.controlloCreateRoute:
        // Verify arguments are correct
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ControlloArniaScreen(arniaId: args),
          );
        }
        return _errorRoute();

      // Routes for queen management
      case AppConstants.reginaListRoute:
        return MaterialPageRoute(builder: (_) => ReginaListScreen());
        
      case AppConstants.reginaDetailRoute:
        // Verify arguments are correct
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ReginaDetailScreen(reginaId: args),
          );
        }
        return _errorRoute();

      // Routes for treatment management
      case AppConstants.trattamentiRoute:
        return MaterialPageRoute(builder: (_) => TrattamentiScreen());
        
      case AppConstants.nuovoTrattamentoRoute:
        // Check if an apiary is specified
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => TrattamentoFormScreen(apiarioId: args),
          );
        }
        return MaterialPageRoute(builder: (_) => TrattamentoFormScreen());

      // Routes for honey super and production management
      case AppConstants.melariRoute:
        return MaterialPageRoute(builder: (_) => MelariScreen());
      
      // Route for map
      case AppConstants.mappaRoute:
        return MaterialPageRoute(builder: (_) => MappaScreen());
      
      // Routes for payment management
      case AppConstants.pagamentiRoute:
        return MaterialPageRoute(builder: (_) => PagamentiScreen());
        
      case AppConstants.pagamentoDetailRoute:
        // Verify arguments are correct
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => PagamentoDetailScreen(pagamentoId: args),
          );
        }
        return _errorRoute();
        
      case AppConstants.pagamentoCreateRoute:
        // If args is null, it's a creation, otherwise it's a modification
        return MaterialPageRoute(
          builder: (_) => PagamentoFormScreen(pagamentoId: args as int?),
        );
        
      case AppConstants.quoteRoute:
        return MaterialPageRoute(builder: (_) => QuoteScreen());
        
      // Routes for equipment management
      case AppConstants.attrezzatureRoute:
        return MaterialPageRoute(builder: (_) => AttrezzatureListScreen());

      case AppConstants.attrezzaturaDetailRoute:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => AttrezzaturaDetailScreen(attrezzaturaId: args),
          );
        }
        return _errorRoute();

      case AppConstants.attrezzaturaCreateRoute:
        // If args is null, it's a creation, otherwise it's a modification
        return MaterialPageRoute(
          builder: (_) => AttrezzaturaFormScreen(attrezzaturaId: args as int?),
        );

      case AppConstants.spesaAttrezzaturaCreateRoute:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => SpesaAttrezzaturaFormScreen(
              attrezzaturaId: args['attrezzaturaId'],
              attrezzaturaNome: args['attrezzaturaNome'],
              condivisoConGruppo: args['condivisoConGruppo'] ?? false,
              gruppoId: args['gruppoId'],
            ),
          );
        }
        return _errorRoute();

      case AppConstants.manutenzioneCreateRoute:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ManutenzioneFormScreen(
              attrezzaturaId: args['attrezzaturaId'],
              attrezzaturaNome: args['attrezzaturaNome'],
              condivisoConGruppo: args['condivisoConGruppo'] ?? false,
              gruppoId: args['gruppoId'],
            ),
          );
        }
        return _errorRoute();

      case AppConstants.chatRoute:
        return MaterialPageRoute(builder: (_) => ChatScreen());
        
      // Route for voice input with Wit.ai - Updated to use the new class
      case AppConstants.voiceCommandRoute:
        return MaterialPageRoute(builder: (_) => VoiceCommandScreen());

      // Route for voice entry verification
      case AppConstants.voiceVerificationRoute:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => VoiceEntryVerificationScreen(
              batch: args['batch'],
              onSuccess: args['onSuccess'] ?? () {},
              onCancel: args['onCancel'] ?? () {},
            ),
          );
        }
        return _errorRoute();

      default:
        return _errorRoute();
    }
  }
  
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Errore'),
        ),
        body: Center(
          child: Text('Pagina non trovata'),
        ),
      );
    });
  }
}