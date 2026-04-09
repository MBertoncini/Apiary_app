import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class FrequenzaControlliWidget extends StatefulWidget {
  final StatisticheService service;
  const FrequenzaControlliWidget({super.key, required this.service});

  @override
  State<FrequenzaControlliWidget> createState() => _FrequenzaControlliWidgetState();
}

class _FrequenzaControlliWidgetState extends State<FrequenzaControlliWidget> {
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
      final data = await widget.service.getFrequenzaControlli(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.calendar_today, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleFrequenzaControlli,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 280,
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final media = _data!['media_giorni_tra_controlli'];
    final arnie = _data!['arnie'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (media != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F0E8), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFFD4A017), size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_s.dashboardFrequenzaMedia, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_s.dashboardFrequenzaGiorni((media as num).toInt()), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (arnie.isNotEmpty) ...[
          Text(_s.dashboardFrequenzaDettaglio, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...arnie.take(8).map((a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('Arnia #${a['numero']}', style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text(
                  a['media_intervallo_giorni'] != null ? '${a['media_intervallo_giorni']} gg' : 'N/D',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: a['media_intervallo_giorni'] != null && (a['media_intervallo_giorni'] as num) > 30
                        ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }
}
