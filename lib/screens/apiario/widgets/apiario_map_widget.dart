import 'dart:convert';
import 'dart:math' show min, max, Random, cos, sin, pi, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_constants.dart';
import '../../../services/api_service.dart';

// ════════════════════════════════════════════════════════════════
//  DATA MODELS
// ════════════════════════════════════════════════════════════════

/// Un segmento di vialetto: direzione assoluta (gradi) + lunghezza canvas.
class PathSegment {
  double angle;  // 0=destra, 90=basso, 180=sinistra, 270=su
  double length;

  PathSegment({required this.angle, this.length = 100.0});

  Map<String, dynamic> toJson() => {'angle': angle, 'length': length};

  factory PathSegment.fromJson(Map<String, dynamic> j) => PathSegment(
        angle: (j['angle'] as num).toDouble(),
        length: (j['length'] as num?)?.toDouble() ?? 100.0,
      );
}

// ── Tipo arnia (corrisponde a TIPO_ARNIA_CHOICES del backend) ──
enum HiveTipo {
  dadant,
  langstroth,
  top_bar,
  warre,
  osservazione,
  pappa_reale,
  nucleo_legno,
  nucleo_polistirolo,
  portasciami,
  apidea,
  mini_plus;

  static HiveTipo parse(String? s) {
    if (s == null) return HiveTipo.dadant;
    try { return HiveTipo.values.firstWhere((t) => t.name == s); }
    catch (_) { return HiveTipo.dadant; }
  }

  String get label {
    const m = {
      'dadant':             'Dadant-Blatt',
      'langstroth':         'Langstroth',
      'top_bar':            'Top Bar',
      'warre':              'Warré',
      'osservazione':       'Osservazione',
      'pappa_reale':        'Pappa Reale',
      'nucleo_legno':       'Nucleo (legno)',
      'nucleo_polistirolo': 'Nucleo (poli.)',
      'portasciami':        'Portasciami',
      'apidea':             'Apidea',
      'mini_plus':          'Mini-Plus',
    };
    return m[name] ?? name;
  }

  /// true per arnie da produzione vere e proprie
  bool get isFullHive => const {
    HiveTipo.dadant, HiveTipo.langstroth, HiveTipo.top_bar,
    HiveTipo.warre, HiveTipo.osservazione, HiveTipo.pappa_reale,
  }.contains(this);
}

enum MapElementType { nucleo, apidea, mini_plus, portasciami, albero, vialetto }

class MapElement {
  final String id;
  final MapElementType type;
  Offset position;

  int? numero;
  String? coloreHex;
  bool? attiva;
  int? nucleoDbId;

  List<PathSegment> segments;
  double pathWidth;

