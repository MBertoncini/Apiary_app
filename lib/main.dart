// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/route_generator.dart';
import 'utils/navigator_key.dart';
import 'constants/app_constants.dart';
import 'constants/theme_constants.dart';
import 'database/database_helper.dart';
import 'provider_setup.dart';
import 'services/language_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('======= FLUTTER ERROR =======');
        debugPrint('${details.exception}');
        debugPrint('${details.stack}');
      }
    };

    final dbHelper = DatabaseHelper();
    await dbHelper.database;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Edge-to-edge: il contenuto si estende sotto status bar e nav bar
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    runApp(
      MultiProvider(
        providers: providers,
        child: Consumer<LanguageService>(
          builder: (context, languageService, _) => MaterialApp(
            navigatorKey: navigatorKey,
            title: AppConstants.appName,
            theme: ThemeConstants.getTheme(),
            locale: languageService.locale,
            supportedLocales: LanguageService.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            onGenerateRoute: RouteGenerator.generateRoute,
            // SafeArea globale: protegge il basso da gesture bar / tasti nav
            // top: false perché AppBar gestisce già la status bar
            builder: (context, child) => SafeArea(
              top: false,
              child: child!,
            ),
          ),
        ),
      ),
    );
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('======= UNCAUGHT ERROR =======');
      debugPrint('$error');
      debugPrint('$stack');
    }
  });
}
