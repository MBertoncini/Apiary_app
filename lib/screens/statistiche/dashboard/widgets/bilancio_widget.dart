import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class BilancioWidget extends StatefulWidget {
  final StatisticheService service;
  const BilancioWidget({super.key, required this.service});

  @override
  State<BilancioWidget> createState() => _BilancioWidgetState();
}

class _BilancioWidgetState extends State<BilancioWidget> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  late int _anno;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _anno = DateTime.now().year;
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getBilancioEconomico(anno: _anno, forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final anni = List<int>.generate(5, (i) => currentYear - i);
    return DashboardCardBase(
      icon: const Icon(Icons.euro, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleBilancio(_data?['anno'] as int? ?? _anno),
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 270,
      headerTrailing: DropdownButton<int>(
        value: _anno,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        items: anni
            .map((y) => DropdownMenuItem<int>(value: y, child: Text('$y')))
            .toList(),
        onChanged: (v) {
          if (v == null || v == _anno) return;
          setState(() => _anno = v);
          _load(forceRefresh: true);
        },
      ),
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    // Cast difensivi: cache stats può contenere {} su errore parziale.
    final entrateRaw = (_data?['entrate'] as List?) ?? const [];
    final usciteRaw = (_data?['uscite'] as List?) ?? const [];
    final entrate = entrateRaw.map((v) => (v is num ? v.toDouble() : 0.0)).toList();
    final uscite = usciteRaw.map((v) => (v is num ? v.toDouble() : 0.0)).toList();
    final mesi = List<String>.from(_data?['mesi'] ?? const []);
    final saldo = (_data?['saldo_totale'] as num?)?.toDouble() ?? 0.0;

    final maxY = [...entrate, ...uscite].fold(0.0, (max, v) => v > max ? v : max) * 1.2;

    return Column(
      children: [
        // Saldo totale KPI
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: saldo >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_s.dashboardBilancioSaldoAnnuale, style: const TextStyle(fontSize: 14)),
              Text('€ ${saldo.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: saldo >= 0 ? Colors.green : Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(enabled: false),
              maxY: maxY > 0 ? maxY : 10,
              barGroups: List.generate(entrate.length, (i) => BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  BarChartRodData(toY: entrate[i], color: Colors.green.withOpacity(0.8), width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
                  BarChartRodData(toY: uscite[i], color: Colors.red.withOpacity(0.8), width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
                ],
              )),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= mesi.length) return const SizedBox();
                    return Text(mesi[i], style: const TextStyle(fontSize: 9));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('€${v.toInt()}', style: const TextStyle(fontSize: 9)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(Colors.green, _s.dashboardBilancioEntrate),
            const SizedBox(width: 16),
            _legendItem(Colors.red, _s.dashboardBilancioUscite),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