  MapElement({
    required this.id,
    required this.type,
    required this.position,
    this.numero,
    this.coloreHex,
    this.attiva,
    this.nucleoDbId,
    List<PathSegment>? segments,
    this.pathWidth = 40.0,
  }) : segments = segments ?? [];

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'type': type.name,
      'x': position.dx,
      'y': position.dy,
    };
    if (numero != null) m['numero'] = numero;
    if (coloreHex != null) m['colore_hex'] = coloreHex;
    if (attiva != null) m['attiva'] = attiva;
    if (nucleoDbId != null) m['nucleo_db_id'] = nucleoDbId;
    if (type == MapElementType.vialetto) {
      m['path_width'] = pathWidth;
      m['segments'] = segments.map((s) => s.toJson()).toList();
    }
    return m;
  }

  factory MapElement.fromJson(Map<String, dynamic> j) {
    MapElementType type;
    try {
      type = MapElementType.values.firstWhere((t) => t.name == j['type']);
    } catch (_) {
      // Legacy: 'nucleo' maps to nucleo, anything else to albero
      type = MapElementType.albero;
    }
    List<PathSegment> segs = [];
    if (j['segments'] is List) {
      segs = (j['segments'] as List)
          .map((s) => PathSegment.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (type == MapElementType.vialetto) {
      final w = (j['width'] as num?)?.toDouble() ?? 200.0;
      segs = [PathSegment(angle: 0, length: w)];
    }
    return MapElement(
      id: j['id'] as String,
      type: type,
      position: Offset(
        (j['x'] as num).toDouble(),
        (j['y'] as num).toDouble(),
      ),
      numero: j['numero'] as int?,
      coloreHex: j['colore_hex'] as String?,
      attiva: j['attiva'] as bool?,
      nucleoDbId: j['nucleo_db_id'] as int?,
      segments: segs,
      pathWidth: (j['path_width'] as num?)?.toDouble() ?? 40.0,
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET PRINCIPALE
// ════════════════════════════════════════════════════════════════

class ApiarioMapWidget extends StatefulWidget {
  final List<dynamic> arnie;
  final int apiarioId;
  final Function(int arniaId) onArniaTap;
  final VoidCallback onAddArnia;
  final ValueChanged<bool>? onEditModeChanged;
  final VoidCallback? onNucleoConverted;
  final bool selectionMode;
  final Set<int> selectedArnieIds;

  /// Ultimo controllo per ciascuna arnia: arniaId → raw DAO map.
  final Map<int, Map<String, dynamic>?>? ultimiControlli;

  /// Melari attivi per tutte le arnie dell'apiario (raw storage data).
  final List<dynamic>? melariData;

  const ApiarioMapWidget({
    Key? key,
    required this.arnie,
    required this.apiarioId,
    required this.onArniaTap,
    required this.onAddArnia,
    this.onEditModeChanged,
    this.onNucleoConverted,
    this.selectionMode = false,
    this.selectedArnieIds = const {},
    this.ultimiControlli,
    this.melariData,
  }) : super(key: key);

  @override
  _ApiarioMapWidgetState createState() => _ApiarioMapWidgetState();
}

// ════════════════════════════════════════════════════════════════
//  STATE
// ════════════════════════════════════════════════════════════════

class _ApiarioMapWidgetState extends State<ApiarioMapWidget>
    with SingleTickerProviderStateMixin {
  Map<int, Offset> _arniaPositions = {};
  List<MapElement> _elements = [];
  List<dynamic> _nucleiDb = [];

  bool _editMode = false;
  bool _hasChanges = false;
  bool _snapEnabled = false;
  int? _draggingArniaId;
  String? _draggingElementId;
  String? _selectedPathId;

  OverlayEntry? _dirPickerOverlay;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  final TransformationController _transformCtrl = TransformationController();

  static const double _canvasSize = 10000.0;
  static const double _cellSize = 90.0;
  static const double _gridStep = 120.0;
  static const double _originX = _canvasSize / 2 - 250;
  static const double _originY = _canvasSize / 2 - 250;
  static const double _snapSize = 60.0;

  Size _viewportSize = Size.zero;

  // ── lifecycle ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void didUpdateWidget(ApiarioMapWidget old) {
    super.didUpdateWidget(old);
    if (old.arnie.length != widget.arnie.length ||
        old.apiarioId != widget.apiarioId) {
      _init();
    } else if (old.ultimiControlli != widget.ultimiControlli ||
               old.melariData != widget.melariData) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _hideDirectionPicker();
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([_loadLayout(), _loadNucleiDb()]);
  }

  // ── nuclei dal DB ──────────────────────────────────────────────

  Future<void> _loadNucleiDb() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();

    // Fase 1: cache locale — mostra subito
    final cached = prefs.getString('nuclei_${widget.apiarioId}');
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _nucleiDb = list);
      } catch (_) {}
    }

    // Fase 2: aggiornamento dal server in background
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.getNucleiByApiario(widget.apiarioId);
      await prefs.setString('nuclei_${widget.apiarioId}', jsonEncode(list));
      if (mounted) setState(() => _nucleiDb = list);
    } catch (e) {
      debugPrint('Nuclei fetch failed: $e');
    }
  }

  // ── storage ────────────────────────────────────────────────────

  String get _cacheKey => 'apiary_map_v2_${widget.apiarioId}';

  String _buildLayoutJson() {
    final arnieMap = _arniaPositions
        .map((k, v) => MapEntry(k.toString(), {'x': v.dx, 'y': v.dy}));
    return jsonEncode({
      'arnie': arnieMap,
      'elements': _elements.map((e) => e.toJson()).toList(),
    });
  }

  void _parseLayout(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['arnie'] is Map) {
      _arniaPositions = (data['arnie'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          int.parse(k),
          Offset((v['x'] as num).toDouble(), (v['y'] as num).toDouble()),
        ),
      );
    }
    if (data['elements'] is List) {
      _elements = (data['elements'] as List)
          .map((e) => MapElement.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  void _parseLegacyLayout(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _arniaPositions = map.map((k, v) => MapEntry(
            int.parse(k),
            Offset((v['x'] as num).toDouble(), (v['y'] as num).toDouble()),
          ));
    } catch (_) {}
  }

  Future<void> _loadLayout() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();

    // Fase 1: cache locale — mostra subito
    final v2 = prefs.getString(_cacheKey);
    if (v2 != null) {
      try { _parseLayout(v2); } catch (_) {}
    } else {
      final leg = prefs.getString('arnie_map_${widget.apiarioId}');
      if (leg != null) _parseLegacyLayout(leg);
    }
    _assignMissing();
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnArnie());

    // Fase 2: aggiornamento dal server in background
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final resp = await api.getMapLayout(widget.apiarioId);
      if (resp != null) {
        final lj = resp['layout_json'] as String? ?? '';
        if (lj.isNotEmpty && lj != '{}') {
          await prefs.setString(_cacheKey, lj);
          _parseLayout(lj);
          _assignMissing();
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Map layout fetch: $e');
    }
  }

  void _assignMissing() {
    int col = 0, row = 0;
    for (final a in widget.arnie) {
      final id = a['id'] as int;
      if (!_arniaPositions.containsKey(id)) {
        _arniaPositions[id] = Offset(
          _originX + col * (_cellSize + 50),
          _originY + row * (_cellSize + 50),
        );
        col++;
        if (col >= 5) { col = 0; row++; }
      }
    }
  }

  Future<void> _saveLayout() async {
    final json = _buildLayoutJson();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json);
    if (!mounted) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.saveMapLayout(widget.apiarioId, json);
    } catch (e) {
      debugPrint('Map layout save: $e');
    }
    if (mounted) setState(() => _hasChanges = false);
  }

  // ── geometria ─────────────────────────────────────────────────

  Offset _snap(Offset raw) {
    if (!_snapEnabled) return raw;
    return Offset(
      (raw.dx / _snapSize).round() * _snapSize,
      (raw.dy / _snapSize).round() * _snapSize,
    );
  }

  Offset _viewportCenter() {
    final m = _transformCtrl.value;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    return Offset(
      (_viewportSize.width / 2 - t.x) / s,
      (_viewportSize.height / 2 - t.y) / s,
    );
  }

  Offset _canvasToScreen(Offset canvas) {
    final m = _transformCtrl.value;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    return Offset(canvas.dx * s + t.x, canvas.dy * s + t.y);
  }

  void _centerOnArnie() {
    if (widget.arnie.isEmpty || _arniaPositions.isEmpty) return;
    final vw = _viewportSize.width, vh = _viewportSize.height;
    if (vw == 0 || vh == 0) return;
    final pts = widget.arnie
        .map((a) => a['id'] as int)
        .where(_arniaPositions.containsKey)
        .map((id) => _arniaPositions[id]!)
        .toList();
    if (pts.isEmpty) return;
    final minX = pts.map((p) => p.dx).reduce(min);
    final minY = pts.map((p) => p.dy).reduce(min);
    final maxX = pts.map((p) => p.dx).reduce(max) + _cellSize;
    final maxY = pts.map((p) => p.dy).reduce(max) + _cellSize;
    final scale = min(vw / ((maxX - minX) + 160), vh / ((maxY - minY) + 160))
        .clamp(0.2, 2.5);
    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    _transformCtrl.value = Matrix4.identity()
      ..translate(vw / 2 - scale * cx, vh / 2 - scale * cy)
      ..scale(scale);
  }

  // ── bounding box vialetto ─────────────────────────────────────

  ({Offset origin, Size size, Offset draw}) _pathBounds(MapElement e) {
    final hw = e.pathWidth / 2 + 28.0;
    final pts = <Offset>[Offset.zero];
    var cur = Offset.zero;
    for (final s in e.segments) {
      final r = s.angle * pi / 180;
      cur = Offset(cur.dx + cos(r) * s.length, cur.dy + sin(r) * s.length);
      pts.add(cur);
    }
    final xs = pts.map((p) => p.dx);
    final ys = pts.map((p) => p.dy);
    final minX = xs.reduce(min) - hw;
    final maxX = xs.reduce(max) + hw;
    final minY = ys.reduce(min) - hw;
    final maxY = ys.reduce(max) + hw;
    return (
      origin: Offset(minX, minY),
      size: Size(maxX - minX, maxY - minY),
      draw: Offset(-minX, -minY),
    );
  }

  Offset _pathEndRelative(MapElement e) {
    var cur = Offset.zero;
    for (final s in e.segments) {
      final r = s.angle * pi / 180;
      cur = Offset(cur.dx + cos(r) * s.length, cur.dy + sin(r) * s.length);
    }
    return cur;
  }

  // ── aggiunta / rimozione elementi ─────────────────────────────

  void _addElement(MapElementType type) {
    if (!_editMode) {
      setState(() => _editMode = true);
      widget.onEditModeChanged?.call(true);
    }
    if (type == MapElementType.nucleo ||
        type == MapElementType.apidea ||
        type == MapElementType.mini_plus ||
        type == MapElementType.portasciami) {
      _showAddSmallHiveDialog(type);
      return;
    }
    HapticFeedback.mediumImpact();
    final c = _viewportCenter();
    final id =
        '${type.name}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    MapElement el;
    if (type == MapElementType.vialetto) {
      el = MapElement(
        id: id,
        type: type,
        position: _snap(Offset(c.dx - 50, c.dy - 20)),
        segments: [PathSegment(angle: 0, length: 100)],
        pathWidth: 40,
      );
    } else {
      el = MapElement(
        id: id,
        type: type,
        position: _snap(Offset(c.dx - 35, c.dy - 35)),
      );
    }
    setState(() { _elements.add(el); _hasChanges = true; });
  }

  void _removeElement(String id) {
    HapticFeedback.heavyImpact();
    setState(() {
      _elements.removeWhere((e) => e.id == id);
      if (_selectedPathId == id) _selectedPathId = null;
      _hasChanges = true;
    });
  }

  // ── estensione vialetto ────────────────────────────────────────

  void _extendPath(String elementId, bool isEnd, double newAngle) {
    final el = _elements.firstWhere((e) => e.id == elementId);
    const segLen = 100.0;
    if (isEnd) {
      el.segments.add(PathSegment(angle: newAngle, length: segLen));
    } else {
      final r = newAngle * pi / 180;
      el.position = Offset(
        el.position.dx - cos(r) * segLen,
        el.position.dy - sin(r) * segLen,
      );
      el.segments.insert(0, PathSegment(angle: newAngle, length: segLen));
    }
    setState(() => _hasChanges = true);
  }

  // ── direction picker (compass overlay) ────────────────────────

  void _showDirectionPicker({
    required String elementId,
    required bool isEnd,
    required double referenceAngle,
    required Offset handleCanvasPos,
  }) {
    _hideDirectionPicker();
    final screen = _canvasToScreen(handleCanvasPos);
    _dirPickerOverlay = OverlayEntry(
      builder: (ctx) {
        final sw = MediaQuery.of(ctx).size.width;
        final sh = MediaQuery.of(ctx).size.height;
        const pw = 220.0, ph = 280.0;
        final left = (screen.dx - pw / 2).clamp(8.0, sw - pw - 8);
        final top = (screen.dy - ph - 12).clamp(8.0, sh - ph - 8);
        return Positioned(
          left: left,
          top: top,
          child: _CompassPickerOverlay(
            referenceAngle: referenceAngle,
            onSelect: (absAngle) {
              // La bussola ora passa angoli assoluti in canvas (0=destra,90=giù).
              // Per END il segmento va nella direzione assoluta scelta.
              // Per START il segmento deve andare nella direzione OPPOSTA
              // all'estensione (new_pos = old_pos - direction(newAngle)*len).
              final newAngle = isEnd ? absAngle : absAngle + 180;
              _extendPath(elementId, isEnd, newAngle);
              _hideDirectionPicker();
            },
            onDismiss: _hideDirectionPicker,
          ),
        );
      },
    );
    Overlay.of(context).insert(_dirPickerOverlay!);
  }

  void _hideDirectionPicker() {
    _dirPickerOverlay?.remove();
    _dirPickerOverlay = null;
  }

  // ── cassette piccole: dialog aggiunta ─────────────────────────

  void _showAddSmallHiveDialog(MapElementType type) {
    final labels = {
      MapElementType.nucleo:      'nucleo',
      MapElementType.apidea:      'Apidea/Kieler',
      MapElementType.mini_plus:   'Mini-Plus',
      MapElementType.portasciami: 'portasciami',
    };
    final label = labels[type] ?? 'elemento';

    final numCtrl = TextEditingController();
    String selectedColor = '#FFC107';
    final colors = ['#FFC107', '#8B6914', '#0d6efd', '#198754',
                    '#dc3545', '#fd7e14', '#6f42c1', '#212529',
                    '#FFFFFF', '#F5E6C8'];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Aggiungi $label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Numero $label',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Colore', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: colors.map((hex) {
                  final c = _parseHex(hex);
                  return GestureDetector(
                    onTap: () => setS(() => selectedColor = hex),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == hex
                              ? Colors.white : Colors.grey.shade300,
                          width: selectedColor == hex ? 3 : 1,
                        ),
                        boxShadow: selectedColor == hex
                            ? [BoxShadow(color: c.withOpacity(.5), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final num = int.tryParse(numCtrl.text.trim());
                if (num == null) return;
                Navigator.pop(ctx);
                await _createNucleoDb(num, selectedColor, type);
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNucleoDb(int numero, String coloreHex,
      [MapElementType type = MapElementType.nucleo]) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final c = _viewportCenter();

      // Apidea, Mini-Plus e Portasciami diventano vere Arnie nel DB
      if (type == MapElementType.apidea ||
          type == MapElementType.mini_plus ||
          type == MapElementType.portasciami) {
        final resp = await api.createArnia({
          'apiario': widget.apiarioId,
          'numero': numero,
          'colore_hex': coloreHex,
          'tipo_arnia': type.name,
          'data_installazione': today,
        });
        if (resp == null) return;
        final arniaId = resp['id'] as int;
        HapticFeedback.mediumImpact();
        setState(() {
          _arniaPositions[arniaId] = _snap(Offset(c.dx - 35, c.dy - 35));
          _hasChanges = true;
        });
        await _saveLayout();
        widget.onNucleoConverted?.call();
        return;
      }

      // Nucleo: crea record Nucleo nel DB
      int? nucleoId;
      if (type == MapElementType.nucleo) {
        final resp = await api.createNucleo({
          'apiario': widget.apiarioId,
          'numero': numero,
          'colore_hex': coloreHex,
          'data_installazione': today,
        });
        if (resp == null) return;
        nucleoId = resp['id'] as int;
        _nucleiDb.add(resp);
      }
      final id = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
      HapticFeedback.mediumImpact();
      setState(() {
        _elements.add(MapElement(
          id: id,
          type: type,
          position: _snap(Offset(c.dx - 35, c.dy - 35)),
          numero: numero,
          coloreHex: coloreHex,
          attiva: true,
          nucleoDbId: nucleoId,
        ));
        _hasChanges = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  // ── nucleo: sheet info ─────────────────────────────────────────

  void _showNucleoSheet(MapElement el) {
    final dbData = el.nucleoDbId != null
        ? _nucleiDb.firstWhere(
            (n) => n['id'] == el.nucleoDbId,
            orElse: () => <String, dynamic>{},
          ) as Map<String, dynamic>
        : <String, dynamic>{};
    final num = dbData['numero'] ?? el.numero ?? '?';
    final conv = dbData['convertito'] == true;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Nucleo $num',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            if (dbData['data_installazione'] != null)
              Text('Installato: ${dbData['data_installazione']}',
                  style: const TextStyle(color: Colors.grey)),
            if (dbData['note'] != null && dbData['note'] != '')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(dbData['note'] as String),
              ),
            const SizedBox(height: 20),
            // Pulsante scheda tecnica
            if (el.nucleoDbId != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Apri scheda tecnica'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamed(
                      AppConstants.nucleoDetailRoute,
                      arguments: el.nucleoDbId,
                    ).then((result) {
                      if (result == true) {
                        // Il nucleo è stato convertito: ricarica la mappa
                        _init();
                        widget.onNucleoConverted?.call();
                      }
                    });
                  },
                ),
              ),
            const SizedBox(height: 8),
            if (conv)
              const Chip(
                label: Text('Già convertito in arnia'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              )
            else if (el.nucleoDbId != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Converti in arnia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmConvertNucleo(el);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmConvertNucleo(MapElement el) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Converti in arnia'),
        content: Text(
            'Il nucleo ${el.numero ?? ''} verrà trasformato in un\'arnia completa. Continuare?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Converti'),
          ),
        ],
      ),
    ).then((ok) { if (ok == true) _convertNucleo(el); });
  }

  Future<void> _convertNucleo(MapElement el) async {
    if (el.nucleoDbId == null) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final arnia = await api.convertNucleoToArnia(el.nucleoDbId!);
      if (arnia == null) return;
      final arniaId = arnia['id'] as int;
      _arniaPositions[arniaId] = el.position;
      _removeElement(el.id);
      await _saveLayout();
      await _loadNucleiDb();
      widget.onNucleoConverted?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nucleo convertito in arnia!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore conversione: $e')));
      }
    }
  }

  // ── helpers ────────────────────────────────────────────────────

  Color _parseHex(String hex) {
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return Colors.amber; }
  }

  bool _isActive(dynamic a) => a['attiva'] == true || a['attiva'] == 1;

  Future<void> _toggleEditMode() async {
    if (_editMode && _hasChanges) {
      await _saveLayout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mappa salvata'),
              duration: Duration(seconds: 2)));
      }
    }
    _hideDirectionPicker();
    if (mounted) {
      final nm = !_editMode;
      setState(() { _editMode = nm; _selectedPathId = null; });
      widget.onEditModeChanged?.call(nm);
      HapticFeedback.selectionClick();
    }
  }

  void _applyZoom(double factor) {
    final matrix = _transformCtrl.value;
    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.15, 4.0);
    if ((newScale - currentScale).abs() < 0.001) return;
    final center = _viewportSize == Size.zero
        ? const Offset(200, 150)
        : Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final invMatrix = Matrix4.inverted(matrix);
    final focalCanvas = MatrixUtils.transformPoint(invMatrix, center);
    _transformCtrl.value = Matrix4.copy(matrix)
      ..translate(focalCanvas.dx, focalCanvas.dy)
      ..scale(newScale / currentScale)
      ..translate(-focalCanvas.dx, -focalCanvas.dy);
  }

  void _confirmDelete(String id, String msg) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rimuovi elemento'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    ).then((ok) { if (ok == true) _removeElement(id); });
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.arnie.isEmpty;

    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.biggest != _viewportSize) {
        _viewportSize = constraints.biggest;
      }
      return Stack(children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFEDE8DC))),

        // ── canvas ───────────────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_selectedPathId != null) {
                setState(() => _selectedPathId = null);
                _hideDirectionPicker();
              }
            },
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.15,
              maxScale: 4.0,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              panEnabled: true,
              child: SizedBox(
                width: _canvasSize,
                height: _canvasSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(_canvasSize, _canvasSize),
                        painter: _GridPainter(step: _gridStep),
                      ),
                    ),
                    ..._buildVialettiWidgets(),
                    ..._buildYSortedWidgets(),
                    // Snap grid indicator
                    if (_editMode && _snapEnabled)
                      IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(_canvasSize, _canvasSize),
                            painter: _SnapGridPainter(step: _snapSize),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── empty state ──────────────────────────────────────────
        if (isEmpty)
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hive_outlined, size: 40,
                      color: Colors.brown.withOpacity(.3)),
                ),
                const SizedBox(height: 20),
                Text('Nessuna arnia in questo apiario',
                    style: TextStyle(fontSize: 16,
                        color: Colors.brown.withOpacity(.5),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Premi + per aggiungerne una',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),

        // ── edit mode hint ───────────────────────────────────────
        if (_editMode && !isEmpty)
          Positioned(
            top: 12, left: 12,
            child: _InfoChip(
              icon: Icons.open_with_rounded,
              text: 'Trascina · Tocca vialetto per estenderlo',
            ),
          ),

        // ── selection mode hint ──────────────────────────────────
        if (widget.selectionMode && !isEmpty)
          Positioned(
            top: 12, left: 12,
            child: _InfoChip(icon: Icons.touch_app_rounded, text: 'Tocca per selezionare'),
          ),

        // ── zoom controls (selection mode) ───────────────────────
        if (widget.selectionMode && !isEmpty)
          Positioned(
            top: 8, right: 8,
            child: Column(
              children: [
                _MapZoomButton(
                  icon: Icons.add,
                  onTap: () => _applyZoom(1.4),
                ),
                const SizedBox(height: 4),
                _MapZoomButton(
                  icon: Icons.remove,
                  onTap: () => _applyZoom(1 / 1.4),
                ),
              ],
            ),
          ),

        // ── selection counter ────────────────────────────────────
        if (widget.selectionMode && widget.selectedArnieIds.isNotEmpty)
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(.4),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Text('${widget.selectedArnieIds.length} selezionate',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),

        // ── bottom panel ─────────────────────────────────────────
        if (!widget.selectionMode)
          _buildBottomPanel(),
      ]);
    });
  }

  // ── helper: frame config per il mini-strip sulla mappa ─────────

  static const Map<String, Color> _frameColors = {
    'covata':    Color(0xFFFF8C42),
    'scorte':    Color(0xFFFFD166),
    'diaframma': Color(0xFF9E9E9E),
    'nutritore': Color(0xFF74B3CE),
    'vuoto':     Color(0xFFDDDDDD),
  };

  List<String> _parseFrameConfig(Map<String, dynamic>? controllo) {
    if (controllo == null) return List.filled(10, 'vuoto');
    final raw = controllo['telaini_config'];
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw.toString()) as List;
        if (decoded.length == 10) return List<String>.from(decoded);
      } catch (_) {}
    }
    final scorte = (controllo['telaini_scorte'] as num?)?.toInt() ?? 0;
    final covata = (controllo['telaini_covata'] as num?)?.toInt() ?? 0;
    final config = List.filled(10, 'vuoto');
    int start = ((10 - covata) / 2).floor().clamp(0, 9);
    for (int i = 0; i < covata && start + i < 10; i++) config[start + i] = 'covata';
    int left = scorte;
    for (int i = 0; i < 10 && left > 0; i++) {
      if (config[i] == 'vuoto') { config[i] = 'scorte'; left--; }
    }
    for (int i = 9; i >= 0 && left > 0; i--) {
      if (config[i] == 'vuoto') { config[i] = 'scorte'; left--; }
    }
    return config;
  }

  List<Widget> _buildMelariBoxes(int arniaId) {
    if (widget.melariData == null) return [];
    final active = widget.melariData!
        .where((m) => m['arnia'] == arniaId && m['stato'] == 'posizionato')
        .toList()
      ..sort((a, b) => ((b['posizione'] as num?)?.toInt() ?? 0)
          .compareTo((a['posizione'] as num?)?.toInt() ?? 0));
    // Sort descending: highest position first → renders at top of column (visually highest)
    return active.map((m) {
      final pos = (m['posizione'] as num?)?.toInt() ?? 1;
      return Container(
        width: _cellSize,
        height: 13.0,
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFEFCF78),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFFB8942A), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'M$pos',
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4C10),
              height: 1,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMiniHiveInfo(int arniaId) {
    final controllo = widget.ultimiControlli?[arniaId];
    final frames = _parseFrameConfig(controllo);
    final presenzaRegina = controllo?['presenza_regina'] == true;
    final celleReali    = controllo?['celle_reali']    == true;
    final dataCont      = controllo?['data'] as String?;

    int daysSince = 0;
    if (celleReali && dataCont != null) {
      try { daysSince = DateTime.now().difference(DateTime.parse(dataCont)).inDays; } catch (_) {}
    }

    Color celleColor;
    String celleMark;
    if (daysSince < 5) {
      celleColor = Colors.amber.shade700;  celleMark = '!';
    } else if (daysSince < 10) {
      celleColor = Colors.orange.shade800; celleMark = '!!';
    } else if (daysSince < 14) {
      celleColor = Colors.deepOrange;      celleMark = '!!!';
    } else {
      celleColor = Colors.red.shade800;    celleMark = '!!!';
    }

    return SizedBox(
      width: _cellSize,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 10 mini slot telaini ──────────────────────────────
            Row(
              children: List.generate(10, (i) => Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 0.3),
                  decoration: BoxDecoration(
                    color: _frameColors[frames[i]] ?? const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 2),
            // ── regina + celle reali ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '♛',
                  style: TextStyle(
                    fontSize: 9,
                    color: presenzaRegina
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFFFF6E6E),
                    height: 1,
                  ),
                ),
                if (celleReali) ...[
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: celleColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: celleColor, width: 0.5),
                    ),
                    child: Text(
                      celleMark,
                      style: TextStyle(
                        color: celleColor, fontSize: 8,
                        fontWeight: FontWeight.bold, height: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── arnie ──────────────────────────────────────────────────────

  List<Widget> _buildArnieWidgets() {
    return widget.arnie.map((arnia) {
      final id = arnia['id'] as int;
      final pos = _arniaPositions[id] ?? Offset(_originX, _originY);
      final color = _parseHex(arnia['colore_hex'] ?? '#FFC107');
      final isActive = _isActive(arnia);
      final numero = arnia['numero'] as int;
      final tipo = HiveTipo.parse(arnia['tipo_arnia'] as String?);
      final isDragging = _draggingArniaId == id;
      final isSelected = widget.selectionMode && widget.selectedArnieIds.contains(id);

      Widget child;

      if (_editMode && !widget.selectionMode) {
        child = _DraggableHive(
          numero: numero, color: color, isActive: isActive,
          isDragging: isDragging, cellSize: _cellSize, tipo: tipo,
          onDragStart: () {
            HapticFeedback.selectionClick();
            setState(() => _draggingArniaId = id);
          },
          onDragUpdate: (d) {
            final s = _transformCtrl.value.getMaxScaleOnAxis();
            setState(() {
              final cur = _arniaPositions[id] ?? Offset(_originX, _originY);
              _arniaPositions[id] = _snap(Offset(
                (cur.dx + d.dx / s).clamp(0, _canvasSize),
                (cur.dy + d.dy / s).clamp(0, _canvasSize),
              ));
              _hasChanges = true;
            });
          },
          onDragEnd: () => setState(() => _draggingArniaId = null),
        );
      } else {
        child = _StaticHive(
          numero: numero, color: color, isActive: isActive,
          isSelected: isSelected, cellSize: _cellSize, tipo: tipo,
          onTap: () => widget.onArniaTap(id),
        );
      }

      // ── melari tra il tappo e il corpo, mini info sotto ────────
      final melariBoxes = _buildMelariBoxes(id);
      Widget hiveWithMelari;
      if (melariBoxes.isEmpty) {
        hiveWithMelari = child;
      } else {
        // Overlay i melari subito sotto il tappo in lamiera (~15% dall'alto)
        hiveWithMelari = Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              top: _cellSize * 0.15,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: melariBoxes,
              ),
            ),
          ],
        );
      }
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          hiveWithMelari,
          _buildMiniHiveInfo(id),
        ],
      );

      // Pulse ring when selected
      if (isSelected) {
        child = AnimatedBuilder(
          animation: _pulseAnim,
          builder: (ctx, ch) => Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: -(_cellSize * .12 * _pulseAnim.value),
              top: -(_cellSize * .12 * _pulseAnim.value),
              child: Container(
                width: _cellSize + _cellSize * .24 * _pulseAnim.value,
                height: _cellSize + _cellSize * .24 * _pulseAnim.value,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withOpacity(.6 * _pulseAnim.value),
                    width: 2.5,
                  ),
                  boxShadow: [BoxShadow(
                    color: Colors.green.withOpacity(.35 * _pulseAnim.value),
                    blurRadius: 16 * _pulseAnim.value,
                  )],
                ),
              ),
            ),
            ch!,
          ]),
          child: child,
        );
      }

      return Positioned(key: ValueKey('arnia_$id'), left: pos.dx, top: pos.dy, child: child);
    }).toList();
  }

  // ── decorazioni (alberi e nuclei) ──────────────────────────────

  List<Widget> _buildDecorWidgets() {
    return _elements
        .where((e) => e.type != MapElementType.vialetto)
        .map((el) {
      final pos = el.position;
      final isDragging = _draggingElementId == el.id;

      Widget inner;

      // ── nuclei e cassette piccole ───────────────────────────────
      final isSmallHive = el.type == MapElementType.nucleo ||
          el.type == MapElementType.apidea ||
          el.type == MapElementType.mini_plus ||
          el.type == MapElementType.portasciami;

      if (isSmallHive) {
        final dbData = el.nucleoDbId != null
            ? _nucleiDb.firstWhere(
                (n) => n['id'] == el.nucleoDbId,
                orElse: () => <String, dynamic>{},
              ) as Map<String, dynamic>
            : <String, dynamic>{};
        final num = (dbData['numero'] ?? el.numero ?? 1) as int;
        final hex = (dbData['colore_hex'] ?? el.coloreHex ?? '#8B6914') as String;
        final active = (dbData['attiva'] ?? el.attiva ?? true) as bool;
        final converted = dbData['convertito'] == true;
        if (converted) return const SizedBox.shrink();

        // Mappa tipo elemento → HiveTipo painter
        final HiveTipo smallTipo;
        switch (el.type) {
          case MapElementType.apidea:     smallTipo = HiveTipo.apidea; break;
          case MapElementType.mini_plus:  smallTipo = HiveTipo.mini_plus; break;
          case MapElementType.portasciami: smallTipo = HiveTipo.portasciami; break;
          default:                        smallTipo = HiveTipo.nucleo_legno;
        }
        final smallCell = _cellSize * (el.type == MapElementType.apidea ? 0.60 : 0.78);

        inner = _editMode
            ? _DraggableHive(
                numero: num,
                color: _parseHex(hex),
                isActive: active,
                isDragging: isDragging,
                cellSize: smallCell,
                tipo: smallTipo,
                onDragStart: () {
                  HapticFeedback.selectionClick();
                  setState(() => _draggingElementId = el.id);
                },
                onDragUpdate: (d) {
                  final s = _transformCtrl.value.getMaxScaleOnAxis();
                  setState(() {
                    el.position = _snap(Offset(
                      (el.position.dx + d.dx / s).clamp(0, _canvasSize),
                      (el.position.dy + d.dy / s).clamp(0, _canvasSize),
                    ));
                    _hasChanges = true;
                  });
                },
                onDragEnd: () => setState(() => _draggingElementId = null),
                onLongPress: () => _confirmDelete(
                    el.id, 'Rimuovere questo elemento dalla mappa?'),
              )
            : GestureDetector(
                onTap: () => _showNucleoSheet(el),
                child: _StaticHive(
                  numero: num,
                  color: _parseHex(hex),
                  isActive: active,
                  isSelected: false,
                  cellSize: smallCell,
                  tipo: smallTipo,
                  onTap: () => _showNucleoSheet(el),
                ),
              );
      } else {
        // albero
        inner = _editMode
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _draggingElementId = el.id);
                },
                onPanUpdate: (d) {
                  final s = _transformCtrl.value.getMaxScaleOnAxis();
                  setState(() {
                    el.position = _snap(Offset(
                      (el.position.dx + d.delta.dx / s).clamp(0, _canvasSize),
                      (el.position.dy + d.delta.dy / s).clamp(0, _canvasSize),
                    ));
                    _hasChanges = true;
                  });
                },
                onPanEnd: (_) => setState(() => _draggingElementId = null),
                onLongPress: () => _confirmDelete(el.id, 'Rimuovere questo albero?'),
                child: _AlberoWidget(isDragging: isDragging),
              )
            : _AlberoWidget(isDragging: false);

        // Albero semi-trasparente se un'arnia con Y maggiore (in primo piano) si sovrappone.
        // La pos dell'arnia è il top-left della Column (melari + hive + info).
        // L'arnia vera occupa _cellSize px in altezza a partire da pos.dy;
        // usiamo un rect generoso (1.4× _cellSize) per coprire anche il corpo completo.
        const treeW = 72.0, treeH = 82.0;
        final treeRect = Rect.fromLTWH(pos.dx, pos.dy, treeW, treeH);
        final isOverlapped = _arniaPositions.entries.any((e) {
          if (e.value.dy <= el.position.dy) return false;
          return treeRect.overlaps(
            Rect.fromLTWH(e.value.dx, e.value.dy, _cellSize, _cellSize * 1.4),
          );
        });
        if (isOverlapped) {
          inner = AnimatedOpacity(
            opacity: 0.42,
            duration: const Duration(milliseconds: 200),
            child: inner,
          );
        }
      }

      return Positioned(key: ValueKey('el_${el.id}'), left: pos.dx, top: pos.dy, child: inner);
    }).toList();
  }

  // ── Y-sorting: alberi + arnie ordinati per profondità ──────────

  /// Unisce decor e arnie in un'unica lista ordinata per Y (y-sorting rigoroso).
  /// Gli elementi con Y minore (più in alto sullo schermo) vengono renderizzati
  /// prima, dando una prospettiva naturale.
  List<Widget> _buildYSortedWidgets() {
    final all = [..._buildDecorWidgets(), ..._buildArnieWidgets()];
    all.sort((a, b) {
      final ay = (a is Positioned ? a.top : null) ?? 0.0;
      final by = (b is Positioned ? b.top : null) ?? 0.0;
      return ay.compareTo(by);
    });
    return all;
  }

  // ── vialetti modulari ──────────────────────────────────────────

  List<Widget> _buildVialettiWidgets() {
    return _elements
        .where((e) => e.type == MapElementType.vialetto)
        .map((el) => _buildSingleVialetto(el))
        .toList();
  }

  Widget _buildSingleVialetto(MapElement el) {
    if (el.segments.isEmpty) return const SizedBox.shrink();
    final bounds = _pathBounds(el);
    final endRel = _pathEndRelative(el);
    final isSelected = _selectedPathId == el.id;
    final isDragging = _draggingElementId == el.id;

    final startInBox = bounds.draw;
    final endInBox = bounds.draw + endRel;

    return Positioned(
      left: el.position.dx + bounds.origin.dx,
      top: el.position.dy + bounds.origin.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── corpo vialetto ──────────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _editMode
                ? () {
                    _hideDirectionPicker();
                    setState(() => _selectedPathId = isSelected ? null : el.id);
                  }
                : null,
            onPanStart: _editMode
                ? (_) => setState(() => _draggingElementId = el.id)
                : null,
            onPanUpdate: _editMode
                ? (d) {
                    final s = _transformCtrl.value.getMaxScaleOnAxis();
                    setState(() {
                      el.position = Offset(
                        el.position.dx + d.delta.dx / s,
                        el.position.dy + d.delta.dy / s,
                      );
                      _hasChanges = true;
                    });
                  }
                : null,
            onPanEnd: _editMode
                ? (_) => setState(() => _draggingElementId = null)
                : null,
            onLongPress: _editMode
                ? () => _confirmDelete(el.id, 'Rimuovere questo vialetto?')
                : null,
            child: SizedBox(
              width: bounds.size.width,
              height: bounds.size.height,
              child: CustomPaint(
                painter: _PathPainter(
                  segments: el.segments,
                  drawOffset: bounds.draw,
                  pathWidth: el.pathWidth,
                  isSelected: isSelected,
                  isDragging: isDragging,
                ),
              ),
            ),
          ),

          // ── handle START ─────────────────────────────────────
          if (isSelected && _editMode)
            Positioned(
              left: startInBox.dx - 20,
              top: startInBox.dy - 20,
              child: _PathHandle(
                icon: Icons.add_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  final refAngle = el.segments.first.angle + 180;
                  _showDirectionPicker(
                    elementId: el.id,
                    isEnd: false,
                    referenceAngle: refAngle,
                    handleCanvasPos: el.position,
                  );
                },
              ),
            ),

          // ── handle END ───────────────────────────────────────
          if (isSelected && _editMode)
            Positioned(
              left: endInBox.dx - 20,
              top: endInBox.dy - 20,
              child: _PathHandle(
                icon: Icons.add_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  final refAngle = el.segments.last.angle;
                  final canvasEndPos = el.position + endRel;
                  _showDirectionPicker(
                    elementId: el.id,
                    isEnd: true,
                    referenceAngle: refAngle,
                    handleCanvasPos: canvasEndPos,
                  );
                },
              ),
            ),

          // ── hint tieni premuto ───────────────────────────────
          if (isSelected && _editMode)
            Positioned(
              left: (startInBox.dx + endInBox.dx) / 2 - 56,
              top: (startInBox.dy + endInBox.dy) / 2 - 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332).withOpacity(.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Tieni premuto per eliminare',
                    style: TextStyle(color: Colors.white70, fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  // ── bottom panel ───────────────────────────────────────────────

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 16, right: 16,
      child: SafeArea(
        top: false, left: false, right: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add elements panel (only in edit mode)
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: _editMode
                ? Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2436),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.35),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _AddBtn(
                            icon: Icons.hive_rounded,
                            label: 'Arnia',
                            color: const Color(0xFFF59E0B),
                            onTap: widget.onAddArnia,
                          ),
                          const SizedBox(width: 4),
                          _AddBtn(
                            icon: Icons.hive_outlined,
                            label: 'Nucleo',
                            color: const Color(0xFF8B6914),
                            onTap: () => _addElement(MapElementType.nucleo),
                          ),
                          const SizedBox(width: 4),
                          _AddBtn(
                            icon: Icons.square_outlined,
                            label: 'Apidea',
                            color: const Color(0xFF5B8DEF),
                            onTap: () => _addElement(MapElementType.apidea),
                          ),
                          const SizedBox(width: 4),
                          _AddBtn(
                            icon: Icons.layers_outlined,
                            label: 'Mini-Plus',
                            color: const Color(0xFF9B59B6),
                            onTap: () => _addElement(MapElementType.mini_plus),
                          ),
                          const SizedBox(width: 4),
                          _AddBtn(
                            icon: Icons.inventory_2_outlined,
                            label: 'Portasc.',
                            color: const Color(0xFFA0856C),
                            onTap: () => _addElement(MapElementType.portasciami),
                          ),
                          const SizedBox(width: 4),
                          _AddBtn(
                            icon: Icons.park_rounded,
                            label: 'Albero',
                            color: const Color(0xFF2E7D32),
                            onTap: () => _addElement(MapElementType.albero),
                          ),
                          const SizedBox(width: 4),
                          _AddBtn(
                            icon: Icons.remove_road_rounded,
                            label: 'Vialetto',
                            color: const Color(0xFF8D6E63),
                            onTap: () => _addElement(MapElementType.vialetto),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Control row
          Row(
            children: [
              // Center
              _MapIconButton(
                icon: Icons.filter_center_focus_rounded,
                onTap: _centerOnArnie,
                tooltip: 'Centra',
              ),
              if (_editMode) ...[
                const SizedBox(width: 8),
                // Snap toggle
                _MapIconButton(
                  icon: _snapEnabled ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _snapEnabled = !_snapEnabled);
                  },
                  tooltip: _snapEnabled ? 'Snap ON' : 'Snap OFF',
                  active: _snapEnabled,
                ),
              ],
              const Spacer(),
              // Edit / save toggle
              _EditToggleBtn(
                editMode: _editMode,
                hasChanges: _hasChanges,
                onTap: _toggleEditMode,
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — ARNIA STATICA
// ════════════════════════════════════════════════════════════════

class _StaticHive extends StatelessWidget {
  final int numero;
  final Color color;
  final bool isActive, isSelected;
  final HiveTipo tipo;
  final double cellSize;
  final VoidCallback onTap;

  const _StaticHive({
    required this.numero, required this.color, required this.isActive,
    required this.isSelected, required this.cellSize, required this.onTap,
    this.tipo = HiveTipo.dadant,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(clipBehavior: Clip.none, children: [
      _HiveCell(numero: numero, color: color, isActive: isActive,
          isSelected: isSelected, cellSize: cellSize,
          isDragging: false, showDragIcon: false, tipo: tipo),
      if (isSelected)
        Positioned(
          top: -7, right: -7,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: Colors.green, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 4)],
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — ARNIA TRASCINABILE
// ════════════════════════════════════════════════════════════════

class _DraggableHive extends StatelessWidget {
  final int numero;
  final Color color;
  final bool isActive, isDragging;
  final HiveTipo tipo;
  final double cellSize;
  final VoidCallback onDragStart;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback? onLongPress;

  const _DraggableHive({
    required this.numero, required this.color, required this.isActive,
    required this.isDragging, required this.cellSize,
    required this.onDragStart, required this.onDragUpdate, required this.onDragEnd,
    this.tipo = HiveTipo.dadant, this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onPanStart: (_) => onDragStart(),
    onPanUpdate: (d) => onDragUpdate(d.delta),
    onPanEnd: (_) => onDragEnd(),
    onLongPress: onLongPress,
    child: _HiveCell(numero: numero, color: color, isActive: isActive,
        cellSize: cellSize, isDragging: isDragging,
        showDragIcon: true, tipo: tipo),
  );
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — CELLA ARNIA
// ════════════════════════════════════════════════════════════════

class _HiveCell extends StatelessWidget {
  final int numero;
  final Color color;
  final bool isActive, isSelected, isDragging, showDragIcon;
  final HiveTipo tipo;
  final double cellSize;

  const _HiveCell({
    required this.numero, required this.color, required this.isActive,
    required this.cellSize, required this.isDragging, required this.showDragIcon,
    this.isSelected = false, this.tipo = HiveTipo.dadant,
  });

  @override
  Widget build(BuildContext context) {
    final disp = isActive ? color : Colors.grey.shade400;
    final lum = disp.computeLuminance();
    final tc = lum > 0.4 ? Colors.black87 : Colors.white;
    final isSmall = !tipo.isFullHive;
    final prefix = switch (tipo) {
      HiveTipo.apidea             => 'A',
      HiveTipo.mini_plus          => 'M',
      HiveTipo.portasciami        => 'P',
      HiveTipo.nucleo_polistirolo => 'N',
      _ when isSmall              => 'N',
      _                           => '',
    };
    final label = '$prefix$numero';

    return AnimatedContainer(
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 150),
      width: cellSize, height: cellSize,
      transform: isDragging
          ? (Matrix4.identity()..scale(1.08))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmall ? 6 : 5),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.green.withOpacity(.55)
                : disp.withOpacity(isDragging ? .50 : .35),
            blurRadius: isSelected ? 16 : (isDragging ? 22 : 8),
            spreadRadius: isDragging ? 2 : 0,
            offset: Offset(0, isDragging ? 10 : 3),
          ),
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HivePainter(
              color: disp, tipo: tipo,
              isSelected: isSelected, isDragging: isDragging,
            ),
          ),
        ),
        // Number label
        Positioned(
          top: cellSize * (isSmall ? .36 : .38), left: 0, right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: cellSize * .06, vertical: cellSize * .02),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label,
                style: TextStyle(
                  color: tc, fontWeight: FontWeight.w900, height: 1,
                  fontSize: isSmall ? cellSize * .26 : cellSize * .28,
                  shadows: [Shadow(color: Colors.black.withOpacity(.25), blurRadius: 3)],
                )),
            ),
          ),
        ),
        if (!isActive)
          Positioned(
            bottom: cellSize * .12, left: 0, right: 0,
            child: Center(
              child: Text(isSmall ? 'inattivo' : 'inattiva',
                style: TextStyle(color: tc.withOpacity(.7),
                    fontSize: cellSize * .10, fontWeight: FontWeight.w600)),
            ),
          ),
        if (showDragIcon)
          Positioned(
            bottom: cellSize * .04, left: 0, right: 0,
            child: Icon(Icons.drag_indicator_rounded,
                size: cellSize * .16,
                color: tc.withOpacity(.40)),
          ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  PAINTER — FORMA ARNIA (con honeycomb)
// ════════════════════════════════════════════════════════════════

class _HivePainter extends CustomPainter {
  final Color color;
  final HiveTipo tipo;
  final bool isSelected, isDragging;

  const _HivePainter({
    required this.color,
    this.tipo = HiveTipo.dadant, this.isSelected = false, this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final hsl = HSLColor.fromColor(color);
    final darker = hsl
        .withLightness((hsl.lightness - .22).clamp(0, 1))
        .withSaturation((hsl.saturation + .08).clamp(0, 1))
        .toColor();
    final darkest = hsl.withLightness((hsl.lightness - .38).clamp(0, 1)).toColor();
    final lighter = hsl.withLightness((hsl.lightness + .15).clamp(0, 1)).toColor();

    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final stroke = Paint()..color = darker..style = PaintingStyle.stroke
        ..strokeWidth = 1.4..strokeJoin = StrokeJoin.round;
    final darkFill = Paint()..color = darker..style = PaintingStyle.fill;

    switch (tipo) {
      case HiveTipo.dadant:
        _drawArnia(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.langstroth:
        _drawLangstroth(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.top_bar:
        _drawTopBar(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.warre:
        _drawWarre(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.osservazione:
        _drawOsservazione(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.pappa_reale:
        _drawPappaReale(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.nucleo_legno:
      case HiveTipo.nucleo_polistirolo:
        _drawNucleo(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter,
            polistirolo: tipo == HiveTipo.nucleo_polistirolo);
      case HiveTipo.portasciami:
        _drawPortasciami(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.apidea:
        _drawApidea(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
      case HiveTipo.mini_plus:
        _drawMiniPlus(canvas, w, h, fill, stroke, darkFill, darker, darkest, lighter);
    }

    // Selection / drag ring
    if (isSelected || isDragging) {
      canvas.drawRRect(
        RRect.fromLTRBR(.02 * w, .02 * h, .98 * w, .98 * h, const Radius.circular(5)),
        Paint()..color = isSelected ? Colors.green : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 3.0 : 2.5,
      );
    }
  }

  void _drawArnia(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // ── Tetto piatto in acciaio ───────────────────────────────────
    // Colore acciaio: grigio-azzurro metallico mischiato con il tono scuro dell'arnia
    final roofBase = HSLColor.fromColor(darker)
        .withSaturation(0.06)
        .withLightness(0.48)
        .toColor();
    final roofColor = Color.lerp(roofBase, const Color(0xFFB8C4CC), 0.55)!;
    final roofHighlight = Color.lerp(roofColor, Colors.white, 0.38)!;
    final roofShadow = Color.lerp(roofColor, Colors.black, 0.28)!;

    // Tetto leggermente più largo del corpo (2% overhang per lato)
    final roofRRect = RRect.fromLTRBR(
        -w * .02, h * .02, w * 1.02, h * .16, const Radius.circular(2));
    c.drawRRect(roofRRect, Paint()..color = roofColor..style = PaintingStyle.fill);

    // Riflesso metallico (banda chiara nella metà superiore)
    c.save();
    c.clipRRect(roofRRect);
    c.drawRect(
      Rect.fromLTWH(0, h * .02, w, h * .07),
      Paint()..color = roofHighlight.withValues(alpha: 0.28),
    );
    // Linea di shininess
    c.drawLine(
      Offset(w * .05, h * .065),
      Offset(w * .95, h * .065),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    c.restore();

    // Bordo tetto
    c.drawRRect(roofRRect,
        Paint()..color = roofShadow..style = PaintingStyle.stroke..strokeWidth = 0.9);

    // ── Corpo superiore ───────────────────────────────────────────
    final upper = RRect.fromLTRBR(w * .07, h * .15, w * .93, h * .50, const Radius.circular(2));
    c.drawRRect(upper, fill);
    c.drawRRect(upper, stroke);

    // ── Corpo inferiore ───────────────────────────────────────────
    final lower = RRect.fromLTRBR(w * .07, h * .50, w * .93, h * .80, const Radius.circular(2));
    c.drawRRect(lower, fill);
    c.drawRRect(lower, stroke);

    // ── Honeycomb texture ─────────────────────────────────────────
    _drawHoneycomb(c, Rect.fromLTRB(w * .08, h * .16, w * .92, h * .80), w * .085, darker);

    // ── Predellino d'atterraggio ──────────────────────────────────
    final boardRect = Rect.fromLTWH(w * .04, h * .80, w * .92, h * .05);
    c.drawRect(boardRect, Paint()..color = darkest..style = PaintingStyle.fill);

    // ── Porticina rettangolare larga e bassa ──────────────────────
    // 80% della larghezza, altezza bassa (6% dell'altezza)
    final portW = w * 0.80;
    final portH = h * 0.062;
    final portX = (w - portW) / 2;
    final portY = h * .80;

    // Fondo scuro (profondità)
    c.drawRect(
      Rect.fromLTWH(portX, portY, portW, portH),
      Paint()..color = const Color(0xEE000000)..style = PaintingStyle.fill,
    );
    // Sottile bordo superiore chiaro (luce in cima alla porticina)
    c.drawLine(
      Offset(portX + portW * .04, portY + portH * .18),
      Offset(portX + portW * .96, portY + portH * .18),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.09)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawNucleo(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter,
      {bool polistirolo = false}) {
    if (polistirolo) {
      // Polistirolo: forme arrotondate, colore chiaro quasi bianco
      final bodyColor = Color.lerp(fill.color, Colors.white, 0.55)!;
      final pFill = Paint()..color = bodyColor..style = PaintingStyle.fill;
      final pStroke = Paint()..color = darker.withOpacity(.5)..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
      final roof = RRect.fromLTRBR(w*.04, h*.08, w*.96, h*.24, const Radius.circular(6));
      c.drawRRect(roof, pFill); c.drawRRect(roof, pStroke);
      final body = RRect.fromLTRBR(w*.06, h*.23, w*.94, h*.82, const Radius.circular(8));
      c.drawRRect(body, pFill); c.drawRRect(body, pStroke);
      final board = RRect.fromLTRBR(w*.04, h*.82, w*.96, h*.88, const Radius.circular(4));
      c.drawRRect(board, Paint()..color = darker.withOpacity(.3)..style = PaintingStyle.fill);
      final entW = w*.22, entH = h*.048;
      c.drawRRect(RRect.fromLTRBR((w-entW)/2, h*.82, (w+entW)/2, h*.82+entH,
          const Radius.circular(2)),
          Paint()..color = const Color(0xBB000000)..style = PaintingStyle.fill);
    } else {
      // Legno: forma classica
      final roof = RRect.fromLTRBR(w*.04, h*.10, w*.96, h*.24, const Radius.circular(3));
      c.drawRRect(roof, dFill);
      final body = RRect.fromLTRBR(w*.08, h*.23, w*.92, h*.80, const Radius.circular(2));
      c.drawRRect(body, fill); c.drawRRect(body, stroke);
      _drawHoneycomb(c, Rect.fromLTRB(w*.09, h*.24, w*.91, h*.80), w * .075, darker);
      c.drawLine(Offset(w*.08, h*.515), Offset(w*.92, h*.515),
          Paint()..color = darker.withOpacity(.4)..strokeWidth = .9);
      c.drawRect(Rect.fromLTWH(w*.04, h*.80, w*.92, h*.055),
          Paint()..color = darkest..style = PaintingStyle.fill);
      final entW = w*.24, entH = h*.055;
      c.drawRRect(RRect.fromLTRBR((w-entW)/2, h*.80, (w+entW)/2, h*.80+entH,
          const Radius.circular(1.5)),
          Paint()..color = const Color(0xBB000000)..style = PaintingStyle.fill);
    }
  }

  // ── Langstroth: casse modulari tutte uguali ────────────────────
  void _drawLangstroth(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Tetto piatto metallico (stesso del Dadant)
    final roofColor = Color.lerp(darker.withOpacity(1), const Color(0xFFB8C4CC), 0.55)!;
    final roofRRect = RRect.fromLTRBR(-w*.02, h*.02, w*1.02, h*.14, const Radius.circular(2));
    c.drawRRect(roofRRect, Paint()..color = roofColor..style = PaintingStyle.fill);
    c.drawRRect(roofRRect, Paint()..color = roofColor.withOpacity(.5)..style = PaintingStyle.stroke..strokeWidth = .9);

    // 3 casse modulari identiche (Langstroth è modulare)
    const boxes = 3;
    final boxH = (h * .70) / boxes;
    for (int i = 0; i < boxes; i++) {
      final top = h * .14 + i * boxH;
      final box = RRect.fromLTRBR(w*.06, top, w*.94, top + boxH - 1, const Radius.circular(2));
      c.drawRRect(box, fill);
      c.drawRRect(box, stroke);
      _drawHoneycomb(c, Rect.fromLTRB(w*.07, top + 1, w*.93, top + boxH - 2), w * .080, darker);
    }
    // Predellino e porta
    final boardTop = h * .14 + boxes * boxH;
    c.drawRect(Rect.fromLTWH(w*.04, boardTop, w*.92, h*.04),
        Paint()..color = darkest..style = PaintingStyle.fill);
    final portW = w * .78, portH = h * .055;
    c.drawRect(Rect.fromLTWH((w - portW) / 2, boardTop, portW, portH),
        Paint()..color = const Color(0xEE000000)..style = PaintingStyle.fill);
  }

  // ── Top Bar (Kenyana): forma trapezoidale orizzontale ──────────
  void _drawTopBar(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Corpo trapezoidale (più largo in alto, più stretto in basso)
    final path = Path()
      ..moveTo(w * .00, h * .18)   // sinistra alto
      ..lineTo(w * 1.00, h * .18)  // destra alto
      ..lineTo(w * .88, h * .82)   // destra basso
      ..lineTo(w * .12, h * .82)   // sinistra basso
      ..close();
    c.drawPath(path, fill);
    c.drawPath(path, stroke);

    // Barre superiori (top bars) — 5 linee verticali
    final barPaint = Paint()..color = darker.withOpacity(.55)..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 5; i++) {
      final x = w * .08 + (w * .84) * i / 6;
      c.drawLine(Offset(x, h * .19), Offset(x, h * .80), barPaint);
    }

    // Tetto a capanna triangolare
    final roofPath = Path()
      ..moveTo(w * .50, h * .02)   // vertice tetto
      ..lineTo(w * 1.04, h * .18)  // destra base tetto
      ..lineTo(w * -.04, h * .18)  // sinistra base tetto
      ..close();
    final roofColor = Color.lerp(darker, const Color(0xFFB8C4CC), 0.45)!;
    c.drawPath(roofPath, Paint()..color = roofColor..style = PaintingStyle.fill);
    c.drawPath(roofPath, Paint()..color = roofColor.withOpacity(.7)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Entrata frontale (sul lato stretto basso)
    final entW = w * .20;
    c.drawRect(Rect.fromLTWH((w - entW) / 2, h * .78, entW, h * .04),
        Paint()..color = const Color(0xCC000000)..style = PaintingStyle.fill);
  }

  // ── Warré: alta e stretta, casse aggiunte dal basso ───────────
  void _drawWarre(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Tetto a capanna
    final roofPath = Path()
      ..moveTo(w * .50, h * .00)
      ..lineTo(w * 1.02, h * .16)
      ..lineTo(w * -.02, h * .16)
      ..close();
    final roofColor = Color.lerp(darker.withOpacity(1), const Color(0xFF9E8060), 0.4)!;
    c.drawPath(roofPath, Paint()..color = roofColor..style = PaintingStyle.fill);
    c.drawPath(roofPath, Paint()..color = roofColor.withOpacity(.7)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 4 casse piccole identiche (Warré è più alta e stretta)
    const boxes = 4;
    final boxH = (h * .68) / boxes;
    for (int i = 0; i < boxes; i++) {
      final top = h * .16 + i * boxH;
      final box = RRect.fromLTRBR(w*.10, top, w*.90, top + boxH - 1, const Radius.circular(1));
      c.drawRRect(box, fill);
      c.drawRRect(box, stroke);
      if (i < boxes - 1) {
        _drawHoneycomb(c, Rect.fromLTRB(w*.11, top + 1, w*.89, top + boxH - 2), w * .065, darker);
      }
    }
    // Piedini (Warré ha spesso dei piedini)
    final legW = w * .12, legH = h * .06;
    c.drawRect(Rect.fromLTWH(w * .14, h * .84, legW, legH),
        Paint()..color = darkest..style = PaintingStyle.fill);
    c.drawRect(Rect.fromLTWH(w * .74, h * .84, legW, legH),
        Paint()..color = darkest..style = PaintingStyle.fill);
    // Entrata
    final entW = w * .32;
    c.drawRect(Rect.fromLTWH((w - entW) / 2, h * .82, entW, h * .028),
        Paint()..color = const Color(0xCC000000)..style = PaintingStyle.fill);
  }

  // ── Osservazione: corpo con pannelli di vetro ─────────────────
  void _drawOsservazione(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Tetto piatto metallico
    final roofColor = Color.lerp(darker.withOpacity(1), const Color(0xFFB8C4CC), 0.55)!;
    final roofRRect = RRect.fromLTRBR(-w*.02, h*.02, w*1.02, h*.14, const Radius.circular(2));
    c.drawRRect(roofRRect, Paint()..color = roofColor..style = PaintingStyle.fill);

    // Telaio corpo
    final frame = RRect.fromLTRBR(w*.06, h*.14, w*.94, h*.82, const Radius.circular(2));
    c.drawRRect(frame, dFill);
    c.drawRRect(frame, stroke);

    // Pannello di vetro (zona centrale più chiara e trasparente)
    final glassPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(.18)
      ..style = PaintingStyle.fill;
    final glassBorder = Paint()
      ..color = Colors.lightBlue.shade200.withOpacity(.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final glass = RRect.fromLTRBR(w*.16, h*.18, w*.84, h*.78, const Radius.circular(1));
    c.drawRRect(glass, glassPaint);
    c.drawRRect(glass, glassBorder);

    // Ape stilizzata nel vetro (cerchio + ali)
    final cx = w * .50, cy = h * .48;
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w*.12, height: h*.08),
        Paint()..color = darker.withOpacity(.35)..style = PaintingStyle.fill);

    // Predellino e porta
    c.drawRect(Rect.fromLTWH(w*.04, h*.82, w*.92, h*.04),
        Paint()..color = darkest..style = PaintingStyle.fill);
    c.drawRect(Rect.fromLTWH(w*.10, h*.82, w*.80, h*.05),
        Paint()..color = const Color(0xEE000000)..style = PaintingStyle.fill);
  }

  // ── Pappa Reale: arnia orizzontale con divisore ───────────────
  void _drawPappaReale(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Corpo molto largo e basso
    final roofColor = Color.lerp(darker.withOpacity(1), const Color(0xFFB8C4CC), 0.55)!;
    c.drawRRect(RRect.fromLTRBR(-w*.01, h*.06, w*1.01, h*.18, const Radius.circular(2)),
        Paint()..color = roofColor..style = PaintingStyle.fill);

    final body = RRect.fromLTRBR(w*.04, h*.18, w*.96, h*.80, const Radius.circular(2));
    c.drawRRect(body, fill); c.drawRRect(body, stroke);

    // Linea divisoria verticale con tratteggio (griglia escludiregina)
    final divX = w * .52;
    final divPaint = Paint()
      ..color = darker.withOpacity(.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // Tratteggio manuale
    double y = h * .19;
    while (y < h * .79) {
      c.drawLine(Offset(divX, y), Offset(divX, y + h * .03), divPaint);
      y += h * .05;
    }

    // Honeycomb su entrambi i lati
    _drawHoneycomb(c, Rect.fromLTRB(w*.05, h*.19, divX - 2, h*.79), w * .07, darker);
    _drawHoneycomb(c, Rect.fromLTRB(divX + 2, h*.19, w*.95, h*.79), w * .07, darker);

    // Etichetta "R" sul lato regina
    c.drawCircle(Offset(w * .28, h * .50),
        w * .08, Paint()..color = const Color(0xFFFFD700).withOpacity(.25)..style = PaintingStyle.fill);

    // Predellino e porta
    c.drawRect(Rect.fromLTWH(w*.04, h*.80, w*.92, h*.04),
        Paint()..color = darkest..style = PaintingStyle.fill);
    c.drawRect(Rect.fromLTWH(w*.08, h*.80, w*.40, h*.05),
        Paint()..color = const Color(0xEE000000)..style = PaintingStyle.fill);
  }

  // ── Portasciami: cassetta semplice cartone ─────────────────────
  void _drawPortasciami(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Corpo rettangolare semplice con angoli vivi (cartone)
    final cardColor = Color.lerp(fill.color, const Color(0xFFD2B48C), 0.65)!;
    final cFill = Paint()..color = cardColor..style = PaintingStyle.fill;
    final cStroke = Paint()..color = darker.withOpacity(.6)..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

    // Corpo
    c.drawRect(Rect.fromLTWH(w*.06, h*.12, w*.88, h*.70), cFill);
    c.drawRect(Rect.fromLTWH(w*.06, h*.12, w*.88, h*.70), cStroke);

    // Coperchio a sormonto
    c.drawRect(Rect.fromLTWH(w*.02, h*.06, w*.96, h*.10), cFill);
    c.drawRect(Rect.fromLTWH(w*.02, h*.06, w*.96, h*.10), cStroke);

    // Linee cartone (texture)
    final linePaint = Paint()..color = darker.withOpacity(.18)..strokeWidth = .7;
    for (int i = 1; i < 4; i++) {
      c.drawLine(Offset(w*.06, h*.12 + i * h*.175),
                 Offset(w*.94, h*.12 + i * h*.175), linePaint);
    }

    // Foro d'ingresso a cerchio (classico per portasciami)
    c.drawCircle(Offset(w*.50, h*.82),
        w * .07, Paint()..color = const Color(0xCC000000)..style = PaintingStyle.fill);
    c.drawCircle(Offset(w*.50, h*.82),
        w * .07, Paint()..color = darker.withOpacity(.4)..style = PaintingStyle.stroke..strokeWidth = .8);
  }

  // ── Apidea / Kieler: micro-cassetta squadrata ──────────────────
  void _drawApidea(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Colore chiaro (polistirolo o plastica)
    final apoColor = Color.lerp(fill.color, Colors.white, 0.60)!;
    final aFill = Paint()..color = apoColor..style = PaintingStyle.fill;
    final aStroke = Paint()..color = darker.withOpacity(.45)..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;

    // Corpo quasi quadrato con angoli arrotondati
    final body = RRect.fromLTRBR(w*.06, h*.20, w*.94, h*.82, const Radius.circular(5));
    c.drawRRect(body, aFill); c.drawRRect(body, aStroke);

    // Coperchio
    final lid = RRect.fromLTRBR(w*.04, h*.10, w*.96, h*.22, const Radius.circular(4));
    final lidColor = Color.lerp(apoColor, Colors.grey.shade300, 0.3)!;
    c.drawRRect(lid, Paint()..color = lidColor..style = PaintingStyle.fill);
    c.drawRRect(lid, aStroke);

    // Finestrella vano candito (piccolo rettangolo in alto)
    c.drawRRect(RRect.fromLTRBR(w*.25, h*.24, w*.75, h*.40, const Radius.circular(2)),
        Paint()..color = const Color(0xFFF5E6C8).withOpacity(.6)..style = PaintingStyle.fill);
    c.drawRRect(RRect.fromLTRBR(w*.25, h*.24, w*.75, h*.40, const Radius.circular(2)),
        aStroke);

    // Piccola entrata
    final entW = w * .16;
    c.drawRect(Rect.fromLTWH((w - entW) / 2, h * .79, entW, h * .035),
        Paint()..color = const Color(0xCC000000)..style = PaintingStyle.fill);
  }

  // ── Mini-Plus: modulare piccolo ────────────────────────────────
  void _drawMiniPlus(Canvas c, double w, double h,
      Paint fill, Paint stroke, Paint dFill,
      Color darker, Color darkest, Color lighter) {
    // Colore polistirolo/legno chiaro
    final mpColor = Color.lerp(fill.color, Colors.white, 0.42)!;
    final mpFill = Paint()..color = mpColor..style = PaintingStyle.fill;
    final mpStroke = Paint()..color = darker.withOpacity(.5)..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

    // Coperchio
    final lid = RRect.fromLTRBR(w*.04, h*.08, w*.96, h*.20, const Radius.circular(3));
    c.drawRRect(lid, Paint()..color = Color.lerp(mpColor, Colors.grey.shade400, .25)!
        ..style = PaintingStyle.fill);
    c.drawRRect(lid, mpStroke);

    // 2 cassette modulari
    const boxes = 2;
    final boxH = (h * .62) / boxes;
    for (int i = 0; i < boxes; i++) {
      final top = h * .20 + i * boxH;
      final box = RRect.fromLTRBR(w*.06, top, w*.94, top + boxH - 1, const Radius.circular(3));
      c.drawRRect(box, mpFill);
      c.drawRRect(box, mpStroke);
    }

    // Fondo
    c.drawRRect(RRect.fromLTRBR(w*.04, h*.82, w*.96, h*.90, const Radius.circular(3)),
        Paint()..color = darkest.withOpacity(.55)..style = PaintingStyle.fill);

    // Entrata mini
    final entW = w * .20;
    c.drawRect(Rect.fromLTWH((w - entW) / 2, h * .82, entW, h * .04),
        Paint()..color = const Color(0xCC000000)..style = PaintingStyle.fill);
  }

  void _drawHoneycomb(Canvas canvas, Rect rect, double hexR, Color baseColor) {
    final hexPaint = Paint()
      ..color = baseColor.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;

    canvas.save();
    canvas.clipRect(rect);

    final hexW = hexR * sqrt(3);
    final hexH = hexR * 2.0;

    for (double row = rect.top - hexH; row < rect.bottom + hexH; row += hexH * .75) {
      final rowN = ((row - rect.top) / (hexH * .75)).round();
      final xOff = (rowN % 2 == 1) ? hexW / 2 : 0.0;
      for (double col = rect.left - hexW; col < rect.right + hexW; col += hexW) {
        _drawSingleHex(canvas, Offset(col + xOff, row), hexR, hexPaint);
      }
    }
    canvas.restore();
  }

  void _drawSingleHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60.0 * i - 30.0) * pi / 180.0;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HivePainter o) =>
      color != o.color || tipo != o.tipo ||
      isSelected != o.isSelected || isDragging != o.isDragging;
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — ALBERO (con CustomPaint a strati)
// ════════════════════════════════════════════════════════════════

class _AlberoWidget extends StatelessWidget {
  final bool isDragging;
  const _AlberoWidget({this.isDragging = false});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: isDragging ? Duration.zero : const Duration(milliseconds: 120),
    width: 72, height: 82,
    transform: isDragging ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
    transformAlignment: Alignment.center,
    child: CustomPaint(painter: _AlberoPainter(isDragging: isDragging)),
  );
}

class _AlberoPainter extends CustomPainter {
  final bool isDragging;
  const _AlberoPainter({required this.isDragging});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;

    // Ombra a terra
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * .92), width: w * .52, height: h * .08),
      Paint()
        ..color = Colors.black.withOpacity(.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Tronco
    final trunk = RRect.fromLTRBR(
        cx - w * .07, h * .54, cx + w * .07, h * .84,
        const Radius.circular(3));
    canvas.drawRRect(trunk, Paint()..color = const Color(0xFF795548));
    canvas.drawRRect(
        trunk,
        Paint()
          ..color = const Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    // Texture tronco
    for (double y = h * .56; y < h * .82; y += h * .08) {
      canvas.drawLine(
        Offset(cx - w * .04, y),
        Offset(cx + w * .04, y + h * .03),
        Paint()..color = const Color(0xFF4E342E).withOpacity(.3)..strokeWidth = .7,
      );
    }

    // Chioma posteriore sx
    canvas.drawCircle(Offset(cx - w * .18, h * .40), w * .26,
        Paint()..color = const Color(0xFF1B5E20));
    // Chioma posteriore dx
    canvas.drawCircle(Offset(cx + w * .18, h * .40), w * .26,
        Paint()..color = const Color(0xFF1B5E20));

    // Chioma principale
    canvas.drawCircle(Offset(cx, h * .30), w * .34,
        Paint()..color = const Color(0xFF2E7D32));

    // Highlight radiale
    final grad = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.25, -.45),
        radius: .7,
        colors: [
          const Color(0xFF81C784).withOpacity(.65),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(cx, h * .30), radius: w * .34));
    canvas.drawCircle(Offset(cx, h * .30), w * .34, grad);

    // Bordo drag
    if (isDragging) {
      canvas.drawCircle(
          Offset(cx, h * .30),
          w * .36,
          Paint()
            ..color = Colors.white.withOpacity(.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(_AlberoPainter o) => isDragging != o.isDragging;
}

// ════════════════════════════════════════════════════════════════
//  PAINTER — VIALETTO MODULARE
// ════════════════════════════════════════════════════════════════

class _PathPainter extends CustomPainter {
  final List<PathSegment> segments;
  final Offset drawOffset;
  final double pathWidth;
  final bool isSelected, isDragging;

  const _PathPainter({
    required this.segments, required this.drawOffset,
    required this.pathWidth, this.isSelected = false, this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final line = _buildLine();

    // Selezione/drag glow
    if (isSelected || isDragging) {
      canvas.drawPath(line, Paint()
        ..color = (isSelected ? const Color(0xFF3B82F6) : Colors.white).withOpacity(.4)
        ..strokeWidth = pathWidth + 10
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
    }

    // Bordo
    canvas.drawPath(line, Paint()
      ..color = const Color(0xFF8B6E52)
      ..strokeWidth = pathWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);

    // Riempimento sabbia con gradient
    canvas.drawPath(line, Paint()
      ..color = const Color(0xFFD4A96A)
      ..strokeWidth = pathWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);

    // Highlight centrale chiaro
    canvas.drawPath(line, Paint()
      ..color = const Color(0xFFE8C88A).withOpacity(.45)
      ..strokeWidth = pathWidth * .4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);

    // Linea tratteggiata centrale
    _drawDashed(canvas, line, Paint()
      ..color = const Color(0xFF7D5A3C).withOpacity(.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke, 14.0, 9.0);
  }

  Path _buildLine() {
    final p = Path();
    p.moveTo(drawOffset.dx, drawOffset.dy);
    var cur = drawOffset;
    for (final s in segments) {
      final r = s.angle * pi / 180;
      cur = Offset(cur.dx + cos(r) * s.length, cur.dy + sin(r) * s.length);
      p.lineTo(cur.dx, cur.dy);
    }
    return p;
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final m in path.computeMetrics()) {
      double d = 0; bool drawing = true;
      while (d < m.length) {
        if (drawing) {
          final end = d + dash < m.length ? d + dash : m.length;
          canvas.drawPath(m.extractPath(d, end), paint);
          d = end;
        } else { d += gap; }
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter o) =>
      segments != o.segments || drawOffset != o.drawOffset ||
      pathWidth != o.pathWidth || isSelected != o.isSelected;
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — HANDLE ESTENSIONE VIALETTO
// ════════════════════════════════════════════════════════════════

class _PathHandle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PathHandle({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color, shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(.5), blurRadius: 10, spreadRadius: 1),
          BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 6),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — COMPASS PICKER OVERLAY (direzione vialetto)
// ════════════════════════════════════════════════════════════════

class _CompassPickerOverlay extends StatelessWidget {
  final double referenceAngle;
  final void Function(double angle) onSelect; // angolo assoluto canvas (0=dx,90=giù)
  final VoidCallback onDismiss;

  // Bussola assoluta: pos=0 in alto, CW → canvas angle = (pos*45 - 90 + 360) % 360
  static const _dirs = [
    (pos: 0, angle: 270.0, label: '↑'),
    (pos: 1, angle: 315.0, label: '↗'),
    (pos: 2, angle: 0.0,   label: '→'),
    (pos: 3, angle: 45.0,  label: '↘'),
    (pos: 4, angle: 90.0,  label: '↓'),
    (pos: 5, angle: 135.0, label: '↙'),
    (pos: 6, angle: 180.0, label: '←'),
    (pos: 7, angle: 225.0, label: '↖'),
  ];

  const _CompassPickerOverlay({
    required this.referenceAngle,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2436),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.5),
                blurRadius: 28, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(children: [
              const Icon(Icons.route_rounded, color: Colors.white38, size: 13),
              const SizedBox(width: 6),
              const Text('DIREZIONE SEGMENTO',
                  style: TextStyle(color: Colors.white38, fontSize: 9,
                      letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
              ),
            ]),
            const SizedBox(height: 12),

            // Compass rose
            SizedBox(
              width: 168, height: 168,
              child: Stack(
                children: [
                  // Background
                  Positioned.fill(
                    child: CustomPaint(
                        painter: _CompassBgPainter(referenceAngle: referenceAngle)),
                  ),
                  // Direction buttons
                  ..._dirs.map((d) {
                    const cx = 84.0, cy = 84.0, r = 58.0;
                    final posAngleRad = d.pos * 45.0 * pi / 180.0;
                    final bx = cx + r * sin(posAngleRad);
                    final by = cy - r * cos(posAngleRad);
                    // Evidenzia il bottone più vicino alla direzione di riferimento
                    final diff = ((d.angle - referenceAngle) % 360 + 360) % 360;
                    final normDiff = diff > 180 ? 360 - diff : diff;
                    final isMain = normDiff < 22.5;
                    final isSharp = d.angle == 135.0 || d.angle == 225.0 || d.angle == 315.0 || d.angle == 45.0;

                    return Positioned(
                      left: bx - 17,
                      top: by - 17,
                      child: Tooltip(
                        message: d.label,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSelect(d.angle);
                          },
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: isMain
                                  ? const Color(0xFFF59E0B)
                                  : isSharp
                                      ? Colors.white.withOpacity(.06)
                                      : Colors.white.withOpacity(.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isMain
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white.withOpacity(.2),
                                width: isMain ? 2.0 : 1.0,
                              ),
                              boxShadow: isMain
                                  ? [BoxShadow(
                                      color: const Color(0xFFF59E0B).withOpacity(.5),
                                      blurRadius: 10,
                                    )]
                                  : null,
                            ),
                            child: Center(
                              child: Transform.rotate(
                                // canvas: 0=right,90=down → flutter arrow up base → rotate (angle+90)°
                                angle: (d.angle + 90.0) * pi / 180.0,
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: isMain
                                      ? Colors.white
                                      : Colors.white.withOpacity(isSharp ? .3 : .7),
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Centro
                  Center(
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(.15), width: 1),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white24, size: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('annulla',
                    style: TextStyle(color: Colors.white30, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassBgPainter extends CustomPainter {
  final double referenceAngle;
  const _CompassBgPainter({required this.referenceAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = cx - 2;

    // Outer ring fill
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white.withOpacity(.05));
    // Outer ring border
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white.withOpacity(.10)
            ..style = PaintingStyle.stroke..strokeWidth = 1);

    // Inner ring (middle)
    canvas.drawCircle(Offset(cx, cy), 30,
        Paint()..color = Colors.white.withOpacity(.04));

    // Tick marks (8 cardinal)
    final tick = Paint()..color = Colors.white.withOpacity(.18)..strokeWidth = 1;
    for (int i = 0; i < 8; i++) {
      final a = i * 45.0 * pi / 180;
      canvas.drawLine(
        Offset(cx + cos(a) * (r - 1), cy + sin(a) * (r - 1)),
        Offset(cx + cos(a) * (r - 8), cy + sin(a) * (r - 8)),
        tick,
      );
    }

    // Beam verso "dritto" (posizione 0 = alto nella bussola)
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - (r - 10)),
      Paint()
        ..color = const Color(0xFFF59E0B).withOpacity(.25)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CompassBgPainter o) => referenceAngle != o.referenceAngle;
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — INFO CHIP
// ════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF1C2436).withOpacity(.88),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 13),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(
          color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — ADD BUTTON (bottom panel)
// ════════════════════════════════════════════════════════════════

class _AddBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: color.withOpacity(.45), blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(
          color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — EDIT TOGGLE BUTTON
// ════════════════════════════════════════════════════════════════

class _EditToggleBtn extends StatelessWidget {
  final bool editMode, hasChanges;
  final VoidCallback onTap;

  const _EditToggleBtn({
    required this.editMode, required this.hasChanges, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: editMode
            ? (hasChanges ? const Color(0xFFF59E0B) : const Color(0xFF16A34A))
            : const Color(0xFF1C2436),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (editMode
                ? (hasChanges ? const Color(0xFFF59E0B) : const Color(0xFF16A34A))
                : Colors.black).withOpacity(.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          editMode ? Icons.check_rounded : Icons.edit_rounded,
          color: Colors.white, size: 18,
        ),
        const SizedBox(width: 7),
        Text(
          editMode ? (hasChanges ? 'Salva*' : 'Fine') : 'Modifica',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
//  WIDGET — MAP ICON BUTTON
// ════════════════════════════════════════════════════════════════

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  const _MapIconButton({
    required this.icon, required this.onTap, required this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1C2436) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(.2), blurRadius: 8,
              offset: const Offset(0, 3))],
        ),
        child: Icon(icon,
            color: active ? const Color(0xFFF59E0B) : Colors.black54, size: 20),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
//  PAINTER — GRID (hex offset dots)
// ════════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  final double step;
  const _GridPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    // Background caldo
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFEDE8DC));

    // Dot grid con offset esagonale
    final dot = Paint()
      ..color = const Color(0xFFC8B8A8)
      ..style = PaintingStyle.fill;

    final hx = step;
    for (double row = 0; row * step <= size.height + step; row++) {
      final xOff = (row.round() % 2 == 1) ? hx * 0.5 : 0.0;
      for (double col = 0; col * hx <= size.width + hx; col++) {
        canvas.drawCircle(Offset(col * hx + xOff, row * step), 2.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => o.step != step;
}

// ════════════════════════════════════════════════════════════════
//  PAINTER — SNAP GRID OVERLAY
// ════════════════════════════════════════════════════════════════

class _SnapGridPainter extends CustomPainter {
  final double step;
  const _SnapGridPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(.18)
      ..strokeWidth = .5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Snap points
    final dot = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(.35)
      ..style = PaintingStyle.fill;
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 3.0, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_SnapGridPainter o) => o.step != step;
}

// ── Bottone zoom per selection mode ──────────────────────────────────────────

class _MapZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: Colors.brown[700]),
        ),
      ),
    );
  }
}
