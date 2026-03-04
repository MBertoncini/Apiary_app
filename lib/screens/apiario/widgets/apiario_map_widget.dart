import 'dart:convert';
import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mappa simulata dell'apiario – visualizza le arnie come quadrati
/// posizionabili su una canvas molto grande con sfondo a griglia puntata.
///
/// Se [selectionMode] è true, il drag/edit viene disabilitato e il tap
/// su un'arnia richiama [onArniaTap] per toggleare la selezione.
/// Le arnie selezionate vanno passate in [selectedArnieIds].
class ApiarioMapWidget extends StatefulWidget {
  final List<dynamic> arnie;
  final int apiarioId;
  final Function(int arniaId) onArniaTap;
  final VoidCallback onAddArnia;
  /// Chiamata ogni volta che la modalità modifica cambia (true = edit attivo)
  final ValueChanged<bool>? onEditModeChanged;

  /// Se true, disabilita drag/edit e mostra checkmark sui selezionati.
  final bool selectionMode;

  /// Arnie attualmente selezionate (usate solo con [selectionMode] = true).
  final Set<int> selectedArnieIds;

  const ApiarioMapWidget({
    Key? key,
    required this.arnie,
    required this.apiarioId,
    required this.onArniaTap,
    required this.onAddArnia,
    this.onEditModeChanged,
    this.selectionMode = false,
    this.selectedArnieIds = const {},
  }) : super(key: key);

  @override
  _ApiarioMapWidgetState createState() => _ApiarioMapWidgetState();
}

class _ApiarioMapWidgetState extends State<ApiarioMapWidget> {
  Map<int, Offset> _positions = {};

  bool _editMode = false;
  bool _hasChanges = false;
  int? _draggingId;

  final TransformationController _transformCtrl = TransformationController();

  /// Canvas molto grande per simulare spazio libero illimitato.
  static const double _canvasSize = 10000.0;
  static const double _cellSize = 90.0;
  static const double _gridStep = 120.0;

  /// Punto di origine per il posizionamento iniziale delle arnie
  /// (centrato nella canvas).
  static const double _originX = _canvasSize / 2 - 250;
  static const double _originY = _canvasSize / 2 - 250;

  /// Dimensioni del viewport, aggiornate dalla LayoutBuilder.
  Size _viewportSize = Size.zero;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  @override
  void didUpdateWidget(ApiarioMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arnie.length != widget.arnie.length ||
        oldWidget.apiarioId != widget.apiarioId) {
      _loadPositions();
    }
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  // ── storage ────────────────────────────────────────────────────────────────

