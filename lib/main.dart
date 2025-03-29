// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/route_generator.dart';
import 'constants/app_constants.dart';
import 'database/database_helper.dart';
import 'provider_setup.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('======= FLUTTER ERROR =======');
      print('${details.exception}');
      print('======= STACK TRACE =======');
      print('${details.stack}');
      print('===========================');
    };

    final dbHelper = DatabaseHelper();
    await dbHelper.database;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(
      MultiProvider(
        providers: providers, // Usa i provider aggiornati definiti in provider_setup_updated.dart
        child: MaterialApp(
          title: AppConstants.appName,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          initialRoute: AppConstants.splashRoute,
          onGenerateRoute: RouteGeneratorUpdated.generateRoute, // Use the updated route generator
        ),
      ),
    );
  }, (Object error, StackTrace stack) {
    print('======= UNCAUGHT ERROR =======');
    print('$error');
    print('======= STACK TRACE =======');
    print('$stack');
    print('============================');
  });
}