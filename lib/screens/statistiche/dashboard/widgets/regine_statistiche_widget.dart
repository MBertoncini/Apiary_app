import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class RegineStatisticheWidget extends StatefulWidget {
  final StatisticheService service;
  const RegineStatisticheWidget({super.key, required this.service});

  @override
  State<RegineStatisticheWidget> createState() => _RegineStatisticheWidgetState();
}

class _RegineStatisticheWidgetState extends State<RegineStatisticheWidget> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getRegineStatistiche(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.local_florist, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleRegineStats,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 200,
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final totale = _data!['sostituzioni_totali'] ?? 0;
    final attive = _data!['regine_attive'] ?? 0;
    final durata = _data!['durata_media_mesi'];
    final perMotivo = _data!['per_motivo'] as List;

    return Column(
      children: [
        Row(
          children: [
            _KpiCard(label: _s.dashboardRegineAttive, valore: '$attive', color: Colors.green),
            const SizedBox(width: 8),
            _KpiCard(label: _s.dashboardRegineSostituzioni, valore: '$totale', color: Colors.orange),
            const SizedBox(width: 8),
            _KpiCard(label: _s.dashboardRegineVitaMedia, valore: durata != null ? _s.dashboardRegineVitaMesiStr(durata.toString()) : _s.labelNa, color: Colors.blue),
          ],
        ),
        if (perMotivo.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: Text(_s.dashboardRegineMotiviSostituzione, style: const TextStyle(fontWeight: FontWeight.w600))),
          ...perMotivo.take(5).map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Text(m['motivo'] ?? 'N/D', style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text('${m['count']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          )),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String valore;
  final Color color;
  const _KpiCard({required this.label, required this.valore, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(valore, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
