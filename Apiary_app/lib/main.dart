import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Imposta orientamento solo verticale
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(ApiarioManagerApp());
}