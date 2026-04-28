import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class ProduzionePerTipoWidget extends StatefulWidget {
  final StatisticheService service;
  const ProduzionePerTipoWidget({super.key, required this.service});

  @override
  State<ProduzionePerTipoWidget> createState() => _ProduzionePerTipoWidgetState();
}

class _ProduzionePerTipoWidgetState extends State<ProduzionePerTipoWidget> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getProduzionePerTipo(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  static const _colors = [
    Color(0xFFD4A017), Color(0xFF1A6B3C), Color(0xFF8B4513),
    Color(0xFF4A90D9), Color(0xFF9B59B6), Color(0xFF2ECC71),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.pie_chart, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleProduzionePerTipo,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final tipi = (_data?['tipi'] as List?) ?? const [];
    final totale = (_data?['totale_kg'] as num?)?.toDouble() ?? 0.0;

    if (tipi.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s.dashboardProdTipoNessuno)));
    }

    return Row(
      children: [
        IgnorePointer(
          child: SizedBox(
          height: 150,
          width: 150,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(enabled: false),
              sections: tipi.asMap().entries.map((entry) {
                final t = entry.value as Map?;
                final kg = (t?['kg'] as num?)?.toDouble() ?? 0.0;
                final perc = (t?['percentuale'] as num?)?.toDouble() ?? 0.0;
                return PieChartSectionData(
                  value: kg,
                  color: _colors[entry.key % _colors.length],
                  title: '${perc.toStringAsFixed(0)}%',
                  radius: 55,
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                );
              }).toList(),
              centerSpaceRadius: 25,
              sectionsSpace: 2,
            ),
          ),
        ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_s.dashboardProdTipoTotale(totale.toStringAsFixed(1)), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...tipi.asMap().entries.take(6).map((entry) {
                final t = entry.value as Map?;
                final kg = (t?['kg'] as num?)?.toDouble() ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Container(width: 10, height: 10, color: _colors[entry.key % _colors.length]),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t?['tipo_miele']?.toString() ?? 'N/D', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    Text('${kg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
