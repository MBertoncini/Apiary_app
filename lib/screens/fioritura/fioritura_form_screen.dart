import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/theme_constants.dart';
import '../../models/fioritura.dart';
import '../../services/api_service.dart';
import '../../services/fioritura_service.dart';

class FiorituraFormScreen extends StatefulWidget {
  final Fioritura? fioritura; // null = crea, non-null = modifica

  const FiorituraFormScreen({this.fioritura});

  @override
  _FiorituraFormScreenState createState() => _FiorituraFormScreenState();
}

class _FiorituraFormScreenState extends State<FiorituraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late FiorituraService _service;

  final _piantaCtrl = TextEditingController();
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

  static const List<Map<String, String>> _tipiPianta = [
    {'value': 'spontanea', 'label': 'Spontanea'},
    {'value': 'coltivata', 'label': 'Coltivata'},
    {'value': 'alberata', 'label': 'Alberata'},
    {'value': 'arborea', 'label': 'Arborea'},
    {'value': 'arbustiva', 'label': 'Arbustiva'},
  ];

  static const List<Map<String, dynamic>> _intensitaOptions = [
    {'value': 1, 'label': 'Scarsa'},
    {'value': 2, 'label': 'Discreta'},
    {'value': 3, 'label': 'Buona'},
    {'value': 4, 'label': 'Ottima'},
    {'value': 5, 'label': 'Eccezionale'},
  ];

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
    if (_dataInizio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inserisci la data di inizio')),
      );
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleziona la posizione sulla mappa')),
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
        'latitudine': _lat,
        'longitudine': _lng,
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
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.fioritura != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica fioritura' : 'Nuova fioritura'),
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: Icon(Icons.check),
              tooltip: 'Salva',
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Pianta
            TextFormField(
              controller: _piantaCtrl,
              decoration: InputDecoration(
                labelText: 'Pianta *',
                prefixIcon: Icon(Icons.local_florist),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            SizedBox(height: 12),

            // Tipo pianta
            DropdownButtonFormField<String>(
              value: _piantaTipo,
              decoration: InputDecoration(
                labelText: 'Tipo di pianta',
                prefixIcon: Icon(Icons.park),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Non specificato')),
                ..._tipiPianta.map((t) => DropdownMenuItem(
                    value: t['value'], child: Text(t['label']!))),
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
                        labelText: 'Data inizio *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_dataInizio != null
                          ? '${_dataInizio!.day}/${_dataInizio!.month}/${_dataInizio!.year}'
                          : 'Seleziona'),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data fine',
                        prefixIcon: Icon(Icons.event),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _dataFine != null
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 16),
                                onPressed: () =>
                                    setState(() => _dataFine = null))
                            : null,
                      ),
                      child: Text(_dataFine != null
                          ? '${_dataFine!.day}/${_dataFine!.month}/${_dataFine!.year}'
                          : 'Nessuna'),
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
                labelText: 'Raggio (metri)',
                prefixIcon: Icon(Icons.radio_button_checked),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),

            // Intensità
            DropdownButtonFormField<int>(
              value: _intensita,
              decoration: InputDecoration(
                labelText: 'Intensità fioritura',
                prefixIcon: Icon(Icons.star_border),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Non valutata')),
                ..._intensitaOptions.map((o) => DropdownMenuItem(
                    value: o['value'] as int,
                    child: Text(o['label'] as String))),
              ],
              onChanged: (v) => setState(() => _intensita = v),
            ),
            SizedBox(height: 12),

            // Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Note',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),

            // Pubblica
            SwitchListTile(
              title: Text('Visibile alla community'),
              subtitle: Text(
                  'Condividi questa fioritura con tutti gli apicoltori'),
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
              'Posizione *',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textPrimaryColor),
            ),
            SizedBox(height: 4),
            Text(
              'Tocca la mappa per impostare la posizione della fioritura',
              style: TextStyle(
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
              icon: Icon(Icons.my_location),
              label: Text('Usa la mia posizione attuale'),
              onPressed: _fetchCurrentLocation,
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
