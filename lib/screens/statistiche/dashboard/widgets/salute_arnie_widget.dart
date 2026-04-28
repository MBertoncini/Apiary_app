import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class SaluteArnieWidget extends StatefulWidget {
  final StatisticheService service;
  const SaluteArnieWidget({super.key, required this.service});

  @override
  State<SaluteArnieWidget> createState() => _SaluteArnieWidgetState();
}

class _SaluteArnieWidgetState extends State<SaluteArnieWidget> {
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
      final data = await widget.service.getSaluteArnie(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.hive, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleSaluteArnie,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 160,
      headerTrailing: IconButton(
        icon: const Icon(Icons.info_outline, size: 20),
        tooltip: _s.dashboardSaluteInfoTitle,
        onPressed: _showInfoDialog,
      ),
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final ottima = (_data?['ottima'] as num?)?.toInt() ?? 0;
    final attenzione = (_data?['attenzione'] as num?)?.toInt() ?? 0;
    final critica = (_data?['critica'] as num?)?.toInt() ?? 0;
    final totale = (_data?['totale'] as num?)?.toInt() ?? 0;
    final ottime = (_data?['arnie_ottime'] as List?) ?? const [];
    final attenzioneList = (_data?['arnie_attenzione'] as List?) ?? const [];
    final critiche = (_data?['arnie_critiche'] as List?) ?? const [];

    if (totale == 0) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s.dashboardSaluteNoArnie)));
    }

    final entries = <_SaluteEntry>[
      _SaluteEntry(label: _s.dashboardSaluteOttima, color: Colors.green, count: ottima, arnie: ottime),
      _SaluteEntry(label: _s.dashboardSaluteAttenzione, color: Colors.orange, count: attenzione, arnie: attenzioneList),
      _SaluteEntry(label: _s.dashboardSaluteCritica, color: Colors.red, count: critica, arnie: critiche),
    ];
    final visibleEntries = entries.where((e) => e.count > 0).toList();

    return Row(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) return;
                  final idx = response?.touchedSection?.touchedSectionIndex;
                  if (idx == null || idx < 0 || idx >= visibleEntries.length) return;
                  _showArnieList(visibleEntries[idx]);
                },
              ),
              sections: [
                for (final e in visibleEntries)
                  PieChartSectionData(
                    value: e.count.toDouble(),
                    color: e.color,
                    title: '${e.count}',
                    radius: 55,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
              ],
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in entries)
                _LegendItem(
                  color: e.color,
                  label: e.label,
                  valore: e.count,
                  onTap: e.count > 0 ? () => _showArnieList(e) : null,
                ),
              const Divider(),
              Text(_s.dashboardSaluteTotale(totale), style: const TextStyle(fontWeight: FontWeight.w600)),
              if (critiche.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _s.dashboardSaluteCritiche(critiche.map((a) => 'Arnia #${a is Map ? a['numero'] : ''}').join(', ')),
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.dashboardSaluteInfoTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_s.dashboardSaluteInfoIntro),
              const SizedBox(height: 12),
              _InfoRow(color: Colors.green, label: _s.dashboardSaluteOttima, body: _s.dashboardSaluteInfoOttima),
              const SizedBox(height: 8),
              _InfoRow(color: Colors.orange, label: _s.dashboardSaluteAttenzione, body: _s.dashboardSaluteInfoAttenzione),
              const SizedBox(height: 8),
              _InfoRow(color: Colors.red, label: _s.dashboardSaluteCritica, body: _s.dashboardSaluteInfoCritica),
              const SizedBox(height: 12),
              Text(_s.dashboardSaluteInfoSuggerimento, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showArnieList(_SaluteEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 14, height: 14, decoration: BoxDecoration(color: entry.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _s.dashboardSaluteListaTitolo(entry.label),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${entry.count}', style: TextStyle(fontWeight: FontWeight.bold, color: entry.color)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: entry.arnie.isEmpty
                        ? Center(child: Text(_s.dashboardSaluteListaVuota))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: entry.arnie.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final a = entry.arnie[i];
                              if (a is! Map) return const SizedBox.shrink();
                              final numero = a['numero'];
                              final apiario = a['apiario']?.toString() ?? '';
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: entry.color.withValues(alpha: 0.15),
                                  child: Icon(Icons.hive, color: entry.color, size: 20),
                                ),
                                title: Text('Arnia #$numero'),
                                subtitle: apiario.isEmpty
                                    ? null
                                    : Text('${_s.dashboardSaluteApiarioPrefisso} $apiario'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SaluteEntry {
  final String label;
  final Color color;
  final int count;
  final List<dynamic> arnie;
  _SaluteEntry({required this.label, required this.color, required this.count, required this.arnie});
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int valore;
  final VoidCallback? onTap;
  const _LegendItem({required this.color, required this.label, required this.valore, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label),
            const Spacer(),
            Text('$valore', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Color color;
  final String label;
  final String body;
  const _InfoRow({required this.color, required this.label, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
              children: [
                TextSpan(text: '$label — ', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
