import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/theme_constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/varroa_checkpoint.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/varroa_service.dart';
import 'varroa_form_screen.dart';
import 'varroa_model_info_screen.dart';

class VarroaScreen extends StatefulWidget {
  final int coloniaId;
  final String coloniaName;
  final double? lastTelainiCovata;

  const VarroaScreen({
    Key? key,
    required this.coloniaId,
    required this.coloniaName,
    this.lastTelainiCovata,
  }) : super(key: key);

  @override
  State<VarroaScreen> createState() => _VarroaScreenState();
}

class _VarroaScreenState extends State<VarroaScreen> {
  bool _isLoading = true;
  String? _error;

  List<VarroaCheckpoint> _checkpoints = [];
  List<Map<String, dynamic>> _trajectory = [];
  List<Map<String, dynamic>> _trattamenti = [];
  Map<String, dynamic>? _allarme;
  Map<String, dynamic> _statistiche = {};

  // Chart range: days to show in the past
  int _rangeDays = 120;

  final _displayFormat = DateFormat('d MMM');
  final _fullFormat    = DateFormat('d MMM yyyy');

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final svc   = VarroaService(Provider.of<ApiService>(context, listen: false));
      final data  = await svc.getTraiettoria(widget.coloniaId, daysAhead: 60);
      if (mounted) {
        setState(() {
          _checkpoints = (data['checkpoints'] as List? ?? [])
              .map((e) => VarroaCheckpoint.fromJson(e as Map<String, dynamic>))
              .toList();
          _trajectory  = List<Map<String, dynamic>>.from(data['trajectory'] ?? []);
          _trattamenti = List<Map<String, dynamic>>.from(data['trattamenti_nel_range'] ?? []);
          _allarme     = data['allarme'] as Map<String, dynamic>?;
          _statistiche = (data['statistiche'] as Map<String, dynamic>?) ?? {};
          _isLoading   = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _openForm({VarroaCheckpoint? cp}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VarroaFormScreen(
          coloniaId:           widget.coloniaId,
          coloniaName:         widget.coloniaName,
          checkpoint:          cp,
          initialTelainiCovata: widget.lastTelainiCovata,
        ),
      ),
    );
    if (result == true) _load();
  }

  void _openModelInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VarroaModelInfoScreen()),
    );
  }

  Future<void> _deleteCheckpoint(VarroaCheckpoint cp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.varroaDeleteTitle),
        content: Text(_s.varroaDeleteConfirm(
            _fullFormat.format(DateTime.parse(cp.dataCampionamento)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_s.btnCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.btnConfirm,
                style: TextStyle(color: ThemeConstants.errorColor)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await VarroaService(Provider.of<ApiService>(context, listen: false))
          .deleteCheckpoint(cp.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeConstants.primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_s.varroaScreenTitle,
                style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(widget.coloniaName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: _s.varroaRefresh,
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(_s.varroaFabAdd),
        backgroundColor: ThemeConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _checkpoints.isEmpty
                  ? _buildEmpty()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: ThemeConstants.errorColor),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _load, child: Text(_s.varroaRefresh)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bug_report_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_s.varroaEmptyTitle,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_s.varroaEmptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: Text(_s.varroaFabAdd),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _openModelInfo,
              icon: Icon(Icons.info_outline,
                  size: 15,
                  color: ThemeConstants.secondaryColor),
              label: Text(
                _s.varroaModelInfoBtn,
                style: TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _load,
      color: ThemeConstants.primaryColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildAlarmCard(),
          const SizedBox(height: 12),
          _buildChartCard(),
          const SizedBox(height: 12),
          _buildStatsRow(),
          const SizedBox(height: 12),
          _buildModelInfoBanner(),
          const SizedBox(height: 16),
          _buildCheckpointsList(),
        ],
      ),
    );
  }

  Widget _buildModelInfoBanner() {
    return InkWell(
      onTap: _openModelInfo,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ThemeConstants.secondaryColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: ThemeConstants.secondaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16,
                color: ThemeConstants.secondaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _s.varroaModelInfoBtn,
                style: TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.secondaryColor,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 16,
                color: ThemeConstants.secondaryColor.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  // ── Alarm card ─────────────────────────────────────────────────────────────

  Widget _buildAlarmCard() {
    if (_allarme == null) return const SizedBox.shrink();
    final livello   = _allarme!['livello'] as String;
    final pct       = _allarme!['percentuale_attuale'] as double;
    final sGialla   = _allarme!['soglia_gialla'] as double;
    final sRossa    = _allarme!['soglia_rossa'] as double;
    final dataPrev  = _allarme!['data_prevista_soglia_rossa'] as String?;
    final color     = _levelColor(livello);
    final giorni    = _statistiche['giorni_dall_ultimo_checkpoint'] as int? ?? 0;

    return Card(
      color: const Color(0xFFFFFDF5),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Big % circle
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color),
                  ),
                  Text(
                    _s.varroaAlarmPct,
                    style: TextStyle(fontSize: 9, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _levelLabel(livello),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _s.varroaAlarmDaGiorni(giorni),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _s.varroaAlarmSoglie(sGialla, sRossa),
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (dataPrev != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _s.varroaAlarmProiezioneRossa(
                          _fullFormat.format(DateTime.parse(dataPrev))),
                      style: TextStyle(
                          fontSize: 11,
                          color: ThemeConstants.errorColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chart card ─────────────────────────────────────────────────────────────

  Widget _buildChartCard() {
    return Card(
      color: const Color(0xFFFFFDF5),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: ThemeConstants.secondaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _s.varroaChartTitle,
                  style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: ThemeConstants.secondaryColor),
                ),
                const Spacer(),
                _buildRangeChips(),
              ],
            ),
            const Divider(height: 16),
            SizedBox(height: 220, child: _buildChart()),
            const SizedBox(height: 8),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final range in [60, 120, 365])
          GestureDetector(
            onTap: () => setState(() { _rangeDays = range; }),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _rangeDays == range
                    ? ThemeConstants.primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                range == 365 ? '12M' : '${range ~/ 30}M',
                style: TextStyle(
                    fontSize: 10,
                    color: _rangeDays == range ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChart() {
    if (_trajectory.isEmpty) return const SizedBox.shrink();

    // Filter trajectory to _rangeDays before today + full projection
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    final filtered = _trajectory
        .where((p) => DateTime.parse(p['data'] as String).isAfter(cutoff))
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    final startDate = DateTime.parse(filtered.first['data'] as String);
    final checkpointDates = _checkpoints
        .map((c) => c.dataCampionamento)
        .toSet();

    // Split into observed+estimated and projection spots
    final observedSpots  = <FlSpot>[];
    final projectionSpots = <FlSpot>[];

    for (final p in filtered) {
      final d   = DateTime.parse(p['data'] as String);
      final x   = d.difference(startDate).inDays.toDouble();
      final y   = (p['percentuale'] as num).toDouble();
      final tipo = p['tipo'] as String;
      if (tipo == 'proiezione') {
        projectionSpots.add(FlSpot(x, y));
      } else {
        observedSpots.add(FlSpot(x, y));
      }
    }

    // Total x-range
    final maxX = filtered.isNotEmpty
        ? DateTime.parse(filtered.last['data'] as String)
              .difference(startDate)
              .inDays
              .toDouble()
        : 60.0;

    // Thresholds
    final sGialla = (_allarme?['soglia_gialla'] as num?)?.toDouble() ?? 2.0;
    final sRossa  = (_allarme?['soglia_rossa']  as num?)?.toDouble() ?? 3.0;

    // Y max
    final allPct = filtered.map((p) => (p['percentuale'] as num).toDouble()).toList();
    final yMax   = (allPct.reduce((a, b) => a > b ? a : b) * 1.3).clamp(4.0, 12.0);

    return LineChart(
      LineChartData(
        minX: 0, maxX: maxX,
        minY: 0, maxY: yMax,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 30,
          getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200, strokeWidth: 0.8),
          getDrawingVerticalLine: (_) => FlLine(
              color: Colors.grey.shade200, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: sGialla,
              color: Colors.amber.shade700,
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                style: TextStyle(
                    fontSize: 9, color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold),
                labelResolver: (_) => '${sGialla.toStringAsFixed(1)}%',
              ),
            ),
            HorizontalLine(
              y: sRossa,
              color: ThemeConstants.errorColor,
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                style: TextStyle(
                    fontSize: 9,
                    color: ThemeConstants.errorColor,
                    fontWeight: FontWeight.bold),
                labelResolver: (_) => '${sRossa.toStringAsFixed(1)}%',
              ),
            ),
          ],
          verticalLines: _trattamenti.map((t) {
            final d = DateTime.parse(t['data_inizio'] as String);
            final x = d.difference(startDate).inDays.toDouble();
            return VerticalLine(
              x: x,
              color: Colors.green.shade600.withOpacity(0.7),
              strokeWidth: 1.5,
              dashArray: [4, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                    fontSize: 8,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold),
                labelResolver: (_) {
                  final nome = (t['nome'] as String? ?? '');
                  return nome.length > 8 ? nome.substring(0, 8) : nome;
                },
              ),
            );
          }).toList(),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) => v == v.roundToDouble() && v >= 0
                  ? Text('${v.toInt()}%',
                      style: const TextStyle(fontSize: 9, color: Colors.black54))
                  : const SizedBox.shrink(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 30,
              reservedSize: 22,
              getTitlesWidget: (x, _) {
                final d = startDate.add(Duration(days: x.toInt()));
                return Text(
                  _displayFormat.format(d),
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                );
              },
            ),
          ),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: ThemeConstants.secondaryColor.withOpacity(0.85),
            getTooltipItems: (spots) => spots.map((spot) {
              final d = startDate.add(Duration(days: spot.x.toInt()));
              return LineTooltipItem(
                '${_displayFormat.format(d)}\n${spot.y.toStringAsFixed(2)}%',
                const TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Series 1: checkpoint points + interpolated (solid)
          if (observedSpots.isNotEmpty)
            LineChartBarData(
              spots: observedSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: ThemeConstants.primaryColor,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) {
                  final d = startDate
                      .add(Duration(days: spot.x.toInt()))
                      .toIso8601String()
                      .substring(0, 10);
                  return checkpointDates.contains(d);
                },
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 5,
                  color: ThemeConstants.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          // Series 2: projection (dashed, lighter)
          if (projectionSpots.isNotEmpty)
            LineChartBarData(
              spots: projectionSpots,
              isCurved: false,
              color: ThemeConstants.primaryColor.withOpacity(0.45),
              barWidth: 2,
              dashArray: const [6, 4],
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _legendItem(ThemeConstants.primaryColor, _s.varroaLegendaOsservato, solid: true),
        _legendItem(ThemeConstants.primaryColor.withOpacity(0.45),
            _s.varroaLegendaProiezione, solid: false),
        _legendItem(Colors.amber.shade700, _s.varroaLegendaSogliaGialla, dashed: true),
        _legendItem(ThemeConstants.errorColor, _s.varroaLegendaSogliaRossa, dashed: true),
        _legendItem(Colors.green.shade600, _s.varroaLegendaTrattamento, vertical: true),
      ],
    );
  }

  Widget _legendItem(Color color, String label,
      {bool solid = true, bool dashed = false, bool vertical = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 12,
          child: CustomPaint(
            painter: _LegendLinePainter(
                color: color, dashed: dashed, vertical: vertical),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final n       = _statistiche['n_checkpoints'] as int? ?? 0;
    final giorni  = _statistiche['giorni_dall_ultimo_checkpoint'] as int? ?? 0;
    final tasso   = _statistiche['tasso_crescita_giornaliero_osservato'] as double?;
    final tassoStr = tasso != null
        ? '${(tasso * 100).toStringAsFixed(2)}%/d'
        : '—';

    return Row(
      children: [
        _statCard(_s.varroaStatCheckpoints, n.toString(),
            Icons.pin_drop_outlined, ThemeConstants.primaryColor),
        const SizedBox(width: 8),
        _statCard(_s.varroaStatGiorni, '$giorni gg',
            Icons.access_time_outlined, Colors.blue.shade600),
        const SizedBox(width: 8),
        _statCard(_s.varroaStatTasso, tassoStr,
            Icons.trending_up, tasso != null && tasso > 0.02
                ? ThemeConstants.errorColor
                : ThemeConstants.successColor),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: const Color(0xFFFFFDF5),
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ── Checkpoints list ───────────────────────────────────────────────────────

  Widget _buildCheckpointsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: ThemeConstants.secondaryColor, size: 16),
            const SizedBox(width: 8),
            Text(
              _s.varroaListTitle,
              style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ThemeConstants.secondaryColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._checkpoints.map(_buildCheckpointCard),
      ],
    );
  }

  Widget _buildCheckpointCard(VarroaCheckpoint cp) {
    final livello = cp.rischioLivello;
    final color   = _levelColor(livello);
    final date    = _fullFormat.format(DateTime.parse(cp.dataCampionamento));

    String detailStr;
    if (cp.metodo == 'caduta_naturale') {
      detailStr = cp.cadutaGiornaliera != null
          ? '${cp.cadutaGiornaliera!.toStringAsFixed(1)} ${_s.varroaFormSuffixCaduta}'
          : '${cp.acariContati} acari / ${cp.giorniMisurazione} gg';
    } else {
      detailStr = cp.apiCampionate != null
          ? '${cp.acariContati} / ${cp.apiCampionate} api'
          : '';
    }

    return Card(
      color: const Color(0xFFFFFDF5),
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: ListTile(
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${cp.percentualeCalcolata.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        title: Text(date,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _metodoBadge(cp.metodo),
                const SizedBox(width: 6),
                Text(detailStr,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: Colors.blue.shade600,
              tooltip: _s.varroaCheckpointEdit,
              onPressed: () => _openForm(cp: cp),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: ThemeConstants.errorColor,
              tooltip: _s.varroaCheckpointDelete,
              onPressed: () => _deleteCheckpoint(cp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metodoBadge(String metodo) {
    Color color;
    String label;
    switch (metodo) {
      case 'lavaggio_alcolico':
        color = Colors.blue.shade700;
        label = 'LAV';
        break;
      case 'sugar_shake':
        color = Colors.brown.shade500;
        label = 'SUG';
        break;
      default:
        color = Colors.green.shade700;
        label = 'CAD';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _levelColor(String livello) {
    switch (livello) {
      case 'rosso':     return ThemeConstants.errorColor;
      case 'giallo':    return Colors.amber.shade700;
      case 'arancione': return Colors.orange;
      default:          return ThemeConstants.successColor;
    }
  }

  String _levelLabel(String livello) {
    switch (livello) {
      case 'rosso':     return _s.varroaRischioRosso;
      case 'giallo':    return _s.varroaRischioGiallo;
      case 'arancione': return _s.varroaRischioArancione;
      default:          return _s.varroaRischioVerde;
    }
  }
}

// ── Legend line painter ────────────────────────────────────────────────────

class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool dashed;
  final bool vertical;

  const _LegendLinePainter(
      {required this.color, this.dashed = false, this.vertical = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = vertical ? 1.5 : 2;

    if (vertical) {
      final cx = size.width / 2;
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    } else if (dashed) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, size.height / 2),
            Offset((x + 5).clamp(0, size.width), size.height / 2), paint);
        x += 9;
      }
    } else {
      canvas.drawLine(
          Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) =>
      old.color != color || old.dashed != dashed;
}
