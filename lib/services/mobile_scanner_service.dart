import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Servizio che gestisce la scansione QR tramite mobile_scanner
class MobileScannerService {
  /// Estrae informazioni da un QR code scansionato
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
      debugPrint('Error extracting QR data: $e');
      return null;
    }
  }

  /// Genera dati QR per un'arnia
  String generateArniaQrData(int arniaId, int numero, int apiarioId, String apiarioNome) {
    return 'ARNIA:$arniaId:$numero:$apiarioId:$apiarioNome';
  }

  /// Genera dati QR per un apiario
  String generateApiarioQrData(int apiarioId, String nome, double? lat, double? lng) {
    String coordPart = '';
    if (lat != null && lng != null) {
      coordPart = ':$lat:$lng';
    }
    return 'APIARIO:$apiarioId:$nome$coordPart';
  }

  /// Verifica se un codice a barre contiene dati di un'arnia o apiario
  Map<String, dynamic>? processBarcode(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty || capture.barcodes.first.rawValue == null) return null;
    
    final data = capture.barcodes.first.rawValue!;
    
    // Se il QR inizia con ARNIA: o APIARIO: è probabilmente valido
    if (data.startsWith('ARNIA:') || data.startsWith('APIARIO:')) {
      return extractQrData(data);
    }
    
    return null;
  }

  /// Costruisce un overlay personalizzato per lo scanner
  Widget buildScannerOverlay(BuildContext context, MobileScannerController controller) {
    final scanWindow = Rect.fromCenter(
      center: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.4,
    );
    
    return Stack(
      children: [
        // Overlay semi-trasparente
        Container(
          color: Colors.black54,
        ),
        
        // Finestra di scansione
        Positioned(
          left: scanWindow.left,
          top: scanWindow.top,
          width: scanWindow.width,
          height: scanWindow.height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        
        // Ritaglio dell'overlay per creare la finestra di scansione
        ClipPath(
          clipper: ScannerOverlayClipper(scanWindow),
          child: Container(
            color: Colors.transparent,
          ),
        ),
        
        // Testo informativo
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Inquadra un codice QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Clipper personalizzato per ritagliare l'area di scansione
class ScannerOverlayClipper extends CustomClipper<Path> {
  final Rect scanWindow;
  
  ScannerOverlayClipper(this.scanWindow);
  
  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanWindow)
      ..fillType = PathFillType.evenOdd;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}