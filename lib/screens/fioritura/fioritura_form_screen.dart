import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/piante_mellifere.dart';
import '../../constants/theme_constants.dart';
import '../../models/fioritura.dart';
import '../../services/api_service.dart';
import '../../services/fioritura_service.dart';
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class FiorituraFormScreen extends StatefulWidget {
  final Fioritura? fioritura; // null = crea, non-null = modifica

  const FiorituraFormScreen({this.fioritura});

  @override
  _FiorituraFormScreenState createState() => _FiorituraFormScreenState();
}

class _FiorituraFormScreenState extends State<FiorituraFormScreen> {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  final _formKey = GlobalKey<FormState>();
  late FiorituraService _service;

  final _piantaCtrl = TextEditingController();
  final _piantaFocusNode = FocusNode();
  final _noteCtrl = TextEditingController();
  final _raggioCtrl = TextEditingController();

  String? _piantaTipo;
  int? _intensita;
  bool _pubblica = false;
  DateTime? _dataInizio;
  DateTime? _dataFine;
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _mapReady = false;

  final MapController _mapCtrl = MapController();

  static const List<String> _tipiPiantaValues = [
    'spontanea', 'coltivata', 'alberata', 'arborea', 'arbustiva',
  ];

  String _tipoLabel(String value, AppStrings s) {
    switch (value) {
      case 'spontanea':  return s.fiorituraFormTipoSpontanea;
      case 'coltivata':  return s.fiorituraFormTipoColtivata;
      case 'alberata':   return s.fiorituraFormTipoAlberata;
      case 'arborea':    return s.fiorituraFormTipoArborea;
      case 'arbustiva':  return s.fiorituraFormTipoArbustiva;
      default:           return value;
    }
  }

