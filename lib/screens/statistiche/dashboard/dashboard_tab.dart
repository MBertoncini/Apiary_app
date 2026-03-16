import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/statistiche_service.dart';
import '../../../services/api_service.dart';
import 'widgets/salute_arnie_widget.dart';
import 'widgets/produzione_widget.dart';
import 'widgets/frequenza_controlli_widget.dart';
import 'widgets/regine_statistiche_widget.dart';
import 'widgets/performance_regine_widget.dart';
import 'widgets/varroa_trend_widget.dart';
import 'widgets/bilancio_widget.dart';
import 'widgets/quote_gruppo_widget.dart';
import 'widgets/fioriture_vicine_widget.dart';
import 'widgets/andamento_scorte_widget.dart';
import 'widgets/produzione_tipo_widget.dart';
import 'widgets/attrezzature_widget.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final StatisticheService _service;
  bool _initialized = false;

  final List<String> _visibleWidgets = [
    'salute_arnie',
    'produzione_annuale',
    'produzione_per_tipo',
    'bilancio_economico',
    'frequenza_controlli',
    'andamento_scorte',
    'regine_statistiche',
    'performance_regine',
    'varroa_trend',
    'fioriture_vicine',
    'quote_gruppo',
    'riepilogo_attrezzature',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _service = StatisticheService(Provider.of<ApiService>(context, listen: false));
      _initialized = true;
    }
  }

  Widget _buildWidgetCard(String widgetId) {
    switch (widgetId) {
      case 'salute_arnie':
        return SaluteArnieWidget(service: _service);
      case 'produzione_annuale':
        return ProduzioneAnnualeWidget(service: _service);
      case 'frequenza_controlli':
        return FrequenzaControlliWidget(service: _service);
      case 'regine_statistiche':
        return RegineStatisticheWidget(service: _service);
      case 'performance_regine':
        return PerformanceRegineWidget(service: _service);
      case 'varroa_trend':
        return VarroaTrendWidget(service: _service);
      case 'bilancio_economico':
        return BilancioWidget(service: _service);
      case 'quote_gruppo':
        return QuoteGruppoWidget(service: _service);
      case 'fioriture_vicine':
        return FioritureVicineWidget(service: _service);
      case 'andamento_scorte':
        return AndamentoScorteWidget(service: _service);
      case 'produzione_per_tipo':
        return ProduzionePerTipoWidget(service: _service);
      case 'riepilogo_attrezzature':
        return AttrezzatureWidget(service: _service);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _visibleWidgets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildWidgetCard(_visibleWidgets[index]),
      ),
    );
  }
}
