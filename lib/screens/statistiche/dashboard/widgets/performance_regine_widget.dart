import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class PerformanceRegineWidget extends StatefulWidget {
  final StatisticheService service;
  const PerformanceRegineWidget({super.key, required this.service});

  @override
  State<PerformanceRegineWidget> createState() => _PerformanceRegineWidgetState();
}

class _PerformanceRegineWidgetState extends State<PerformanceRegineWidget> {
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
      final data = await widget.service.getPerformanceRegine(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.star, color: Color(0xFFD4A017)),
      title: _s.dashboardTitlePerformanceRegine,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 180,
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final regine = (_data?['regine'] as List?) ?? const [];
    if (regine.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s.dashboardPerformanceNoRegine)));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
          children: [_s.dashboardPerformanceHdrRegina, _s.dashboardPerformanceHdrProd, _s.dashboardPerformanceHdrDoc, _s.dashboardPerformanceHdrResist, _s.dashboardPerformanceHdrSc]
              .map((h) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                  ))
              .toList(),
        ),
        ...regine.asMap().entries.map((entry) {
          final r = entry.value;
          return TableRow(
            decoration: BoxDecoration(color: entry.key % 2 == 0 ? Colors.white : const Color(0xFFF5F0E8)),
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(r['codice'] ?? 'N/D', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              _scoreCell(r['produttivita']),
              _scoreCell(r['docilita']),
              _scoreCell(r['resistenza_malattie']),
              _scoreCell(r['tendenza_sciamatura']),
            ],
          );
        }),
      ],
    );
  }

  Widget _scoreCell(dynamic val) {
    final v = val is num ? val.toInt() : null;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        v != null ? '$v/5' : '-',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: v == null ? Colors.grey : (v >= 4 ? Colors.green : v >= 3 ? Colors.orange : Colors.red),
        ),
      ),
    );
  }
}
