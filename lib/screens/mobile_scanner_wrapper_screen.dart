import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/mobile_scanner_service.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/qr_navigator_service.dart';

class MobileScannerWrapperScreen extends StatefulWidget {
  const MobileScannerWrapperScreen({Key? key}) : super(key: key);

  @override
  _MobileScannerWrapperScreenState createState() => _MobileScannerWrapperScreenState();
}

class _MobileScannerWrapperScreenState extends State<MobileScannerWrapperScreen> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  bool _isProcessing = false;
  final MobileScannerService _scannerService = MobileScannerService();
  StreamSubscription<BarcodeCapture>? _subscription;

  @override
  void initState() {
    super.initState();
    
    // Imposta il controller
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    
    // Registra l'observer del ciclo di vita
    WidgetsBinding.instance.addObserver(this);
    
    // Inizia a ascoltare i codici a barre
    _subscription = _controller.barcodes.listen(_handleBarcode);
    
    // Avvia lo scanner
    unawaited(_controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Se il controller non è pronto, non cercare di avviarlo o fermarlo
    if (_controller.value.isInitialized != true) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // Riavvia scanner quando l'app riprende
        _subscription = _controller.barcodes.listen(_handleBarcode);
        unawaited(_controller.start());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Ferma scanner quando l'app è in pausa
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
        break;
    }
  }

  @override
  void dispose() {
    // Ferma l'ascolto del ciclo di vita
    WidgetsBinding.instance.removeObserver(this);
    
    // Ferma l'ascolto dei codici a barre
    unawaited(_subscription?.cancel());
    _subscription = null;
    
    // Dispose del widget
    super.dispose();
    
    // Dispose del controller
    unawaited(_controller.dispose());
  }

  // Gestisce un codice a barre scansionato
  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final qrData = _scannerService.processBarcode(capture);
    if (qrData == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Feedback tattile
      HapticFeedback.mediumImpact();
      
      // Pausa la scansione
      await _controller.stop();
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      final connectivityService = ConnectivityService();
      
      final qrNavigator = QrNavigatorService(connectivityService, apiService);
      
      // Verifica e naviga al risultato
      final success = await qrNavigator.navigateToQrResult(context, qrData);
      
      if (!success) {
        // Se non è stato possibile navigare, resettiamo lo scanner
        setState(() {
          _isProcessing = false;
        });
        await _controller.start();
      }
      
    } catch (e) {
      // Mostra errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isProcessing = false;
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcola la finestra di scansione (80% della larghezza e 40% dell'altezza)
    final scannerSize = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(scannerSize.width / 2, scannerSize.height / 2),
      width: scannerSize.width * 0.8,
      height: scannerSize.height * 0.4,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Scansiona QR Code'),
        actions: [
          // Pulsante torcia
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) {
                return SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner con overlay personalizzato
          Stack(
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                onDetect: (capture) {
                  _handleBarcode(capture);
                },
              ),
              // Custom overlay usando uno Stack separato
              _scannerService.buildScannerOverlay(context, _controller),
            ],
          ),
          
          // Overlay di elaborazione
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Elaborazione in corso...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}