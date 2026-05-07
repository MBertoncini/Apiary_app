import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../../models/regina.dart';
import 'regina_genealogia_info_sheet.dart';
import 'regina_node_widget.dart';

/// Vista albero genealogico delle regine.
///
/// Layout: tidy-tree top-down per livelli, multi-radice (foreste).
/// Ogni regina senza `reginaMadreId` (o con madre fuori dal set filtrato)
/// è un root del proprio sotto-albero. Le linee madre→figlia sono disegnate
/// con un `CustomPainter` SOTTO i nodi; i nodi sono `Positioned` cliccabili
/// dentro un `InteractiveViewer` che gestisce pan e pinch-zoom.
///
/// L'asse verticale è proporzionale all'anno di nascita (fallback: anno di
/// introduzione). Una colonna a sinistra mostra i marcatori d'anno.
class GenealogiaTreeView extends StatefulWidget {
  final List<Regina> regine;

  /// Insieme degli id delle regine note GLOBALMENTE (non solo nel filtro
  /// corrente): serve a capire se la madre di una regina nel set è
  /// "fuori vista" perché filtrata via, oppure proprio sconosciuta.
  final Set<int> idsKnownGlobally;

  const GenealogiaTreeView({
    Key? key,
    required this.regine,
    required this.idsKnownGlobally,
  }) : super(key: key);

  @override
  State<GenealogiaTreeView> createState() => _GenealogiaTreeViewState();
}

class _GenealogiaTreeViewState extends State<GenealogiaTreeView> {
  static const double _colWidth = 96;
  static const double _yearHeight = 88; // px per anno
  static const double _nodeSize = 52;
  static const double _padding = 32;
  static const double _yearAxisWidth = 48;
  static const double _minGenGap = 0.5; // depthY minimo madre→figlia

  late _LayoutResult _layout;

  @override
  void initState() {
    super.initState();
    _layout = _computeLayout(widget.regine);
  }

