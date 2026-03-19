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
  int _refreshKey = 0;
  bool _preloading = true;

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
      _preloadAll();
    }
  }

  /// Carica tutti i dati in parallelo prima di mostrare la lista.
  /// Così ogni widget trova la cache già popolata al momento della costruzione
  /// → nessuna transizione skeleton→contenuto durante lo scroll → nessun effetto calamita.
  Future<void> _preloadAll() async {
    await Future.wait([
      _service.getSaluteArnie().catchError((_) => <String, dynamic>{}),
      _service.getProduzioneAnnuale().catchError((_) => <String, dynamic>{}),
      _service.getProduzionePerTipo().catchError((_) => <String, dynamic>{}),
      _service.getBilancioEconomico().catchError((_) => <String, dynamic>{}),
      _service.getFrequenzaControlli().catchError((_) => <String, dynamic>{}),
      _service.getAndamentoScorte().catchError((_) => <String, dynamic>{}),
      _service.getRegineStatistiche().catchError((_) => <String, dynamic>{}),
      _service.getPerformanceRegine().catchError((_) => <String, dynamic>{}),
      _service.getVarroaTrend().catchError((_) => <String, dynamic>{}),
      _service.getFioritureVicine().catchError((_) => <String, dynamic>{}),
      _service.getQuoteGruppo().catchError((_) => <String, dynamic>{}),
      _service.getRiepilogoAttrezzature().catchError((_) => <String, dynamic>{}),
    ]);
    if (mounted) setState(() => _preloading = false);
  }

  Widget _buildWidgetCard(String widgetId) {
    final k = ValueKey('$widgetId-$_refreshKey');
    switch (widgetId) {
      case 'salute_arnie':
        return SaluteArnieWidget(key: k, service: _service);
      case 'produzione_annuale':
        return ProduzioneAnnualeWidget(key: k, service: _service);
      case 'frequenza_controlli':
        return FrequenzaControlliWidget(key: k, service: _service);
      case 'regine_statistiche':
        return RegineStatisticheWidget(key: k, service: _service);
      case 'performance_regine':
        return PerformanceRegineWidget(key: k, service: _service);
      case 'varroa_trend':
        return VarroaTrendWidget(key: k, service: _service);
      case 'bilancio_economico':
        return BilancioWidget(key: k, service: _service);
      case 'quote_gruppo':
        return QuoteGruppoWidget(key: k, service: _service);
      case 'fioriture_vicine':
        return FioritureVicineWidget(key: k, service: _service);
      case 'andamento_scorte':
        return AndamentoScorteWidget(key: k, service: _service);
      case 'produzione_per_tipo':
        return ProduzionePerTipoWidget(key: k, service: _service);
      case 'riepilogo_attrezzature':
        return AttrezzatureWidget(key: k, service: _service);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_preloading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () async {
        StatisticheService.clearAllCache();
        await _preloadAll();
        setState(() => _refreshKey++);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _visibleWidgets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildWidgetCard(_visibleWidgets[index]),
      ),
    );
  }
}
