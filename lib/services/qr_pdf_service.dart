import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'mobile_scanner_service.dart';

/// Genera e stampa/condivide un foglio A4 con i QR di tutte le arnie di un apiario.
class QrPdfService {
  final MobileScannerService _scannerService = MobileScannerService();

  Future<Uint8List> _buildPdfBytes({
    required String apiarioNome,
    required List<dynamic> arnie,
  }) async {
    // Pre-renderizza le immagini QR per ogni arnia
    final items = <({pw.MemoryImage img, String label})>[];

    for (final arnia in arnie) {
      final id = int.tryParse(arnia['id'].toString()) ?? 0;
      final numero = int.tryParse(arnia['numero'].toString()) ?? 0;
      final apiarioId = int.tryParse(arnia['apiario'].toString()) ?? 0;
      final qrData = _scannerService.generateArniaQrData(
        id,
        numero,
        apiarioId,
        arnia['apiario_nome']?.toString() ?? apiarioNome,
      );

      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: Colors.white,
        gapless: true,
      );

      final imgData = await painter.toImageData(300);
      if (imgData != null) {
        items.add((
          img: pw.MemoryImage(imgData.buffer.asUint8List()),
          label: 'Arnia ${arnia['numero']}',
        ));
      }
    }

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'QR Arnie – $apiarioNome',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${items.length} arnie  •  $dateStr',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Divider(height: 14),
          ],
        ),
        build: (_) {
          // Suddivide gli item in righe da 3 colonne
          final rows = <List<({pw.MemoryImage img, String label})>>[];
          for (var i = 0; i < items.length; i += 3) {
            final end = (i + 3) > items.length ? items.length : i + 3;
            rows.add(items.sublist(i, end));
          }

          return [
            pw.Column(
              children: rows.map((row) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      ...row.map((item) => pw.Expanded(
                            child: pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(horizontal: 4),
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  border:
                                      pw.Border.all(color: PdfColors.grey300),
                                  borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(6),
                                  ),
                                ),
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Image(item.img,
                                        width: 130, height: 130),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      item.label,
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                      // Celle vuote per completare l'ultima riga
                      ...List.generate(
                        3 - row.length,
                        (_) => pw.Expanded(child: pw.SizedBox()),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Apre il dialogo di stampa nativo con il foglio A4 dei QR.
  Future<void> printQrSheet({
    required Map<String, dynamic> apiario,
    required List<dynamic> arnie,
  }) async {
    final bytes = await _buildPdfBytes(
      apiarioNome: apiario['nome'] as String? ?? 'Apiario',
      arnie: arnie,
    );
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'QR_Arnie_${apiario['nome']}.pdf',
    );
  }

  /// Condivide il PDF tramite il menu di condivisione del sistema.
  Future<void> shareQrSheet({
    required Map<String, dynamic> apiario,
    required List<dynamic> arnie,
  }) async {
    final bytes = await _buildPdfBytes(
      apiarioNome: apiario['nome'] as String? ?? 'Apiario',
      arnie: arnie,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'QR_Arnie_${apiario['nome']}.pdf',
    );
  }
}
