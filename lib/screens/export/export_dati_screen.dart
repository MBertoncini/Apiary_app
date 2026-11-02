import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/apiario.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../widgets/drawer_widget.dart';

/// Esportazione dei dati dell'utente in un file Excel.
///
/// Il file è generato dal backend (`GET /api/v1/export/excel/`), un foglio per
/// ogni sezione selezionata, e poi passato al foglio di condivisione di
/// sistema: da lì l'utente lo salva nei file, su Drive, lo invia per email...
class ExportDatiScreen extends StatefulWidget {
  const ExportDatiScreen({Key? key}) : super(key: key);

  @override
  State<ExportDatiScreen> createState() => _ExportDatiScreenState();
}

class _ExportDatiScreenState extends State<ExportDatiScreen> {
  /// Chiavi delle sezioni, nello stesso ordine dei fogli del backend
  /// (`core/export_excel.py`, `SEZIONI_KEYS`).
  static const List<String> _sezioni = [
    'apiari', 'arnie', 'colonie', 'controlli', 'regine', 'trattamenti',
    'varroa', 'alimentazioni', 'melari', 'smielature', 'invasettamenti',
    'vendite', 'pagamenti', 'attrezzature', 'spese_attrezzatura',
  ];

  /// Sezioni non legate a un apiario: il filtro per apiario non le restringe.
  static const Set<String> _sezioniNonApiario = {
    'vendite', 'pagamenti', 'attrezzature', 'spese_attrezzatura',
  };

  late ApiService _api;
  List<Apiario> _apiari = [];

  /// null = tutti gli apiari / tutti gli anni.
  int? _apiarioId;
  int? _anno;
  final Set<String> _selezionate = {..._sezioni};
  bool _esportando = false;

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _api = ApiService(Provider.of<AuthService>(context, listen: false));
    _loadApiari();
  }

  /// Se la lista apiari non arriva, l'export resta possibile su "tutti".
  Future<void> _loadApiari() async {
    try {
      final list = await _api.getAll(ApiConstants.apiariUrl);
      if (!mounted) return;
      setState(() {
        _apiari = list
            .map((e) => Apiario.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      });
    } catch (e) {
      debugPrint('ExportDati: caricamento apiari fallito: $e');
    }
  }

  Future<void> _esporta(Rect? shareOrigin) async {
    final s = _s;
    final lang =
        Provider.of<LanguageService>(context, listen: false).currentCode;
    setState(() => _esportando = true);
    try {
      final params = <String, String>{
        'lang': lang,
        if (_apiarioId != null) 'apiario': '$_apiarioId',
        if (_anno != null) 'anno': '$_anno',
        // Tutte selezionate = nessun filtro: il backend esporta ogni foglio,
        // anche quelli aggiunti in futuro.
        if (_selezionate.length < _sezioni.length)
          'sezioni': _sezioni.where(_selezionate.contains).join(','),
      };
      final url = Uri.parse(ApiConstants.exportExcelUrl)
          .replace(queryParameters: params)
          .toString();
      final bytes = await _api.getBytes(url);

      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/apiary_export_$stamp.xlsx');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: s.exportDatiShareSubject,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.exportDatiErrore(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _esportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;
    final annoCorrente = DateTime.now().year;
    final anni = List<int>.generate(10, (i) => annoCorrente - i);
    final mostraNotaApiario = _apiarioId != null &&
        _selezionate.any(_sezioniNonApiario.contains);

    return Scaffold(
      appBar: AppBar(title: Text(s.exportDatiTitle)),
      drawer: AppDrawer(currentRoute: AppConstants.exportDatiRoute),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.table_chart,
                  color: ThemeConstants.primaryColor, size: 32),
              title: Text(s.exportDatiIntro),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: _apiarioId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: s.exportDatiApiario,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<int?>(
                  value: null, child: Text(s.exportDatiTuttiApiari)),
              ..._apiari.map((a) => DropdownMenuItem<int?>(
                    value: a.id,
                    child: Text(a.nome, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged:
                _esportando ? null : (v) => setState(() => _apiarioId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: _anno,
            decoration: InputDecoration(
              labelText: s.exportDatiAnno,
              helperText: s.exportDatiAnnoHelper,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<int?>(
                  value: null, child: Text(s.exportDatiTuttiAnni)),
              ...anni.map((a) =>
                  DropdownMenuItem<int?>(value: a, child: Text('$a'))),
            ],
            onChanged: _esportando ? null : (v) => setState(() => _anno = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.exportDatiSezioni,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: _esportando
                    ? null
                    : () => setState(() => _selezionate.addAll(_sezioni)),
                child: Text(s.exportDatiSelezionaTutto),
              ),
              TextButton(
                onPressed: _esportando
                    ? null
                    : () => setState(() => _selezionate.clear()),
                child: Text(s.exportDatiDeselezionaTutto),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _sezioni.map((key) {
              return FilterChip(
                label: Text(s.exportDatiSezione(key)),
                selected: _selezionate.contains(key),
                onSelected: _esportando
                    ? null
                    : (sel) => setState(() {
                          sel ? _selezionate.add(key) : _selezionate.remove(key);
                        }),
              );
            }).toList(),
          ),
          if (mostraNotaApiario) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.exportDatiNotaApiario,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Builder(builder: (btnContext) {
            return ElevatedButton.icon(
              icon: _esportando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.file_download),
              label: Text(_esportando ? s.exportDatiInCorso : s.exportDatiBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _esportando || _selezionate.isEmpty
                  ? null
                  : () {
                      // Su iPad il foglio di condivisione va ancorato al bottone.
                      final box = btnContext.findRenderObject() as RenderBox?;
                      final origin = box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size;
                      _esporta(origin);
                    },
            );
          }),
          if (_selezionate.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.exportDatiNessunaSezione,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
