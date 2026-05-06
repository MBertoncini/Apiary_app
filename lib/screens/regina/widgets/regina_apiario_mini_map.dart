import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../../models/arnia.dart';
import '../../../models/regina.dart';
import '../../../services/language_service.dart';
import '../../../constants/theme_constants.dart';

/// Mini-mappa read-only della disposizione fisica delle arnie di un apiario.
/// Evidenzia le arnie che hanno una regina attiva.
class ReginaApiarioMiniMap extends StatefulWidget {
  final int apiarioId;
  final List<dynamic> arnie; // Dati grezzi o Arnia models
  final List<Regina> regine;
  final Function(int arniaId)? onArniaTap;
  final double height;

  const ReginaApiarioMiniMap({
    Key? key,
    required this.apiarioId,
    required this.arnie,
    required this.regine,
    this.onArniaTap,
    this.height = 120.0,
  }) : super(key: key);

  @override
  State<ReginaApiarioMiniMap> createState() => _ReginaApiarioMiniMapState();
}

class _ReginaApiarioMiniMapState extends State<ReginaApiarioMiniMap> {
  Map<int, Offset> _positions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  @override
  void didUpdateWidget(covariant ReginaApiarioMiniMap old) {
    super.didUpdateWidget(old);
    if (old.apiarioId != widget.apiarioId) {
      _loadPositions();
    }
  }

  Future<void> _loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('apiary_map_v2_${widget.apiarioId}');
    final Map<int, Offset> pos = {};
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['arnie'] is Map) {
          (data['arnie'] as Map<String, dynamic>).forEach((k, v) {
            final id = int.tryParse(k);
            final x = (v is Map) ? (v['x'] as num?)?.toDouble() : null;
            final y = (v is Map) ? (v['y'] as num?)?.toDouble() : null;
            if (id != null && x != null && y != null) {
              pos[id] = Offset(x, y);
            }
          });
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _positions = pos;
      _loading = false;
    });
  }

  Color _colorFor(dynamic a) {
    String? hex = a is Arnia ? a.coloreHex : a['colore_hex'];
    if (hex == null) return const Color(0xFFF5A623);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFF5A623);
    }
  }

  Rect? _boundsFor(Map<int, Offset> pts) {
    if (pts.isEmpty) return null;
    final values = pts.values.toList();
    double x0 = values.first.dx, y0 = values.first.dy;
    double x1 = x0, y1 = y0;
    for (final p in values) {
      if (p.dx < x0) x0 = p.dx;
      if (p.dy < y0) y0 = p.dy;
      if (p.dx > x1) x1 = p.dx;
      if (p.dy > y1) y1 = p.dy;
    }
    const pad = 80.0;
    return Rect.fromLTRB(x0 - pad, y0 - pad, x1 + pad, y1 + pad);
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;

    if (_loading) {
      return SizedBox(height: widget.height);
    }

    final Map<int, Offset> active = {};
    final Map<int, Color> colors = {};
    final Map<int, int> numbers = {};
    final Set<int> regineArnieIds = widget.regine.map((r) => r.arniaId).toSet();
    final Set<int> sospetteArnieIds = widget.regine
        .where((r) => r.sospettaAssente)
        .map((r) => r.arniaId)
        .toSet();

    for (final a in widget.arnie) {
      final id = a is Arnia ? a.id : a['id'];
      if (_positions.containsKey(id)) {
        active[id] = _positions[id]!;
        colors[id] = _colorFor(a);
        numbers[id] = a is Arnia ? a.numero : a['numero'];
      }
    }

    if (active.isEmpty) {
      return const SizedBox.shrink();
    }

    final bounds = _boundsFor(active)!;

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final scale = bounds.width == 0 || bounds.height == 0
                ? 1.0
                : (size.width / bounds.width < size.height / bounds.height
                    ? size.width / bounds.width
                    : size.height / bounds.height);
            final ox = (size.width - bounds.width * scale) / 2;
            final oy = (size.height - bounds.height * scale) / 2;
            Offset toMini(Offset p) => Offset(
                  (p.dx - bounds.left) * scale + ox,
                  (p.dy - bounds.top) * scale + oy,
                );

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RegineMiniMapPainter(
                      positions: active,
                      colors: colors,
                      numbers: numbers,
                      regineArnieIds: regineArnieIds,
                      sospetteArnieIds: sospetteArnieIds,
                      bounds: bounds,
                      highlightColor: ThemeConstants.primaryColor,
                    ),
                  ),
                ),
                // Hit-areas trasparenti per gestire il tap su ogni arnia
                if (widget.onArniaTap != null)
                  ...active.entries.map((e) {
                    final p = toMini(e.value);
                    const r = 14.0;
                    return Positioned(
                      left: p.dx - r,
                      top: p.dy - r,
                      width: r * 2,
                      height: r * 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onArniaTap!(e.key),
                      ),
                    );
                  }),
                Positioned(
                  top: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.melariMiniMapTitle, // Reusiamo stringa "Posizione arnie"
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RegineMiniMapPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final Map<int, Color> colors;
  final Map<int, int> numbers;
  final Set<int> regineArnieIds;
  final Set<int> sospetteArnieIds;
  final Rect bounds;
  final Color highlightColor;

  _RegineMiniMapPainter({
    required this.positions,
    required this.colors,
    required this.numbers,
    required this.regineArnieIds,
    required this.sospetteArnieIds,
    required this.bounds,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width / bounds.width, size.height / bounds.height);
    final ox = (size.width - bounds.width * scale) / 2;
    final oy = (size.height - bounds.height * scale) / 2;

    Offset toMini(Offset p) => Offset(
      (p.dx - bounds.left) * scale + ox,
      (p.dy - bounds.top) * scale + oy,
    );

    const baseR = 10.0;

    for (final entry in positions.entries) {
      final id = entry.key;
      final p = toMini(entry.value);
      final color = colors[id] ?? const Color(0xFFF5A623);
      final hasQueen = regineArnieIds.contains(id);
      final isSospetta = sospetteArnieIds.contains(id);

      if (hasQueen) {
        // Glow effect for hives with queens
        canvas.drawCircle(
          p,
          baseR + 6,
          Paint()..color = (isSospetta ? Colors.red : Colors.amber).withOpacity(0.3),
        );
        canvas.drawCircle(
          p,
          baseR + 3,
          Paint()
            ..color = isSospetta ? Colors.red : Colors.amber
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      // Arnia body
      canvas.drawCircle(p, baseR, Paint()..color = color);
      canvas.drawCircle(
        p,
        baseR,
        Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Number label inside
      final numStr = '${numbers[id] ?? ''}';
      if (numStr.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: numStr,
            style: TextStyle(
              fontSize: 8,
              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
      }
      
      // Mini queen icon (crown) if it has a queen
      if (hasQueen) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '♛',
            style: TextStyle(
              fontSize: 10,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - baseR - 12));
      }
    }
  }

  @override
  bool shouldRepaint(_RegineMiniMapPainter old) => true;
}
