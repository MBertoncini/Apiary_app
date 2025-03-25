// utils/chart_exporter.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ChartExporter {
  static final ScreenshotController _screenshotController = ScreenshotController();
  
  // Cattura uno screenshot di un widget
  static Future<Uint8List> captureWidget(Widget widget, {Size? size}) async {
    return await _screenshotController.captureFromWidget(
      widget,
      delay: const Duration(milliseconds: 10),
      targetSize: size,
    );
  }
  
  // Salva l'immagine in un file e restituisce il percorso
  static Future<String> saveChart(Uint8List bytes, String title) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s]'), '_').replaceAll(' ', '_');
    final fileName = '${sanitizedTitle}_$timestamp.png';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(bytes);
    return file.path;
  }
  
  // Condividi un'immagine
  static Future<void> shareChart(Uint8List bytes, String title) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'chart_$timestamp.png';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Grafico: $title',
      subject: 'Grafico da Apiario Manager',
    );
  }
  
  // Metodo convenience che cattura, salva e condivide un grafico
  static Future<void> captureAndShareChart(
    BuildContext context, 
    Widget chart, 
    String title,
  ) async {
    try {
      // Prima catturiamo il grafico
      final bytes = await captureWidget(
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(16),
          child: chart,
        ),
        size: Size(600, 400), // Dimensione fissa per esportazione
      );
      
      // Mostriamo un dialog con opzioni
      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Salva grafico'),
                  onTap: () async {
                    Navigator.pop(context);
                    
                    // Salva il grafico
                    final path = await saveChart(bytes, title);
                    
                    // Feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Grafico salvato'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Condividi grafico'),
                  onTap: () async {
                    Navigator.pop(context);
                    await shareChart(bytes, title);
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Errore nell\'esportazione del grafico: $e');
      
      // Feedback errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: impossibile esportare il grafico'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}