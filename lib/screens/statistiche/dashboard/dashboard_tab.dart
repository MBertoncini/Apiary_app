import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/statistiche_service.dart';
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
import 'widgets/andamento_covata_widget.dart';
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

  late StatisticheService _service;
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
    'andamento_covata',
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
      _service = context.read<StatisticheService>();
      _initialized = true;
      _preloadAll();
    }
  }

  /// Carica tutti i dati in parallelo prima di mostrare la lista.
  /// Il preload da solo non basta a evitare l'effetto calamita: i widget figli
  /// fanno comunque uno setState(_loading=true) → await → setState(_loading=false)
  /// che mostra lo skeleton per un frame anche con cache hit. Se la ListView è
  /// lazy (.separated/.builder), gli item scrollati fuori vengono distrutti e
  /// quando rientrano nel viewport rifanno il flash skeleton→contenuto con
  /// altezze diverse, spingendo il viewport in basso. Per questo sotto usiamo
  /// `ListView(children: ...)` eager: lo State dei 12 widget viene preservato.
  Future<void> _preloadAll({bool forceRefresh = false}) async {
    // Allinea il preload di quote_gruppo al gruppoId persistito dal widget,
    // così la chiamata centra la stessa cache key e il widget non rifà rete.
    final prefs = await SharedPreferences.getInstance();
    final quoteGruppoId = prefs.getInt(kQuoteGruppoSelectedIdKey);
    await Future.wait([
      _service.getSaluteArnie(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getProduzioneAnnuale(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getProduzionePerTipo(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getBilancioEconomico(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getFrequenzaControlli(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getAndamentoScorte(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getAndamentoCovata(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getRegineStatistiche(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getPerformanceRegine(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getVarroaTrend(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getFioritureVicine(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getQuoteGruppo(gruppoId: quoteGruppoId, forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
      _service.getRiepilogoAttrezzature(forceRefresh: forceRefresh).catchError((_) => <String, dynamic>{}),
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
      case 'andamento_covata':
        return AndamentoCovataWidget(key: k, service: _service);
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
        _service.clearAllCache();
        await _preloadAll(forceRefresh: true);
        setState(() => _refreshKey++);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          for (int i = 0; i < _visibleWidgets.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildWidgetCard(_visibleWidgets[i]),
          ],
        ],
      ),
    );
  }
}
