import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../../models/arnia.dart';
import '../../../models/melario.dart';
import '../../../services/language_service.dart';
import '../../../constants/theme_constants.dart';

/// Mini-mappa read-only della disposizione fisica delle arnie di un apiario.
/// Legge le posizioni salvate dalla `ApiarioMapWidget` (SharedPreferences
/// chiave `apiary_map_v2_<apiarioId>`). Evidenzia l'arnia selezionata e
/// disegna un piccolo indicatore per i melari attivi.
class MelariApiarioMiniMap extends StatefulWidget {
  final int apiarioId;
  final List<Arnia> arnie;
  final Map<int, List<Melario>> melariByArnia;
  final int? highlightedArniaId;
  final ValueChanged<int>? onArniaTap;
  final double height;

  const MelariApiarioMiniMap({
    Key? key,
    required this.apiarioId,
    required this.arnie,
    required this.melariByArnia,
    this.highlightedArniaId,
    this.onArniaTap,
    this.height = 140.0,
  }) : super(key: key);

  @override
  State<MelariApiarioMiniMap> createState() => _MelariApiarioMiniMapState();
}

class _MelariApiarioMiniMapState extends State<MelariApiarioMiniMap> {
  Map<int, Offset> _positions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  @override
  void didUpdateWidget(covariant MelariApiarioMiniMap old) {
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

  Color _colorFor(Arnia a) {
    try {
      return Color(int.parse(a.coloreHex.replaceFirst('#', '0xFF')));
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
    Provider.of<LanguageService>(context);
    final s = Provider.of<LanguageService>(context, listen: false).strings;

    if (_loading) {
      return SizedBox(height: widget.height);
    }

    final Map<int, Offset> active = {};
    final Map<int, Color> colors = {};
    final Map<int, int> numbers = {};
    final Map<int, int> melariCount = {};
    for (final a in widget.arnie) {
      if (_positions.containsKey(a.id)) {
        active[a.id] = _positions[a.id]!;
        colors[a.id] = _colorFor(a);
        numbers[a.id] = a.numero;
        final list = widget.melariByArnia[a.id] ?? const [];
        melariCount[a.id] = list
            .where((m) => m.stato == 'posizionato' || m.stato == 'in_smielatura')
            .length;
      }
    }

    if (active.isEmpty) {
      return Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          s.melariMiniMapNoLayout,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }

    final bounds = _boundsFor(active)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown.shade200),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, size: 14, color: Colors.brown.shade700),
              const SizedBox(width: 4),
              Text(
                s.melariMiniMapTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown.shade800,
                ),
              ),
              const Spacer(),
              Text(
                s.melariMiniMapTapHint,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (ctx, c) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    final hit = _hitTest(
                      d.localPosition, Size(c.maxWidth, c.maxHeight),
                      active, bounds,
                    );
                    if (hit != null && widget.onArniaTap != null) {
                      widget.onArniaTap!(hit);
                    }
                  },
                  child: CustomPaint(
                    size: Size(c.maxWidth, c.maxHeight),
                    painter: _MelariMiniMapPainter(
                      positions: active,
                      colors: colors,
                      numbers: numbers,
                      melariCount: melariCount,
                      highlightedId: widget.highlightedArniaId,
                      bounds: bounds,
                      highlightColor: ThemeConstants.primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int? _hitTest(Offset local, Size size, Map<int, Offset> pts, Rect b) {
    final scale = min(size.width / b.width, size.height / b.height);
    final ox = (size.width - b.width * scale) / 2;
    final oy = (size.height - b.height * scale) / 2;
    int? best;
    double bestDist = double.infinity;
    const hitR = 22.0;
    for (final e in pts.entries) {
      final x = (e.value.dx - b.left) * scale + ox;
      final y = (e.value.dy - b.top) * scale + oy;
      final d = (Offset(x, y) - local).distance;
      if (d < hitR && d < bestDist) {
        best = e.key;
        bestDist = d;
      }
    }
    return best;
  }
}

class _MelariMiniMapPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final Map<int, Color> colors;
  final Map<int, int> numbers;
  final Map<int, int> melariCount;
  final int? highlightedId;
  final Rect bounds;
  final Color highlightColor;

  _MelariMiniMapPainter({
    required this.positions,
    required this.colors,
    required this.numbers,
    required this.melariCount,
    required this.highlightedId,
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

    const baseR = 9.0;
    const melarioH = 3.0;
    const melarioW = 12.0;

    // Render highlighted last so it draws above others
    final entries = positions.entries.toList()
      ..sort((a, b) {
        final ah = a.key == highlightedId ? 1 : 0;
        final bh = b.key == highlightedId ? 1 : 0;
        return ah.compareTo(bh);
      });

    for (final entry in entries) {
      final id = entry.key;
      final p = toMini(entry.value);
      final color = colors[id] ?? const Color(0xFFF5A623);
      final isHigh = id == highlightedId;
      final count = melariCount[id] ?? 0;

      // Stacked melari boxes above the hive
      for (int i = 0; i < count && i < 4; i++) {
        final rect = Rect.fromCenter(
          center: Offset(p.dx, p.dy - baseR - 2 - i * (melarioH + 1)),
          width: melarioW,
          height: melarioH,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          Paint()..color = const Color(0xFFEFCF78),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          Paint()
            ..color = const Color(0xFFB8942A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6,
        );
      }
      if (count > 4) {
        final tp = TextPainter(
          text: TextSpan(
            text: '+${count - 4}',
            style: TextStyle(
              fontSize: 8,
              color: Colors.brown.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(p.dx - tp.width / 2,
              p.dy - baseR - 2 - 4 * (melarioH + 1) - tp.height),
        );
      }

      // Highlight halo
      if (isHigh) {
        canvas.drawCircle(
          p,
          baseR + 5,
          Paint()..color = highlightColor.withValues(alpha: 0.25),
        );
        canvas.drawCircle(
          p,
          baseR + 3,
          Paint()
            ..color = highlightColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }

      // Arnia body
      canvas.drawCircle(p, baseR, Paint()..color = color);
      canvas.drawCircle(
        p,
        baseR,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Number label inside
      final numStr = '${numbers[id] ?? ''}';
      if (numStr.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: numStr,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_MelariMiniMapPainter old) =>
      old.positions != positions ||
      old.colors != colors ||
      old.numbers != numbers ||
      old.melariCount != melariCount ||
      old.highlightedId != highlightedId ||
      old.bounds != bounds;
}
