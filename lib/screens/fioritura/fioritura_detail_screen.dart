import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/fioritura.dart';
import '../../models/fioritura_conferma.dart';
import '../../services/api_service.dart';
import '../../services/fioritura_service.dart';
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class FiorituraDetailScreen extends StatefulWidget {
  final int fiorituraId;

  const FiorituraDetailScreen({required this.fiorituraId});

  @override
  _FiorituraDetailScreenState createState() => _FiorituraDetailScreenState();
}

class _FiorituraDetailScreenState extends State<FiorituraDetailScreen> {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  late FiorituraService _service;
  Fioritura? _fioritura;
  bool _isRefreshing = true;

  // per il form conferma
  int? _myIntensita;
  final _notaCtrl = TextEditingController();
  bool _savingConferma = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = FiorituraService(Provider.of<ApiService>(context, listen: false));
    _load();
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isRefreshing = true);
    try {
      final fioriture = await _service.getFioriture();
      final f = fioriture.firstWhere((f) => f.id == widget.fiorituraId,
          orElse: () => throw Exception('Fioritura non trovata'));
      final conferme = await _service.getMieConferme();
      if (mounted) {
        setState(() {
          _fioritura = f;
          _isRefreshing = false;
          // Precompila il mio voto se già confermato
          if (f.confermaDaMe) {
            final mia = conferme
                .where((c) => c.fioritura == f.id)
                .toList();
            if (mia.isNotEmpty) {
              _myIntensita = mia.first.intensita;
              _notaCtrl.text = mia.first.nota ?? '';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_s.fiorituraDetailError(e.toString()))));
      }
    }
  }

  Future<void> _conferma() async {
    setState(() => _savingConferma = true);
    try {
      final updated = await _service.confermaFioritura(
        _fioritura!.id,
        intensita: _myIntensita,
        nota: _notaCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _fioritura = updated;
          _savingConferma = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.fiorituraDetailConfirmOk)),
        );
      }
    } catch (e) {
      setState(() => _savingConferma = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_s.fiorituraDetailError(e.toString()))));
    }
  }

  Future<void> _rimuoviConferma() async {
    setState(() => _savingConferma = true);
    try {
      await _service.rimuoviConferma(_fioritura!.id);
      _myIntensita = null;
      _notaCtrl.clear();
      await _load();
    } catch (e) {
      setState(() => _savingConferma = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_s.fiorituraDetailError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    final s = _s;
    if (_isRefreshing && _fioritura == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.fiorituraDetailTitle)),
        body: const Column(children: [LinearProgressIndicator(minHeight: 2)]),
      );
    }
    if (_fioritura == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.fiorituraDetailTitle)),
        body: Center(child: Text(s.fiorituraDetailNotFound)),
      );
    }

    final f = _fioritura!;
    final isActive = f.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(f.pianta),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: s.fiorituraDetailTooltipEdit,
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                AppConstants.fiorituraCreateRoute,
                arguments: f,
              );
              if (result == true) _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Header badge stato
            Row(
              children: [
                Icon(Icons.local_florist,
                    color: isActive ? Colors.green : Colors.grey, size: 28),
                SizedBox(width: 10),
                Text(
                  f.pianta,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: ThemeConstants.textPrimaryColor),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.grey)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? s.fiorituraCardAttiva : s.fiorituraCardNonAttiva,
                    style: TextStyle(
                        color: isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Info card
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (f.apiarioNome != null)
                      _infoRow(Icons.hive, s.labelApiario, f.apiarioNome!),
                    _infoRow(Icons.calendar_today, s.fiorituraDetailLblPeriodo,
                        _dateRange(f.dataInizio, f.dataFine, s)),
                    if (f.raggio != null)
                      _infoRow(Icons.radio_button_checked, s.fiorituraDetailLblRaggio,
                          '${f.raggio} m'),
                    if (f.piantaTipo != null)
                      _infoRow(Icons.park, s.fiorituraDetailLblTipoPianta,
                          Fioritura.piantaTipoLabel[f.piantaTipo] ??
                              f.piantaTipo!),
                    if (f.intensita != null)
                      _infoRow(Icons.star, s.fiorituraDetailLblIntensitaStimata,
                          Fioritura.intensitaLabel[f.intensita!]),
                    _infoRow(Icons.public, s.fiorituraDetailLblVisibilita,
                        f.pubblica ? s.fiorituraDetailValPubblica : s.fiorituraDetailValPrivata),
                    if (f.creatoreUsername != null)
                      _infoRow(Icons.person_outline, s.fiorituraDetailLblSegnalata,
                          f.creatoreUsername!),
                    if (f.note != null && f.note!.isNotEmpty)
                      _infoRow(Icons.note, s.labelNotes, f.note!),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Statistiche community
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.fiorituraDetailLblCommunity,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statChip(
                            Icons.people, '${f.nConferme}', s.fiorituraDetailStatConfermanti),
                        const SizedBox(width: 12),
                        if (f.intensitaMedia != null)
                          _statChip(Icons.star,
                              f.intensitaMedia!.toStringAsFixed(1),
                              s.fiorituraDetailStatIntensita),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Sezione conferma personale
            Card(
              color: f.confermaDaMe
                  ? Colors.green.withOpacity(0.07)
                  : Colors.amber.withOpacity(0.05),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          f.confermaDaMe
                              ? Icons.check_circle
                              : Icons.help_outline,
                          color: f.confermaDaMe ? Colors.green : Colors.amber,
                        ),
                        SizedBox(width: 8),
                        Text(
                          f.confermaDaMe
                              ? s.fiorituraDetailConfermata
                              : s.fiorituraDetailConfermaQuestion,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Slider intensità
                    Text(s.fiorituraDetailLblIntensity,
                        style: const TextStyle(fontSize: 12,
                            color: ThemeConstants.textSecondaryColor)),
                    SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (i) {
                        final v = i + 1;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _myIntensita =
                                    _myIntensita == v ? null : v),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: (_myIntensita != null &&
                                          _myIntensita! >= v)
                                      ? Colors.amber
                                      : Colors.grey[300],
                                  size: 28,
                                ),
                                Text(
                                  Fioritura.intensitaLabel[v],
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: ThemeConstants.textSecondaryColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _notaCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: s.fiorituraDetailHintNota,
                        prefixIcon: Icon(Icons.note, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _savingConferma
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : Icon(Icons.check),
                            label: Text(f.confermaDaMe
                                ? s.fiorituraDetailBtnAggiorna
                                : s.fiorituraDetailBtnConferma),
                            onPressed: _savingConferma ? null : _conferma,
                          ),
                        ),
                        if (f.confermaDaMe) ...[
                          SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _savingConferma
                                ? null
                                : _rimuoviConferma,
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red[200]!)),
                            child: Text(s.fiorituraDetailBtnRemove,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Mini mappa
            Text(s.fiorituraDetailLblPosizione,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.textPrimaryColor)),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(f.latitudine, f.longitudine),
                    zoom: 12,
                    interactiveFlags: InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.apiario_manager',
                    ),
                    if (f.raggio != null)
                      CircleLayer(circles: [
                        CircleMarker(
                          point: LatLng(f.latitudine, f.longitudine),
                          radius: f.raggio!.toDouble(),
                          color: Colors.green.withOpacity(0.25),
                          borderColor: Colors.green,
                          borderStrokeWidth: 2,
                          useRadiusInMeter: true,
                        ),
                      ]),
                    MarkerLayer(markers: [
                      Marker(
                        width: 32,
                        height: 32,
                        point: LatLng(f.latitudine, f.longitudine),
                        builder: (_) => Icon(Icons.local_florist,
                            color: isActive ? Colors.green : Colors.grey,
                            size: 28),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      )),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ThemeConstants.textSecondaryColor),
          SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: ThemeConstants.textSecondaryColor)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: ThemeConstants.textPrimaryColor,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeConstants.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeConstants.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: ThemeConstants.textSecondaryColor)),
        ],
      ),
    );
  }

  String _dateRange(String start, String? end, AppStrings s) {
    final from = _fmt(start);
    if (end == null) return s.fiorituraDateFrom(from);
    return '$from → ${_fmt(end)}';
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
