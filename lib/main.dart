// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/route_generator.dart';
import 'utils/navigator_key.dart';
import 'constants/app_constants.dart';
import 'constants/theme_constants.dart';
import 'database/database_helper.dart';
import 'provider_setup.dart';

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

    runApp(
      MultiProvider(
        providers: providers,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: AppConstants.appName,
          theme: ThemeConstants.getTheme(),
          initialRoute: AppConstants.splashRoute,
          onGenerateRoute: RouteGenerator.generateRoute,
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