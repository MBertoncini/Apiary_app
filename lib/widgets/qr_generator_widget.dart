import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/mobile_scanner_service.dart';

/// Widget per generare e visualizzare codici QR per arnie e apiari
class QrGeneratorWidget extends StatelessWidget {
  final dynamic entity;
  final MobileScannerService service;
  final VoidCallback? onShare;
  
  const QrGeneratorWidget({
    Key? key,
    required this.entity,
    required this.service,
    this.onShare,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    String qrData = '';
    String title = '';
    String details = '';
    
    // Genera dati QR in base al tipo di entità
    if (entity is Map<String, dynamic> && entity.containsKey('numero') && entity.containsKey('apiario')) {
      // È un'arnia
      final arnia = entity;
      qrData = service.generateArniaQrData(
        arnia['id'], 
        arnia['numero'], 
        arnia['apiario'], 
        arnia['apiario_nome'] ?? 'Apiario'
      );
      title = 'Arnia ${arnia['numero']}';
      details = 'Apiario: ${arnia['apiario_nome'] ?? 'Sconosciuto'}';
    } else if (entity is Map<String, dynamic> && entity.containsKey('nome') && !entity.containsKey('arnia')) {
      // È un apiario
      final apiario = entity;
      qrData = service.generateApiarioQrData(
        apiario['id'], 
        apiario['nome'], 
        apiario['latitudine'] as double?, 
        apiario['longitudine'] as double?
      );
      title = apiario['nome'];
      details = 'Posizione: ${apiario['posizione'] ?? "Non specificata"}';
    } else {
      return Center(
        child: Text('Tipo di entità non supportato per la generazione QR'),
      );
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titolo
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              details,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            
            // Visualizzazione QR code
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                gapless: false,
              ),
            ),
            const SizedBox(height: 24),
            
            // Pulsanti azioni
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Copia dati QR
                OutlinedButton.icon(
                  icon: Icon(Icons.copy),
                  label: Text('Copia'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: qrData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Codice QR copiato negli appunti'),
                      ),
                    );
                  },
                ),
                
                // Condividi QR
                ElevatedButton.icon(
                  icon: Icon(Icons.share),
                  label: Text('Condividi'),
                  onPressed: () async {
                    try {
                      // Crea un widget QR temporaneo
                      final qrImage = QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 300,
                        backgroundColor: Colors.white,
                      );
                      
                      // Salva l'immagine QR
                      final directory = await getTemporaryDirectory();
                      final path = '${directory.path}/qr_code.png';
                      final file = File(path);
                      
                      // Renderizza il QR in un'immagine
                      final qrPainter = QrPainter(
                        data: qrData,
                        version: QrVersions.auto,
                        color: const Color(0xFF000000),
                        emptyColor: Colors.white,
                        gapless: true,
                      );
                      
                      final picData = await qrPainter.toImageData(300);
                      await file.writeAsBytes(picData!.buffer.asUint8List());
                      
                      // Condividi l'immagine
                      await Share.shareXFiles(
                        [XFile(path)],
                        text: '$title - Scansionami per visualizzare i dettagli',
                        subject: title,
                      );
                      
                      // Callback personalizzato
                      if (onShare != null) {
                        onShare!();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Errore durante la condivisione: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}