  Future<void> _loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('arnie_map_${widget.apiarioId}');
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _positions = map.map((k, v) => MapEntry(
              int.parse(k),
              Offset(
                (v['x'] as num).toDouble(),
                (v['y'] as num).toDouble(),
              ),
            ));
      } catch (_) {}
    }
    _assignMissing();

    // Centra la vista sulle arnie dopo il primo frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnArnie());
  }

  /// Assegna posizione iniziale (griglia centrata) alle arnie non ancora
  /// posizionate.
  void _assignMissing() {
    int col = 0, row = 0;
    for (final arnia in widget.arnie) {
      final id = arnia['id'] as int;
      if (!_positions.containsKey(id)) {
        _positions[id] = Offset(
          _originX + col * (_cellSize + 50),
          _originY + row * (_cellSize + 50),
        );
        col++;
        if (col >= 5) {
          col = 0;
          row++;
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _savePositions() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _positions.map((k, v) => MapEntry(
          k.toString(),
          {'x': v.dx, 'y': v.dy},
        ));
    await prefs.setString(
        'arnie_map_${widget.apiarioId}', jsonEncode(map));
    if (mounted) setState(() => _hasChanges = false);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Color _parseHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.amber;
    }
  }

  bool _isActive(dynamic arnia) =>
      arnia['attiva'] == true || arnia['attiva'] == 1;

  /// Centra la trasformazione per mostrare tutte le arnie nel viewport.
  void _centerOnArnie() {
    if (widget.arnie.isEmpty || _positions.isEmpty) return;
    final vw = _viewportSize.width;
    final vh = _viewportSize.height;
    if (vw == 0 || vh == 0) return;

    final ids = widget.arnie.map((a) => a['id'] as int).toList();
    final pts = ids
        .where((id) => _positions.containsKey(id))
        .map((id) => _positions[id]!)
        .toList();
    if (pts.isEmpty) return;

    final minX = pts.map((p) => p.dx).reduce(min);
    final minY = pts.map((p) => p.dy).reduce(min);
    final maxX = pts.map((p) => p.dx).reduce(max) + _cellSize;
    final maxY = pts.map((p) => p.dy).reduce(max) + _cellSize;

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    const padding = 80.0;
    final bboxW = (maxX - minX) + padding * 2;
    final bboxH = (maxY - minY) + padding * 2;

    // Scala per far entrare tutto il bbox nel viewport
    final scale = min(vw / bboxW, vh / bboxH).clamp(0.2, 2.5);

    // Traslazione: screen_pos = scale * canvas_pos + translate
    // → translate = viewport_center - scale * canvas_center
    final tx = vw / 2 - scale * centerX;
    final ty = vh / 2 - scale * centerY;

    _transformCtrl.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.arnie.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Aggiorna viewport size ad ogni rebuild
        if (constraints.biggest != _viewportSize) {
          _viewportSize = constraints.biggest;
        }

        return Stack(
          children: [
            // ── sfondo infinito (stesso colore della canvas) ──────────────
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFFF7F4EE)),
            ),

            // ── canvas interattiva ────────────────────────────────────────
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.15,
                maxScale: 4.0,
                constrained: false,
                // Margine infinito: l'utente può pannare oltre i bordi della
                // canvas senza essere bloccato.
                boundaryMargin: const EdgeInsets.all(double.infinity),
                // Pan con un dito sempre abilitato (in edit mode il gesto
                // sulle arnie viene catturato dal loro GestureDetector opaque
                // prima che arrivi all'InteractiveViewer).
                panEnabled: true,
                child: SizedBox(
                  width: _canvasSize,
                  height: _canvasSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Sfondo griglia
                      RepaintBoundary(
                        child: CustomPaint(
                          size: const Size(_canvasSize, _canvasSize),
                          painter: _GridPainter(step: _gridStep),
                        ),
                      ),
                      // Arnie
                      ..._buildArnieWidgets(),
                    ],
                  ),
                ),
              ),
            ),

            // ── overlay: stato vuoto ──────────────────────────────────────
            if (isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hive_outlined,
                        size: 72, color: Colors.brown.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Nessuna arnia in questo apiario',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Premi il pulsante + per aggiungerne una',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: widget.onAddArnia,
                      icon: const Icon(Icons.add),
                      label: const Text('Aggiungi arnia'),
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),

            // ── overlay: legenda modalità edit ────────────────────────────
            if (_editMode && !isEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_with, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Trascina le arnie · Scorri per navigare',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // ── overlay: bottoni controllo (nascosti in selection mode) ──
            if (!widget.selectionMode)
              Positioned(
                top: 12,
                right: 12,
                child: _buildControlButtons(),
              ),

            // ── overlay: legenda selezione ────────────────────────────────
            if (widget.selectionMode && !isEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Tocca per selezionare · Scorri per navigare',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // ── overlay: conta selezione ──────────────────────────────────
            if (widget.selectionMode && widget.selectedArnieIds.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.selectedArnieIds.length} selezionate',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),

            // ── FAB aggiungi arnia (solo in edit mode, non in selection) ──
            if (_editMode && !widget.selectionMode)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'add_arnia_map',
                  onPressed: widget.onAddArnia,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi arnia'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  // ── arnia widgets ──────────────────────────────────────────────────────────

  List<Widget> _buildArnieWidgets() {
    return widget.arnie.map((arnia) {
      final id = arnia['id'] as int;
      final pos = _positions[id] ?? Offset(_originX, _originY);
      final color = _parseHex(arnia['colore_hex'] ?? '#FFC107');
      final isActive = _isActive(arnia);
      final numero = arnia['numero'];
      final isDragging = _draggingId == id;
      final isSelected = widget.selectionMode &&
          widget.selectedArnieIds.contains(id);

      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: _editMode && !widget.selectionMode
            ? _DraggableArnia(
                numero: numero,
                color: color,
                isActive: isActive,
                isDragging: isDragging,
                cellSize: _cellSize,
                onDragStart: () => setState(() => _draggingId = id),
                onDragUpdate: (delta) {
                  const sensitivity = 3.0;
                  final scale =
                      _transformCtrl.value.getMaxScaleOnAxis();
                  setState(() {
                    _positions[id] = Offset(
                      (pos.dx + delta.dx / scale * sensitivity)
                          .clamp(0.0, _canvasSize),
                      (pos.dy + delta.dy / scale * sensitivity)
                          .clamp(0.0, _canvasSize),
                    );
                    _hasChanges = true;
                  });
                },
                onDragEnd: () => setState(() => _draggingId = null),
              )
            : _StaticArnia(
                numero: numero,
                color: color,
                isActive: isActive,
                isSelected: isSelected,
                cellSize: _cellSize,
                onTap: () => widget.onArniaTap(id),
              ),
      );
    }).toList();
  }

  // ── controlli overlay ──────────────────────────────────────────────────────

  Widget _buildControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Toggle edit / salva
        _MapButton(
          onPressed: _toggleEditMode,
          icon: _editMode ? Icons.check_circle : Icons.edit,
          label: _editMode ? 'Salva' : 'Modifica',
          color: _editMode ? Colors.green : Colors.white,
          foreground: _editMode ? Colors.white : Colors.black87,
          tooltip:
              _editMode ? 'Salva posizioni' : 'Modifica mappa',
        ),
        const SizedBox(height: 8),
        // Centra su tutte le arnie (sempre visibile)
        _MapButton(
          onPressed: _centerOnArnie,
          icon: Icons.filter_center_focus,
          label: 'Centra',
          color: Colors.white,
          foreground: Colors.black87,
          tooltip: 'Centra la vista su tutte le arnie',
        ),
      ],
    );
  }

  Future<void> _toggleEditMode() async {
    if (_editMode && _hasChanges) {
      await _savePositions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Posizioni salvate'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    if (mounted) {
      final newMode = !_editMode;
      setState(() => _editMode = newMode);
      widget.onEditModeChanged?.call(newMode);
    }
  }
}

