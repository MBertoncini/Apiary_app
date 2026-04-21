// lib/screens/mappa/nomadismo_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';

// ── Modello preset miele ──────────────────────────────────────────────────────
// `nome`, `periodo`, `regioni`, `desc` sono localizzati a runtime via AppStrings.
class _Preset {
  final String key, pianta, emoji;
  final int taxonKey;
  final Color colore, coloreBordo;
  const _Preset({
    required this.key, required this.pianta,
    required this.emoji, required this.taxonKey,
    required this.colore, required this.coloreBordo,
  });
}

const List<_Preset> _presets = [
  _Preset(key:'acacia',     pianta:'Robinia pseudoacacia', emoji:'🌸', taxonKey:5352251, colore:Color(0xFFFFF9C4), coloreBordo:Color(0xFFF5C518)),
  _Preset(key:'castagno',   pianta:'Castanea sativa',      emoji:'🌰', taxonKey:5333294, colore:Color(0xFFEFEBE9), coloreBordo:Color(0xFF795548)),
  _Preset(key:'tiglio',     pianta:'Tilia',                emoji:'🍃', taxonKey:3152041, colore:Color(0xFFC8E6C9), coloreBordo:Color(0xFF388E3C)),
  _Preset(key:'lavanda',    pianta:'Lavandula',            emoji:'💜', taxonKey:2927302, colore:Color(0xFFE1BEE7), coloreBordo:Color(0xFF7B1FA2)),
  _Preset(key:'sulla',      pianta:'Hedysarum coronarium', emoji:'🌺', taxonKey:2960919, colore:Color(0xFFFFCDD2), coloreBordo:Color(0xFFC62828)),
  _Preset(key:'corbezzolo', pianta:'Arbutus unedo',        emoji:'🍓', taxonKey:2882803, colore:Color(0xFFFFCCBC), coloreBordo:Color(0xFFBF360C)),
  _Preset(key:'eucalipto',  pianta:'Eucalyptus',           emoji:'🌿', taxonKey:7493935, colore:Color(0xFFB2DFDB), coloreBordo:Color(0xFF00695C)),
  _Preset(key:'girasole',   pianta:'Helianthus annuus',    emoji:'🌻', taxonKey:9206251, colore:Color(0xFFFFF9C4), coloreBordo:Color(0xFFF9A825)),
  _Preset(key:'trifoglio',  pianta:'Trifolium',            emoji:'🍀', taxonKey:2973363, colore:Color(0xFFDCEDC8), coloreBordo:Color(0xFF558B2F)),
  _Preset(key:'agrumi',     pianta:'Citrus',               emoji:'🍊', taxonKey:3190155, colore:Color(0xFFFFE0B2), coloreBordo:Color(0xFFE65100)),
];

// ── Famiglie mellifere ────────────────────────────────────────────────────────
const _famiglieMellifere = {
  'Lamiaceae','Fabaceae','Rosaceae','Apiaceae','Boraginaceae',
  'Asteraceae','Fagaceae','Ericaceae','Myrtaceae','Rutaceae',
  'Malvaceae','Brassicaceae','Lythraceae','Salicaceae','Polygonaceae',
};

// ── Screen ────────────────────────────────────────────────────────────────────
class NomadismoScreen extends StatefulWidget {
  const NomadismoScreen({super.key});
  @override
  State<NomadismoScreen> createState() => _NomadismoScreenState();
}

class _NomadismoScreenState extends State<NomadismoScreen> {
  final _mapController = MapController();