  String _intensitaLabel(int value, AppStrings s) {
    switch (value) {
      case 1: return s.fiorituraFormIntensita1;
      case 2: return s.fiorituraFormIntensita2;
      case 3: return s.fiorituraFormIntensita3;
      case 4: return s.fiorituraFormIntensita4;
      case 5: return s.fiorituraFormIntensita5;
      default: return value.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    final f = widget.fioritura;
    if (f != null) {
      _piantaCtrl.text = f.pianta;
      _noteCtrl.text = f.note ?? '';
      _raggioCtrl.text = f.raggio?.toString() ?? '500';
      _piantaTipo = f.piantaTipo;
      _intensita = f.intensita;
      _pubblica = f.pubblica;
      _lat = f.latitudine;
      _lng = f.longitudine;
      try {
        _dataInizio = DateTime.parse(f.dataInizio);
        if (f.dataFine != null) _dataFine = DateTime.parse(f.dataFine!);
      } catch (_) {}
    } else {
      _raggioCtrl.text = '500';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service =
        FiorituraService(Provider.of<ApiService>(context, listen: false));
    if (_lat == null) _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _piantaCtrl.dispose();
    _piantaFocusNode.dispose();
    _noteCtrl.dispose();
    _raggioCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
        if (_mapReady) {
          _mapCtrl.move(LatLng(_lat!, _lng!), 13);
        }
      }
    } catch (_) {}
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_dataInizio ?? DateTime.now())
        : (_dataFine ?? _dataInizio ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _dataInizio = picked;
          if (_dataFine != null && _dataFine!.isBefore(_dataInizio!)) {
            _dataFine = null;
          }
        } else {
          _dataFine = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final s = _s;
    if (_dataInizio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.fiorituraFormErrDataInizio)),
      );
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.fiorituraFormErrPosition)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final data = {
        'pianta': _piantaCtrl.text.trim(),
        'pianta_tipo': _piantaTipo,
        'data_inizio':
            '${_dataInizio!.year}-${_dataInizio!.month.toString().padLeft(2, '0')}-${_dataInizio!.day.toString().padLeft(2, '0')}',
        'data_fine': _dataFine != null
            ? '${_dataFine!.year}-${_dataFine!.month.toString().padLeft(2, '0')}-${_dataFine!.day.toString().padLeft(2, '0')}'
            : null,
        'latitudine': double.parse(_lat!.toStringAsFixed(6)),
        'longitudine': double.parse(_lng!.toStringAsFixed(6)),
        'raggio': int.tryParse(_raggioCtrl.text) ?? 500,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'pubblica': _pubblica,
        'intensita': _intensita,
      };

      if (widget.fioritura == null) {
        await _service.createFioritura(data);
      } else {
        await _service.updateFioritura(widget.fioritura!.id, data);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.fiorituraFormError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    final s = _s;
    final isEdit = widget.fioritura != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? s.fiorituraFormTitleEdit : s.fiorituraFormTitleNew),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: s.fiorituraFormTooltipSave,
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Pianta – autocomplete da vocabolario standardizzato
            RawAutocomplete<PiantaMellifera>(
              textEditingController: _piantaCtrl,
              focusNode: _piantaFocusNode,
              displayStringForOption: (p) => p.nome,
              optionsBuilder: (textEditingValue) {
                final q = textEditingValue.text.trim();
                if (q.isEmpty) return const [];
                return PiantaMellifera.cerca(q);
              },
              onSelected: (PiantaMellifera pianta) {
                // Auto-compila tipo pianta se non già selezionato
                if (_piantaTipo == null && pianta.piantaTipo != null) {
                  setState(() => _piantaTipo = pianta.piantaTipo);
                }
              },
              fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: s.fiorituraFormLblPianta,
                    prefixIcon: const Icon(Icons.local_florist),
                    hintText: 'Es. Acacia, Castagno, Tiglio…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? s.trattamentoFormValidateCampoObbligatorio
                      : null,
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                );
              },
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (context, index) {
                        final pianta = options.elementAt(index);
                        final periodo = pianta.periodoFormatted;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.local_florist,
                              size: 18, color: Colors.green),
                          title: Text(pianta.labelCompleta),
                          subtitle: pianta.nomeScientifico != null
                              ? Text(
                                  periodo.isNotEmpty
                                      ? '${pianta.nomeScientifico} · $periodo'
                                      : pianta.nomeScientifico!,
                                  style: const TextStyle(fontSize: 11),
                                )
                              : null,
                          onTap: () => onSelected(pianta),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Tipo pianta
            DropdownButtonFormField<String>(
              value: _piantaTipo,
              decoration: InputDecoration(
                labelText: s.fiorituraFormLblTipoPianta,
                prefixIcon: const Icon(Icons.park),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(s.fiorituraFormHintNonSpecificato)),
                ..._tipiPiantaValues.map((v) => DropdownMenuItem(
                    value: v, child: Text(_tipoLabel(v, s)))),
              ],
              onChanged: (v) => setState(() => _piantaTipo = v),
            ),
            SizedBox(height: 12),

            // Date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: s.fiorituraFormLblDataInizio,
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_dataInizio != null
                          ? '${_dataInizio!.day}/${_dataInizio!.month}/${_dataInizio!.year}'
                          : s.fiorituraFormHintSeleziona),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: s.fiorituraFormLblDataFine,
                        prefixIcon: const Icon(Icons.event),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _dataFine != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () =>
                                    setState(() => _dataFine = null))
                            : null,
                      ),
                      child: Text(_dataFine != null
                          ? '${_dataFine!.day}/${_dataFine!.month}/${_dataFine!.year}'
                          : s.fiorituraFormHintNessuna),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Raggio
            TextFormField(
              controller: _raggioCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.fiorituraFormLblRaggio,
                prefixIcon: const Icon(Icons.radio_button_checked),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Intensità
            DropdownButtonFormField<int>(
              value: _intensita,
              decoration: InputDecoration(
                labelText: s.fiorituraFormLblIntensita,
                prefixIcon: const Icon(Icons.star_border),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(s.fiorituraFormHintNonValutata)),
                ...[1, 2, 3, 4, 5].map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(_intensitaLabel(v, s)))),
              ],
              onChanged: (v) => setState(() => _intensita = v),
            ),
            const SizedBox(height: 12),

            // Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.fiorituraFormLblNote,
                prefixIcon: const Icon(Icons.note),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Pubblica
            SwitchListTile(
              title: Text(s.fiorituraFormVisibilitaTitle),
              subtitle: Text(s.fiorituraFormVisibilitaSubtitle),
              secondary: Icon(Icons.public,
                  color: _pubblica ? Colors.blue : Colors.grey),
              value: _pubblica,
              onChanged: (v) => setState(() => _pubblica = v),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: ThemeConstants.dividerColor),
              ),
            ),
            SizedBox(height: 16),

            // Mappa per selezionare posizione
            Text(
              s.fiorituraDetailLblPosizione,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textPrimaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              s.fiorituraFormMapHint,
              style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConstants.textSecondaryColor),
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 260,
                child: FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    center: _lat != null
                        ? LatLng(_lat!, _lng!)
                        : LatLng(41.9028, 12.4964),
                    zoom: 11,
                    onMapReady: () => setState(() => _mapReady = true),
                    onTap: (tapPos, latlng) {
                      setState(() {
                        _lat = latlng.latitude;
                        _lng = latlng.longitude;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.apiario_manager',
                    ),
                    if (_lat != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 36,
                            height: 36,
                            point: LatLng(_lat!, _lng!),
                            builder: (_) => Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (_lat != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Lat: ${_lat!.toStringAsFixed(5)}, Lng: ${_lng!.toStringAsFixed(5)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: ThemeConstants.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.my_location),
              label: Text(s.fiorituraFormBtnUsePos),
              onPressed: _fetchCurrentLocation,
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
