import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/dao/apiario_dao.dart';
import '../database/dao/arnia_dao.dart';
import '../database/dao/controllo_arnia_dao.dart';
import '../utils/date_formatters.dart';
import 'package:flutter/foundation.dart';

class ExportService {
  final ApiarioDao _apiarioDao = ApiarioDao();
  final ArniaDao _arniaDao = ArniaDao();
  final ControlloArniaDao _controlloArniaDao = ControlloArniaDao();
  
  // Richiedi permessi di storage
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      var storageStatus = await Permission.storage.status;
      
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      
      return storageStatus.isGranted;
    }
    
    // Su iOS non è necessario chiedere permessi per scrivere nella directory dell'app
    return true;
  }
  
  // Crea un documento PDF con controlli di un'arnia
  Future<File?> exportControlliToFile(int arniaId, {bool asPdf = true}) async {
    if (!await requestStoragePermission()) {
      return null;
    }
    
    try {
      // Ottieni l'arnia
      final arnia = await _arniaDao.getById(arniaId);
      if (arnia == null) {
        throw Exception('Arnia non trovata');
      }
      
      // Ottieni l'apiario
      final apiario = await _apiarioDao.getById(arnia.apiario);
      if (apiario == null) {
        throw Exception('Apiario non trovato');
      }
      
      // Ottieni i controlli
      final controlli = await _controlloArniaDao.getByArnia(arniaId);
      
      // Crea directory di export se non esiste
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      if (asPdf) {
        return await _createPdfFile(
          apiario, 
          arnia, 
          controlli, 
          '$exportDir/controlli_arnia_${arnia.numero}_$timestamp.pdf'
        );
      } else {
        return await _createCsvFile(
          controlli, 
          '$exportDir/controlli_arnia_${arnia.numero}_$timestamp.csv'
        );
      }
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return null;
    }
  }
  
  // Crea file PDF con i controlli di un'arnia
  Future<File> _createPdfFile(
    dynamic apiario, 
    dynamic arnia, 
    List<dynamic> controlli, 
    String filePath
  ) async {
    final pdf = pw.Document();
    
    // Crea il documento PDF
    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Apiario Manager',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                pw.Text(
                  'Data: ${DateFormatter.formatDate(DateTime.now().toString())}',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Apiario Manager',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        build: (context) => [
          // Titolo
          pw.Center(
            child: pw.Text(
              'Report Controlli Arnia',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Informazioni apiario e arnia
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Informazioni Arnia',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Apiario:', apiario.nome),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Arnia Numero:', arnia.numero.toString()),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Data installazione:', DateFormatter.formatDate(arnia.dataInstallazione)),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Stato:', arnia.attiva ? 'Attiva' : 'Inattiva'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Tabella controlli
          pw.Text(
            'Lista Controlli',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          
          controlli.isEmpty
              ? pw.Center(
                  child: pw.Text(
                    'Nessun controllo registrato',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                )
              : pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(3),
                  },
                  header: _buildTableHeader(),
                  children: controlli.map<pw.TableRow>((controllo) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(DateFormatter.formatDate(controllo.data)),
                        _buildTableCell(controllo.telainiScorte.toString()),
                        _buildTableCell(controllo.telainiCovata.toString()),
                        _buildTableCell(controllo.presenzaRegina ? 'Sì' : 'No'),
                        _buildTableCell(controllo.problemiSanitari ? 'Sì' : 'No'),
                        _buildTableCell(controllo.note ?? '-'),
                      ],
                    );
                  }).toList(),
                ),
        ],
      ),
    );
    
    // Salva il file
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  // Helper per creare una riga di informazioni nel PDF
  pw.Row _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 5),
        pw.Text(value),
      ],
    );
  }
  
  // Helper per creare l'intestazione della tabella nel PDF
  pw.TableRow _buildTableHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _buildTableCell('Data', header: true),
        _buildTableCell('Scorte', header: true),
        _buildTableCell('Covata', header: true),
        _buildTableCell('Regina', header: true),
        _buildTableCell('Problemi', header: true),
        _buildTableCell('Note', header: true),
      ],
    );
  }
  
  // Helper per creare una cella della tabella nel PDF
  pw.Widget _buildTableCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
  
  // Crea file CSV con i controlli di un'arnia
  Future<File> _createCsvFile(List<dynamic> controlli, String filePath) async {
    // Preparazione dei dati per il CSV
    List<List<dynamic>> rows = [];
    
    // Intestazione
    rows.add([
      'Data', 
      'Telaini Scorte', 
      'Telaini Covata', 
      'Presenza Regina', 
      'Regina Vista', 
      'Uova Fresche',
      'Celle Reali',
      'Numero Celle',
      'Regina Sostituita',
      'Sciamatura',
      'Data Sciamatura',
      'Problemi Sanitari',
      'Note Problemi',
      'Note',
    ]);
    
    // Dati
    for (var controllo in controlli) {
      rows.add([
        controllo.data,
        controllo.telainiScorte,
        controllo.telainiCovata,
        controllo.presenzaRegina ? 'Sì' : 'No',
        controllo.reginaVista ? 'Sì' : 'No',
        controllo.uovaFresche ? 'Sì' : 'No',
        controllo.celleReali ? 'Sì' : 'No',
        controllo.celleReali ? controllo.numeroCelleReali : '',
        controllo.reginaSostituita ? 'Sì' : 'No',
        controllo.sciamatura ? 'Sì' : 'No',
        controllo.dataSciamatura ?? '',
        controllo.problemiSanitari ? 'Sì' : 'No',
        controllo.noteProblemi ?? '',
        controllo.note ?? '',
      ]);
    }
    
    // Converti in CSV
    String csv = const ListToCsvConverter().convert(rows);
    
    // Salva il file
    final file = File(filePath);
    await file.writeAsBytes(utf8.encode(csv));
    return file;
  }
  
  // Condividi file esportato
  Future<void> shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Condivisione dati Apiario Manager',
        subject: 'Export dati Apiario Manager',
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
  
  // Esporta e condividi controlli di un'arnia
  Future<void> exportAndShareControlli(int arniaId, {bool asPdf = true}) async {
    final file = await exportControlliToFile(arniaId, asPdf: asPdf);
    if (file != null) {
      await shareFile(file);
    }
  }
}