  _Preset?  _presetAttivo;
  bool      _analizzaModo  = false;
  bool      _legendaAperta = false;      // collassata di default
  LatLng?   _analisiCenter;
  List<Map<String, dynamic>> _apiari = [];
  // ignore: unused_field
  bool      _loadingApiari = true;
  Position? _currentPosition;
  double    _mapRotation = 0;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApiari();
      _getCurrentPosition();
    });
  }

  Future<void> _getCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 10);
    } catch (_) {}
  }

  void _resetRotation() {
    _mapController.rotate(0);
    setState(() => _mapRotation = 0);
  }

  Color _colorFromString(String s) {
    final hue = (s.codeUnits.fold(0, (a, b) => a + b) * 37) % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.55, 0.45).toColor();
  }

  void _showApiarioInfo(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.hive, color: ThemeConstants.primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(a['nome'] ?? 'Apiario', overflow: TextOverflow.ellipsis,
              style: GoogleFonts.caveat(fontSize: 20, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((a['posizione'] ?? '').toString().isNotEmpty)
              _InfoRow(icon: Icons.place_outlined, label: a['posizione'].toString()),
            if ((a['note'] ?? '').toString().isNotEmpty)
              _InfoRow(icon: Icons.notes_outlined, label: a['note'].toString()),
            _InfoRow(
              icon: Icons.my_location_outlined,
              label: '${double.tryParse(a['latitudine'].toString())?.toStringAsFixed(4) ?? ''}, '
                     '${double.tryParse(a['longitudine'].toString())?.toStringAsFixed(4) ?? ''}',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_s.btnClose)),
        ],
      ),
    );
  }

  Future<void> _loadApiari() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.get('apiari/');
      final list = data is List ? data : (data is Map ? data['results'] ?? [] : []);
      if (mounted) setState(() { _apiari = List<Map<String,dynamic>>.from(list); _loadingApiari = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingApiari = false);
    }
  }

  // ── GBIF: specie vicine a un punto ──────────────────────────────────────────
  Future<List<Map<String,dynamic>>> _fetchSpecie(LatLng centro, double raggioKm) async {
    final lat = centro.latitude;
    final lng = centro.longitude;
    final dLat = raggioKm / 111.0;
    final dLng = raggioKm / (111.0 * cos(lat * pi / 180));
    final url = Uri.parse(
      'https://api.gbif.org/v1/occurrence/search'
      '?decimalLatitude=${(lat-dLat).toStringAsFixed(4)},${(lat+dLat).toStringAsFixed(4)}'
      '&decimalLongitude=${(lng-dLng).toStringAsFixed(4)},${(lng+dLng).toStringAsFixed(4)}'
      '&kingdomKey=6&hasCoordinate=true&hasGeospatialIssue=false'
      '&year=2010,2025&limit=300'
    );
    final resp = await http.get(url, headers: {'User-Agent': 'ApiaryApp/1.0'}).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return [];
    final results = (jsonDecode(resp.body)['results'] as List?) ?? [];

    // Aggrega per specie
    final Map<dynamic, Map<String,dynamic>> dict = {};
    for (final occ in results) {
      final key  = occ['speciesKey'] ?? occ['scientificName'];
      final nome = (occ['species'] ?? occ['scientificName'] ?? '') as String;
      final fam  = (occ['family'] ?? '') as String;
      if (key == null || nome.isEmpty) continue;
      dict.putIfAbsent(key, () => {
        'nome': nome, 'famiglia': fam,
        'mellifera': _famiglieMellifere.contains(fam),
        'count': 0,
        'gbifUrl': 'https://www.gbif.org/species/$key',
      });
      dict[key]!['count'] = (dict[key]!['count'] as int) + 1;
    }
    final list = dict.values.toList()
      ..sort((a, b) {
        final ma = (a['mellifera'] as bool) ? 0 : 1;
        final mb = (b['mellifera'] as bool) ? 0 : 1;
        if (ma != mb) return ma.compareTo(mb);
        return (b['count'] as int).compareTo(a['count'] as int);
      });
    return list;
  }

  // ── Tap mappa ───────────────────────────────────────────────────────────────
  void _onMapTap(TapPosition _, LatLng pos) {
    if (!_analizzaModo) return;
    setState(() { _analizzaModo = false; _analisiCenter = pos; });
    _mostraBottomSheet(pos);
  }

  void _mostraBottomSheet(LatLng pos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SpecieBottomSheet(centro: pos, fetchFn: _fetchSpecie),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Rebuild on language change so localized text refreshes live.
    context.watch<LanguageService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_s.nomadismoTitle, style: GoogleFonts.caveat(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: ThemeConstants.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(top: 8, left: 8, right: 8, child: _buildTopOverlay()),
          Positioned(bottom: 8, left: 8, right: 8, child: _buildBottomOverlay()),
        ],
      ),
    );
  }

  // ── Mappa ───────────────────────────────────────────────────────────────────
  Widget _buildMap() {
    final circleLayers = _analisiCenter == null ? <CircleMarker>[] : [
      CircleMarker(
        point: _analisiCenter!,
        radius: 5000, useRadiusInMeter: true,
        color: const Color(0x1A1565C0),
        borderColor: const Color(0xFF1565C0),
        borderStrokeWidth: 2,
      ),
    ];

    final markers = _apiari
      .where((a) => a['latitudine'] != null && a['longitudine'] != null)
      .map<Marker>((a) {
        final lat = double.tryParse(a['latitudine'].toString()) ?? 0;
        final lng = double.tryParse(a['longitudine'].toString()) ?? 0;
        final username = a['proprietario_username'] as String?;
        final avatarInitial = (username != null && username.isNotEmpty) ? username[0].toUpperCase() : null;
        final avatarColor = username != null ? _colorFromString(username) : null;
        final proprietarioFoto =
            (a['proprietario_immagine_profilo'] as String?)?.trim().isNotEmpty == true
                ? a['proprietario_immagine_profilo'] as String
                : (a['proprietario_profile_image'] as String?)?.trim().isNotEmpty == true
                    ? a['proprietario_profile_image'] as String
                    : null;
        return Marker(
          point: LatLng(lat, lng),
          width: 64, height: 58,
          builder: (_) => GestureDetector(
            onTap: () => _showApiarioInfo(a),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 4, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: ThemeConstants.primaryColor.withOpacity(0.45), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.hive, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                if (avatarInitial != null)
                  Positioned(
                    top: 0, left: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.2)),
                      child: ClipOval(
                        child: proprietarioFoto != null
                            ? CachedNetworkImage(imageUrl: proprietarioFoto, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Center(child: Text(avatarInitial, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white))),
                                placeholder: (_, __) => const SizedBox.shrink())
                            : Center(child: Text(avatarInitial, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]),
                      child: Text(a['nome'] ?? 'Apiario',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();

    // Current position marker
    if (_currentPosition != null) {
      markers.add(Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        width: 18, height: 18,
        builder: (_) => Container(
          decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
        ),
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: const LatLng(42.0, 12.5),
        zoom: 6,
        onTap: _onMapTap,
        rotationThreshold: 15.0,
        enableMultiFingerGestureRace: true,
        onMapEvent: (event) {
          if (event is MapEventRotate) {
            setState(() => _mapRotation = _mapController.rotation);
          }
        },
        interactiveFlags: _analizzaModo
            ? InteractiveFlag.none   // blocca pan/zoom mentre si sceglie un punto
            : InteractiveFlag.all,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.apiary.app',
        ),
        if (_presetAttivo != null)
          Opacity(
            opacity: 0.62,
            child: TileLayer(
              urlTemplate:
                'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@1x.png'
                '?taxonKey=${_presetAttivo!.taxonKey}&style=classic.poly&bin=hex',
              userAgentPackageName: 'com.apiary.app',
            ),
          ),
        CircleLayer(circles: circleLayers),
        MarkerLayer(markers: markers),
      ],
    );
  }

  // ── Controlli mappa (sinistra in basso) ─────────────────────────────────────
  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bottone nord
        FloatingActionButton(
          heroTag: 'nomadismo_nord',
          mini: true,
          backgroundColor: Colors.white,
          onPressed: _resetRotation,
          tooltip: _s.mappaTooltipNord,
          child: Transform.rotate(
            angle: -_mapRotation * pi / 180,
            child: const Icon(Icons.navigation, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        // Bottone posizione
        FloatingActionButton(
          heroTag: 'nomadismo_position',
          mini: true,
          backgroundColor: Colors.white,
          onPressed: _getCurrentPosition,
          tooltip: _s.mappaTooltipPosizione,
          child: const Icon(Icons.my_location, color: Colors.black87),
        ),
      ],
    );
  }

  // ── Overlay in alto: preset chips + info card ────────────────────────────────
  Widget _buildTopOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _PresetChip(
                label: _s.nomadismoSoloApiari,
                selected: _presetAttivo == null,
                colore: Colors.grey.shade200,
                coloreBordo: Colors.grey.shade400,
                onTap: () => setState(() { _presetAttivo = null; _analisiCenter = null; }),
              ),
              ..._presets.map((p) => _PresetChip(
                label: '${p.emoji} ${_s.nomadismoPresetNome(p.key)}',
                selected: _presetAttivo?.key == p.key,
                colore: p.colore,
                coloreBordo: p.coloreBordo,
                onTap: () => setState(() {
                  _presetAttivo = _presetAttivo?.key == p.key ? null : p;
                  _analisiCenter = null;
                }),
              )),
            ],
          ),
        ),
        // Info card preset (animata)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _presetAttivo == null
            ? const SizedBox.shrink()
            : _buildPresetInfo(_presetAttivo!),
        ),
      ],
    );
  }

  Widget _buildPresetInfo(_Preset p) {
    final s = _s;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeConstants.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: p.coloreBordo, width: 4)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0,2))],
      ),
      child: Row(
        children: [
          Text(p.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nomadismoPresetNome(p.key), style: GoogleFonts.caveat(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeConstants.textPrimaryColor)),
                Text(p.pianta, style: GoogleFonts.quicksand(fontSize: 11, fontStyle: FontStyle.italic, color: ThemeConstants.textSecondaryColor)),
                Text(s.nomadismoPresetDesc(p.key), style: GoogleFonts.quicksand(fontSize: 11, color: ThemeConstants.textSecondaryColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(s.nomadismoPresetPeriodo(p.key), style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.bold, color: p.coloreBordo)),
              const SizedBox(height: 2),
              Text(s.nomadismoPresetRegioni(p.key), style: GoogleFonts.quicksand(fontSize: 10, color: ThemeConstants.textSecondaryColor), textAlign: TextAlign.right, maxLines: 2),
            ],
          ),
        ],
      ),
    );
  }

  // ── Overlay in basso: bottone analizza + legenda ─────────────────────────────
  Widget _buildBottomOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controlli mappa (sinistra) + Bottone analizza (destra)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMapControls(),
            const Spacer(),
            GestureDetector(
            onTap: () => setState(() { _analizzaModo = !_analizzaModo; if (!_analizzaModo) _analisiCenter = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _analizzaModo ? ThemeConstants.secondaryColor : ThemeConstants.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0,3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_analizzaModo ? Icons.close : Icons.search, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _analizzaModo ? _s.nomadismoBtnTocca : _s.nomadismoBtnAnalizza,
                    style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
        const SizedBox(height: 6),
        // Legenda collassabile
        _buildLegenda(),
      ],
    );
  }

  Widget _buildLegenda() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.cardColor.withOpacity(0.94),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0,2))],
      ),
      child: Column(
        children: [
          // Header sempre visibile — tocca per aprire/chiudere
          InkWell(
            onTap: () => setState(() => _legendaAperta = !_legendaAperta),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: ThemeConstants.textSecondaryColor),
                  const SizedBox(width: 6),
                  Text(_s.mappaLegenda, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.bold, color: ThemeConstants.textSecondaryColor)),
                  const Spacer(),
                  Text(_legendaAperta ? '−' : '+', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeConstants.primaryColor)),
                ],
              ),
            ),
          ),
          // Corpo espandibile
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _legendaAperta ? _buildLegendaCorpo() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaCorpo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          _LegendaVoce(
            icona: Container(width: 14, height: 9, decoration: BoxDecoration(
              color: const Color(0x4D50A050), border: Border.all(color: const Color(0xFF388E3C)),
              borderRadius: BorderRadius.circular(2),
            )),
            label: _s.nomadismoLegendaDensita,
          ),
          const SizedBox(height: 4),
          _LegendaVoce(
            icona: Container(width: 14, height: 14, decoration: BoxDecoration(
              color: ThemeConstants.primaryColor, shape: BoxShape.circle,
            ), child: const Center(child: Text('🍯', style: TextStyle(fontSize: 8)))),
            label: _s.nomadismoLegendaApiario,
          ),
          const SizedBox(height: 4),
          _LegendaVoce(
            icona: Container(width: 14, height: 14, decoration: BoxDecoration(
              color: const Color(0x1A1565C0), shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
            )),
            label: _s.nomadismoLegendaAreaAnalisi,
          ),
          const SizedBox(height: 4),
          Text(_s.nomadismoLegendaDati, style: GoogleFonts.quicksand(fontSize: 10, color: ThemeConstants.textSecondaryColor)),
        ],
      ),
    );
  }
}

