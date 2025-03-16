import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;

class QrService {
  // Verifica se i permessi della fotocamera sono concessi
  Future<bool> hasCameraPermission() async {
    var status = await Permission.camera.status;
    return status.isGranted;
  }
  
  // Richiedi i permessi della fotocamera
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.request();
    return status.isGranted;
  }
  
  // Genera un QR code come widget
  Widget generateQrCodeWidget({
    required String data,
    double size = 200,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      gapless: false,
      embeddedImage: AssetImage('assets/images/app_icon_small.png'),
      embeddedImageStyle: QrEmbeddedImageStyle(
        size: Size(40, 40),
      ),
    );
  }
  
  // Genera un QR code come immagine e lo salva
  Future<File?> generateQrCodeImage({
    required String data,
    required String fileName,
    double size = 320,
  }) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception('QR code data is invalid: ${qrValidationResult.error}');
      }
      
      final qrCode = qrValidationResult.qrCode;
      
      final painter = QrPainter.withQr(
        qr: qrCode!,
        color: const Color(0xFF000000),
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final file = File('$path/$fileName.png');
      
      final picData = await painter.toImageData(size.toDouble());
      await file.writeAsBytes(picData!.buffer.asUint8List());
      
      return file;
    } catch (e) {
      print('Error generating QR code: $e');
      return null;
    }
  }
  
  // Genera e condividi un QR code
  Future<void> shareQrCode({
    required String data,
    required String title,
    String? message,
  }) async {
    try {
      final tempFile = await generateQrCodeImage(
        data: data,
        fileName: 'qr_share_temp',
      );
      
      if (tempFile != null) {
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: message ?? 'QR Code: $title',
          subject: title,
        );
      }
    } catch (e) {
      print('Error sharing QR code: $e');
    }
  }
  
  // Genera dati per QR code di un'arnia
  String generateArniaQrData(int arniaId, int numero, int apiarioId, String apiarioNome) {
    return 'ARNIA:$arniaId:$numero:$apiarioId:$apiarioNome';
  }
  
  // Genera dati per QR code di un apiario
  String generateApiarioQrData(int apiarioId, String nome, double? lat, double? lng) {
    String coordPart = '';
    if (lat != null && lng != null) {
      coordPart = ':$lat:$lng';
    }
    return 'APIARIO:$apiarioId:$nome$coordPart';
  }
  
  // Estrai informazioni da un QR code scansionato
  Map<String, dynamic>? extractQrData(String data) {
    try {
      final parts = data.split(':');
      
      if (parts.length < 2) return null;
      
      if (parts[0] == 'ARNIA' && parts.length >= 5) {
        return {
          'type': 'arnia',
          'id': int.parse(parts[1]),
          'numero': int.parse(parts[2]),
          'apiarioId': int.parse(parts[3]),
          'apiarioNome': parts[4],
        };
      } else if (parts[0] == 'APIARIO') {
        if (parts.length >= 3) {
          final result = {
            'type': 'apiario',
            'id': int.parse(parts[1]),
            'nome': parts[2],
          };
          
          if (parts.length >= 5) {
            result['lat'] = double.parse(parts[3]);
            result['lng'] = double.parse(parts[4]);
          }
          
          return result;
        }
      }
      
      return null;
    } catch (e) {
      print('Error extracting QR data: $e');
      return null;
    }
  }
}