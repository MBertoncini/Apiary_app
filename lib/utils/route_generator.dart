// lib/utils/route_generator_updated.dart
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
import '../screens/voice_command_screen.dart';

class RouteGeneratorUpdated {
 
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Recupera gli argomenti passati alla navigazione
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
        // Verifica che gli argomenti siano corretti
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
      
      // Rotte per la gestione dei gruppi
      case AppConstants.gruppiListRoute:
        return MaterialPageRoute(builder: (_) => GruppiListScreen());
        
      case AppConstants.gruppoDetailRoute:
        // Verifica che gli argomenti siano corretti
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => GruppoDetailScreen(gruppoId: args),
          );
        }
        return _errorRoute();
        
      case AppConstants.gruppoCreateRoute:
        // Se args è null, è una creazione, altrimenti è una modifica
        return MaterialPageRoute(
          builder: (_) => GruppoFormScreen(gruppo: args as Gruppo?),
        );
        
      case AppConstants.gruppoInvitoRoute:
        // Verifica che gli argomenti siano corretti
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => GruppoInvitoScreen(gruppoId: args),
          );
        }
        return _errorRoute();

      case '/qr_scanner':
        return MaterialPageRoute(builder: (_) => MobileScannerWrapperScreen());

      // Rotte per la gestione delle arnie
      case AppConstants.arniaListRoute:
        return MaterialPageRoute(builder: (_) => ArniaListScreen());
            
      case AppConstants.arniaDetailRoute:
        // Verifica che gli argomenti siano corretti
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ArniaDetailScreen(arniaId: args),
          );
        }
        return _errorRoute();
        
      case AppConstants.creaArniaRoute:
        // Verifica se è specificato un apiario
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ArniaFormScreen(apiarioId: args),
          );
        }
        return MaterialPageRoute(builder: (_) => ArniaFormScreen());

      // Rotte per la gestione dei controlli
      case AppConstants.controlloCreateRoute:
        // Verifica che gli argomenti siano corretti
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ControlloArniaScreen(arniaId: args),
          );
        }
        return _errorRoute();

      // Rotte per la gestione delle regine
      case AppConstants.reginaListRoute:
        return MaterialPageRoute(builder: (_) => ReginaListScreen());
        
      case AppConstants.reginaDetailRoute:
        // Verifica che gli argomenti siano corretti
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ReginaDetailScreen(reginaId: args),
          );
        }
        return _errorRoute();

      // Rotte per la gestione dei trattamenti sanitari
      case AppConstants.trattamentiRoute:
        return MaterialPageRoute(builder: (_) => TrattamentiScreen());
        
      case AppConstants.nuovoTrattamentoRoute:
        // Verifica se è specificato un apiario
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => TrattamentoFormScreen(apiarioId: args),
          );
        }
        return MaterialPageRoute(builder: (_) => TrattamentoFormScreen());

      // Rotte per la gestione dei melari e produzioni
      case AppConstants.melariRoute:
        return MaterialPageRoute(builder: (_) => MelariScreen());
      
      // Rotta per la mappa
      case AppConstants.mappaRoute:
        return MaterialPageRoute(builder: (_) => MappaScreen());
      
      // Rotte per la gestione dei pagamenti
      case AppConstants.pagamentiRoute:
        return MaterialPageRoute(builder: (_) => PagamentiScreen());
        
      case AppConstants.pagamentoDetailRoute:
        // Verifica che gli argomenti siano corretti
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => PagamentoDetailScreen(pagamentoId: args),
          );
        }
        return _errorRoute();
        
      case AppConstants.pagamentoCreateRoute:
        // Se args è null, è una creazione, altrimenti è una modifica
        return MaterialPageRoute(
          builder: (_) => PagamentoFormScreen(pagamentoId: args as int?),
        );
        
      case AppConstants.quoteRoute:
        return MaterialPageRoute(builder: (_) => QuoteScreen());
        
      case AppConstants.chatRoute:
        return MaterialPageRoute(builder: (_) => ChatScreen());
        
      // NUOVA ROTTA PER L'INPUT VOCALE CON GOOGLE API
      case AppConstants.voiceCommandRoute:
        return MaterialPageRoute(builder: (_) => VoiceCommandScreenUpdated());
      
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