  @override
  void didUpdateWidget(covariant GenealogiaTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.regine, widget.regine) ||
        oldWidget.idsKnownGlobally.length != widget.idsKnownGlobally.length) {
      _layout = _computeLayout(widget.regine);
    }
  }

  bool _listEquals(List<Regina> a, List<Regina> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  double _yToPx(double depthY) => depthY * _yearHeight + _padding + 10;

  Offset _centerOf(_LayoutNode n) => Offset(
        n.x * _colWidth + (_nodeSize + 32) / 2 + _padding + _yearAxisWidth,
        _yToPx(n.depthY) + _nodeSize / 2,
      );

  void _onTapNode(_LayoutNode n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => ReginaGenealogiaInfoSheet(
        regina: n.regina,
        figlieCount: n.children.length,
        madreFuoriVista: n.madreFuoriVista,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.regine.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nessuna regina in questa vista',
            style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final width =
        (_layout.maxX + 1) * _colWidth + _padding * 2 + _yearAxisWidth;
    final height = _yToPx(_layout.maxDepthY) + _nodeSize + _padding;

    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.4,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(200),
            constrained: false,
            child: SizedBox(
              width: width < 320 ? 320 : width,
              height: height < 200 ? 200 : height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GenealogiaLinesPainter(
                        nodes: _layout.nodes,
                        centerOf: _centerOf,
                        nodeRadius: _nodeSize / 2,
                        yearMin: _layout.yearMin,
                        yearMax: _layout.yearMax,
                        yToPx: _yToPx,
                        axisX: _padding + _yearAxisWidth - 8,
                      ),
                    ),
                  ),
                  for (final node in _layout.nodes)
                    Positioned(
                      left: node.x * _colWidth + _padding + _yearAxisWidth,
                      top: _yToPx(node.depthY),
                      child: ReginaNodeWidget(
                        regina: node.regina,
                        onTap: () => _onTapNode(node),
                        size: _nodeSize,
                        madreFuoriVista: node.madreFuoriVista,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _LegendChip(
            count: widget.regine.length,
            yearMin: _layout.yearMin,
            yearMax: _layout.yearMax,
          ),
        ),
      ],
    );
  }

  // -------- Layout algorithm --------

  static int? _parseYear(String? s) {
    if (s == null || s.length < 4) return null;
    final y = int.tryParse(s.substring(0, 4));
    if (y == null || y < 1900 || y > 3000) return null;
    return y;
  }

  static int? _rawYear(Regina r) =>
      _parseYear(r.dataNascita) ?? _parseYear(r.dataInserimento);

  _LayoutResult _computeLayout(List<Regina> regine) {
    final byId = <int, _LayoutNode>{};
    for (final r in regine) {
      if (r.id != null) {
        byId[r.id!] = _LayoutNode(r)..year = _rawYear(r);
      }
    }

    // Costruisci relazioni madre→figli e marca le orfane "fuori vista".
    for (final node in byId.values) {
      final mid = node.regina.reginaMadreId;
      if (mid == null) continue;
      final parent = byId[mid];
      if (parent != null) {
        parent.children.add(node);
        node.parent = parent;
      } else if (widget.idsKnownGlobally.contains(mid)) {
        node.madreFuoriVista = true;
      }
    }

    // Ordina i figli per anno (poi id) per stabilità visiva.
    for (final node in byId.values) {
      node.children.sort((a, b) {
        final ay = a.year ?? 9999;
        final by = b.year ?? 9999;
        if (ay != by) return ay.compareTo(by);
        return (a.regina.id ?? 0).compareTo(b.regina.id ?? 0);
      });
    }

    final roots = byId.values.where((n) => n.parent == null).toList();
    roots.sort((a, b) {
      final ah = a.children.isNotEmpty ? 0 : 1;
      final bh = b.children.isNotEmpty ? 0 : 1;
      if (ah != bh) return ah.compareTo(bh);
      final ay = a.year ?? 9999;
      final by = b.year ?? 9999;
      if (ay != by) return ay.compareTo(by);
      return (a.regina.id ?? 0).compareTo(b.regina.id ?? 0);
    });

    // Propaga anno mancante dai genitori (DFS top-down).
    void propagateYear(_LayoutNode n, Set<int> visiting) {
      final id = n.regina.id ?? -1;
      if (visiting.contains(id)) return;
      visiting.add(id);
      if (n.year == null && n.parent?.year != null) {
        n.year = n.parent!.year! + 1;
      }
      for (final c in n.children) {
        propagateYear(c, visiting);
      }
      visiting.remove(id);
    }

    for (final r in roots) {
      propagateYear(r, <int>{});
    }

    // Calcola yearMin/yearMax sulle regine note.
    int? yearMin;
    int? yearMax;
    for (final n in byId.values) {
      final y = n.year;
      if (y == null) continue;
      if (yearMin == null || y < yearMin) yearMin = y;
      if (yearMax == null || y > yearMax) yearMax = y;
    }
    // Fallback se nessuno ha l'anno.
    yearMin ??= DateTime.now().year;
    yearMax ??= yearMin;
    // Assegna l'anno minimo alle regine ancora senza anno (root orfane).
    for (final n in byId.values) {
      n.year ??= yearMin;
    }

    // Larghezza ricorsiva (in unità "colonna").
    void computeWidth(_LayoutNode n, Set<int> visiting) {
      final id = n.regina.id ?? -1;
      if (visiting.contains(id)) {
        n.width = 1;
        return;
      }
      visiting.add(id);
      if (n.children.isEmpty) {
        n.width = 1;
      } else {
        int total = 0;
        for (final c in n.children) {
          computeWidth(c, visiting);
          total += c.width;
        }
        n.width = total < 1 ? 1 : total;
      }
      visiting.remove(id);
    }

    void layoutX(_LayoutNode n, double xStart) {
      if (n.children.isEmpty) {
        n.x = xStart;
      } else {
        double cx = xStart;
        for (final c in n.children) {
          layoutX(c, cx);
          cx += c.width;
        }
        final first = n.children.first.x;
        final last = n.children.last.x;
        n.x = (first + last) / 2;
      }
    }

    void layoutDepthY(_LayoutNode n, Set<int> visiting) {
      final id = n.regina.id ?? -1;
      if (visiting.contains(id)) return;
      visiting.add(id);
      final raw = (n.year! - yearMin!).toDouble();
      if (n.parent == null) {
        n.depthY = raw < 0 ? 0 : raw;
      } else {
        final minD = n.parent!.depthY + _minGenGap;
        n.depthY = raw < minD ? minD : raw;
      }
      for (final c in n.children) {
        layoutDepthY(c, visiting);
      }
      visiting.remove(id);
    }

    double maxDepthY = 0;
    void trackDepthY(_LayoutNode n) {
      if (n.depthY > maxDepthY) maxDepthY = n.depthY;
      for (final c in n.children) {
        trackDepthY(c);
      }
    }

    const double gapBetweenTrees = 1.0;
    double offset = 0;

    for (final r in roots) {
      computeWidth(r, <int>{});
      layoutX(r, offset);
      layoutDepthY(r, <int>{});
      trackDepthY(r);
      offset += r.width + gapBetweenTrees;
    }

    final maxX =
        (offset - gapBetweenTrees).clamp(0, double.infinity).toDouble();
    return _LayoutResult(
      byId.values.toList(),
      maxX,
      maxDepthY,
      yearMin,
      yearMax,
    );
  }
}