// ── Chip preset ───────────────────────────────────────────────────────────────
class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color colore, coloreBordo;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.selected, required this.colore, required this.coloreBordo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? coloreBordo : colore,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: coloreBordo, width: 1.8),
          boxShadow: selected ? [BoxShadow(color: coloreBordo.withOpacity(0.4), blurRadius: 6, offset: const Offset(0,2))] : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: selected ? Colors.white : ThemeConstants.textPrimaryColor,
          ),
        ),
      ),
    );
  }
}

// ── Voce legenda ──────────────────────────────────────────────────────────────
class _LegendaVoce extends StatelessWidget {
  final Widget icona;
  final String label;
  const _LegendaVoce({required this.icona, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icona,
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.quicksand(fontSize: 11, color: ThemeConstants.textPrimaryColor))),
      ],
    );
  }
}

// ── BottomSheet analisi specie ────────────────────────────────────────────────
class _SpecieBottomSheet extends StatefulWidget {
  final LatLng centro;
  final Future<List<Map<String,dynamic>>> Function(LatLng, double) fetchFn;
  const _SpecieBottomSheet({required this.centro, required this.fetchFn});
  @override
  State<_SpecieBottomSheet> createState() => _SpecieBottomSheetState();
}

class _SpecieBottomSheetState extends State<_SpecieBottomSheet> {
  List<Map<String,dynamic>>? _specie;
  bool _loading = true;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final specie = await widget.fetchFn(widget.centro, 5.0);
      if (mounted) setState(() { _specie = specie; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _errore = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LanguageService>(context, listen: false).strings;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.eco_outlined, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.nomadismoFloraTitle,
                    style: GoogleFonts.caveat(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeConstants.textPrimaryColor),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), iconSize: 20, padding: EdgeInsets.zero),
              ],
            ),
            Text(
              '${widget.centro.latitude.toStringAsFixed(3)}, ${widget.centro.longitude.toStringAsFixed(3)}',
              style: GoogleFonts.quicksand(fontSize: 11, color: ThemeConstants.textSecondaryColor),
            ),
            const Divider(),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errore != null)
              Expanded(child: Center(child: Text(loc.nomadismoErrGbif(_errore!), style: const TextStyle(color: Colors.red))))
            else if (_specie!.isEmpty)
              Expanded(child: Center(child: Text(loc.nomadismoNessunaSpecie, style: GoogleFonts.quicksand(color: ThemeConstants.textSecondaryColor))))
            else
              Expanded(child: ListView(
                controller: scrollController,
                children: [
                  ..._specie!.where((s) => s['mellifera'] == true).take(15).map((s) => _SpecieTile(specie: s, mellifera: true)),
                  if (_specie!.any((s) => s['mellifera'] != true)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(loc.nomadismoAltrePiante, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.bold, color: ThemeConstants.textSecondaryColor)),
                    ),
                    ..._specie!.where((s) => s['mellifera'] != true).take(5).map((s) => _SpecieTile(specie: s, mellifera: false)),
                  ],
                  const SizedBox(height: 8),
                  Text(loc.nomadismoGbifFooter, style: GoogleFonts.quicksand(fontSize: 10, color: ThemeConstants.textSecondaryColor), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],
              )),
          ],
        ),
      ),
    );
  }
}

// ── Riga info apiario ─────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ThemeConstants.textSecondaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.quicksand(fontSize: 13, color: ThemeConstants.textPrimaryColor))),
        ],
      ),
    );
  }
}

class _SpecieTile extends StatelessWidget {
  final Map<String,dynamic> specie;
  final bool mellifera;
  const _SpecieTile({required this.specie, required this.mellifera});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(specie['nome'] ?? '', style: GoogleFonts.quicksand(fontSize: 13, fontStyle: FontStyle.italic, color: ThemeConstants.textPrimaryColor, fontWeight: FontWeight.w600)),
                if ((specie['famiglia'] ?? '').isNotEmpty)
                  Text(specie['famiglia'], style: GoogleFonts.quicksand(fontSize: 11, color: ThemeConstants.textSecondaryColor)),
              ],
            ),
          ),
          if (mellifera)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: Text('mellifera', style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
            ),
          const SizedBox(width: 6),
          Text('${specie['count']}', style: GoogleFonts.quicksand(fontSize: 11, color: ThemeConstants.textSecondaryColor)),
        ],
      ),
    );
  }
}
