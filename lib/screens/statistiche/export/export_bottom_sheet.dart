import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../services/statistiche_service.dart';
import '../../../services/language_service.dart';
import '../../../l10n/app_strings.dart';

/// Bottom sheet per esportare dati in Excel o PDF.
/// Uso:
///   showModalBottomSheet(context: context, builder: (_) => ExportBottomSheet(
///     service: _service,
///     titolo: 'Report',
///     colonne: ['Col1', 'Col2'],
///     righe: [[val1, val2], ...],
///   ));
class ExportBottomSheet extends StatefulWidget {
  final StatisticheService service;
  final String titolo;
  final List<String> colonne;
  final List<List<dynamic>> righe;

  const ExportBottomSheet({
    super.key,
    required this.service,
    required this.titolo,
    required this.colonne,
    required this.righe,
  });

  @override
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  bool _loadingExcel = false;
  bool _loadingPdf = false;
  String? _message;
  bool _messageIsError = false;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  Future<void> _esportaExcel() async {
    setState(() { _loadingExcel = true; _message = null; });
    try {
      final bytes = await widget.service.exportExcel(widget.titolo, widget.colonne, widget.righe);
      if (bytes.isNotEmpty) await _salvaFile(bytes, '${widget.titolo}.xlsx');
      setState(() { _message = _s.exportExcelSalvato; _messageIsError = false; _loadingExcel = false; });
    } catch (e) {
      setState(() { _message = _s.exportErrExcel(e.toString()); _messageIsError = true; _loadingExcel = false; });
    }
  }

  Future<void> _esportaPdf() async {
    setState(() { _loadingPdf = true; _message = null; });
    try {
      final bytes = await widget.service.exportPdf(widget.titolo, widget.colonne, widget.righe);
      if (bytes.isNotEmpty) await _salvaFile(bytes, '${widget.titolo}.pdf');
      setState(() { _message = _s.exportPdfSalvato; _messageIsError = false; _loadingPdf = false; });
    } catch (e) {
      setState(() { _message = _s.exportErrPdf(e.toString()); _messageIsError = true; _loadingPdf = false; });
    }
  }

  Future<void> _salvaFile(List<int> bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.exportTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.titolo, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _loadingExcel ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.table_chart),
                  label: Text(s.exportExcel),
                  onPressed: _loadingExcel || _loadingPdf ? null : _esportaExcel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1A6B3C)),
                    foregroundColor: const Color(0xFF1A6B3C),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: _loadingPdf ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
                  label: Text(s.exportPdf),
                  onPressed: _loadingExcel || _loadingPdf ? null : _esportaPdf,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(color: _messageIsError ? Colors.red : Colors.green)),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