class _LayoutNode {
  final Regina regina;
  final List<_LayoutNode> children = [];
  _LayoutNode? parent;
  bool madreFuoriVista = false;
  double x = 0;
  double depthY = 0; // continuo, in "anni" dal yearMin
  int width = 1;
  int? year;
  _LayoutNode(this.regina);
}

class _LayoutResult {
  final List<_LayoutNode> nodes;
  final double maxX;
  final double maxDepthY;
  final int yearMin;
  final int yearMax;
  _LayoutResult(
      this.nodes, this.maxX, this.maxDepthY, this.yearMin, this.yearMax);
}

class _GenealogiaLinesPainter extends CustomPainter {
  final List<_LayoutNode> nodes;
  final Offset Function(_LayoutNode) centerOf;
  final double nodeRadius;
  final int yearMin;
  final int yearMax;
  final double Function(double) yToPx;
  final double axisX;

  _GenealogiaLinesPainter({
    required this.nodes,
    required this.centerOf,
    required this.nodeRadius,
    required this.yearMin,
    required this.yearMax,
    required this.yToPx,
    required this.axisX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintYearAxis(canvas, size);
    _paintLines(canvas);
  }

  void _paintYearAxis(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = ThemeConstants.dividerColor.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final axisPaint = Paint()
      ..color = ThemeConstants.dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(axisX, 0),
      Offset(axisX, size.height),
      axisPaint,
    );

    for (int y = yearMin; y <= yearMax; y++) {
      final dy = yToPx((y - yearMin).toDouble()) + nodeRadius;
      canvas.drawLine(
        Offset(axisX, dy),
        Offset(size.width, dy),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: y.toString(),
          style: const TextStyle(
            color: ThemeConstants.textSecondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(axisX - tp.width - 6, dy - tp.height / 2));
    }
  }

  void _paintLines(Canvas canvas) {
    final paint = Paint()
      ..color = ThemeConstants.secondaryColor.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Per ogni madre raggruppa i suoi figli per disegnare una "rotaia"
    // condivisa appena sotto la madre, da cui partono le verticali ai figli.
    final byParent = <_LayoutNode, List<_LayoutNode>>{};
    for (final n in nodes) {
      final p = n.parent;
      if (p == null) continue;
      byParent.putIfAbsent(p, () => []).add(n);
    }

    for (final entry in byParent.entries) {
      final parent = entry.key;
      final children = entry.value;
      final from = centerOf(parent);
      final fromY = from.dy + nodeRadius;
      final railY = fromY + 14;

      // Verticale dalla madre alla rotaia.
      canvas.drawLine(Offset(from.dx, fromY), Offset(from.dx, railY), paint);

      // Rotaia orizzontale da min a max delle x dei figli (compresa madre).
      double minX = from.dx;
      double maxX = from.dx;
      for (final c in children) {
        final cx = centerOf(c).dx;
        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
      }
      if (maxX - minX > 0.5) {
        canvas.drawLine(Offset(minX, railY), Offset(maxX, railY), paint);
      }

      // Verticale dalla rotaia ad ogni figlio.
      for (final c in children) {
        final to = centerOf(c);
        canvas.drawLine(
          Offset(to.dx, railY),
          Offset(to.dx, to.dy - nodeRadius),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GenealogiaLinesPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.yearMin != yearMin ||
        oldDelegate.yearMax != yearMax;
  }
}

class _LegendChip extends StatelessWidget {
  final int count;
  final int yearMin;
  final int yearMax;
  const _LegendChip({
    required this.count,
    required this.yearMin,
    required this.yearMax,
  });

  @override
  Widget build(BuildContext context) {
    final yearLabel =
        yearMin == yearMax ? '$yearMin' : '$yearMin–$yearMax';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeConstants.cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeConstants.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined,
              size: 14, color: ThemeConstants.secondaryColor),
          const SizedBox(width: 6),
          Text(
            '$count regine · $yearLabel',
            style: const TextStyle(
              fontSize: 12,
              color: ThemeConstants.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