// ── widget arnia in modalità statica (tap) ─────────────────────────────────

class _StaticArnia extends StatelessWidget {
  final int numero;
  final Color color;
  final bool isActive;
  final bool isSelected;
  final double cellSize;
  final VoidCallback onTap;

  const _StaticArnia({
    required this.numero,
    required this.color,
    required this.isActive,
    required this.cellSize,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isActive ? color : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ArniaCell(
            numero: numero,
            color: displayColor,
            isActive: isActive,
            isSelected: isSelected,
            cellSize: cellSize,
            isDragging: false,
            showDragIcon: false,
          ),
          if (isSelected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

// ── widget arnia in modalità drag ──────────────────────────────────────────

class _DraggableArnia extends StatelessWidget {
  final int numero;
  final Color color;
  final bool isActive;
  final bool isDragging;
  final double cellSize;
  final VoidCallback onDragStart;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;

  const _DraggableArnia({
    required this.numero,
    required this.color,
    required this.isActive,
    required this.isDragging,
    required this.cellSize,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isActive ? color : Colors.grey;
    return GestureDetector(
      // opaque: il gesto inizia sull'arnia → viene catturato qui prima
      // che arrivi all'InteractiveViewer, che panna il canvas solo
      // sugli spazi vuoti.
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onDragStart(),
      onPanUpdate: (d) => onDragUpdate(d.delta),
      onPanEnd: (_) => onDragEnd(),
      child: _ArniaCell(
        numero: numero,
        color: displayColor,
        isActive: isActive,
        cellSize: cellSize,
        isDragging: isDragging,
        showDragIcon: true,
      ),
    );
  }
}

// ── cella arnia (aspetto visuale) ──────────────────────────────────────────

class _ArniaCell extends StatelessWidget {
  final int numero;
  final Color color;
  final bool isActive;
  final bool isSelected;
  final double cellSize;
  final bool isDragging;
  final bool showDragIcon;

  const _ArniaCell({
    required this.numero,
    required this.color,
    required this.isActive,
    required this.cellSize,
    required this.isDragging,
    required this.showDragIcon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.4 ? Colors.black87 : Colors.white;

    return AnimatedContainer(
      duration:
          isDragging ? Duration.zero : const Duration(milliseconds: 120),
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: Colors.green, width: 4)
            : Border.all(
                color: isDragging
                    ? Colors.white
                    : color.withOpacity(0.4),
                width: isDragging ? 3 : 2,
              ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.green.withOpacity(0.45)
                : Colors.black.withOpacity(isDragging ? 0.35 : 0.18),
            blurRadius: isSelected ? 12 : (isDragging ? 16 : 5),
            offset: Offset(0, isDragging ? 8 : 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showDragIcon)
            Icon(Icons.drag_indicator,
                size: 14, color: textColor.withOpacity(0.6)),
          Text(
            '$numero',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          if (!isActive)
            Text(
              'inattiva',
              style: TextStyle(
                  color: textColor.withOpacity(0.7), fontSize: 9),
            ),
        ],
      ),
    );
  }
}

// ── bottone controllo overlay ──────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final String tooltip;

  const _MapButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── sfondo griglia puntata ─────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final double step;

  const _GridPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    // Sfondo sabbia chiaro
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F4EE),
    );

    // Punti griglia
    final dotPaint = Paint()
      ..color = Colors.brown.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.step != step;
}
