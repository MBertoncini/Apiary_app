import 'dart:async';  // Aggiungi questa importazione
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'database/database_helper.dart';

void main() {
  // Questo wrapper cattura tutti gli errori non gestiti nell'applicazione
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Gestisce gli errori di Flutter (widget, rendering, ecc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('======= FLUTTER ERROR =======');
      print('${details.exception}');
      print('======= STACK TRACE =======');
      print('${details.stack}');
      print('===========================');
    };
    
    // Inizializza il database
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    
    // Imposta orientamento solo verticale
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Avvia l'app con Riverpod
    runApp(
      ProviderScope(
        child: ApiarioManagerApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    // Gestisce errori asincroni e altri errori non gestiti
    print('======= UNCAUGHT ERROR =======');
    print('$error');
    print('======= STACK TRACE =======');
    print('$stack');
    print('============================');
  });
}
