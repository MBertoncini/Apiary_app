import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import '../services/qr_service.dart';

class QrScannerScreen extends StatefulWidget {
  final Function(Map<String, dynamic> data) onScanSuccess;
  
  const QrScannerScreen({
    Key? key,
    required this.onScanSuccess,
  }) : super(key: key);
  
  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool hasPermission = false;
  bool isScanning = true;
  final QrService _qrService = QrService();
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }
  
  Future<void> _checkPermission() async {
    final hasPermission = await _qrService.hasCameraPermission();
    setState(() {
      this.hasPermission = hasPermission;
    });
    
    if (!hasPermission) {
      final granted = await _qrService.requestCameraPermission();
      setState(() {
        this.hasPermission = granted;
      });
    }
  }
  
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }
  
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanning) return;
      
      final data = scanData.code;
      if (data != null) {
        final extractedData = _qrService.extractQrData(data);
        if (extractedData != null) {
          setState(() {
            isScanning = false;
          });
          controller.pauseCamera();
          widget.onScanSuccess(extractedData);
        }
      }
    });
  }
  
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Scanner QR'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Permesso fotocamera richiesto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Per utilizzare lo scanner QR è necessario concedere l\'accesso alla fotocamera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final granted = await _qrService.requestCameraPermission();
                  setState(() {
                    hasPermission = granted;
                  });
                },
                child: Text('Concedi permesso'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner QR'),
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).primaryColor,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
          Positioned(
            bottom: 0,
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
      ),
    );
  }
}