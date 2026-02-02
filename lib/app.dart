// File: lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart'; // Importa solo da qui, non da api_service.dart
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'utils/route_generator.dart';
import 'constants/app_constants.dart';
import 'constants/theme_constants.dart';
import 'screens/splash_screen.dart';

class ApiarioManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService),
        ),
        Provider(create: (_) => StorageService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeConstants.getTheme(),
        onGenerateRoute: RouteGenerator.generateRoute,
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}