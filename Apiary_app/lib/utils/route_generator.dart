import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/apiario/apiario_list_screen.dart';
import '../screens/apiario/apiario_detail_screen.dart';
import '../screens/apiario/apiario_form_screen.dart';

class RouteGenerator {
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
        
      // Aggiungi altre route qui
      
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