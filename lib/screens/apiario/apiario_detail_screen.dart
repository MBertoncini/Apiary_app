import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';  // Aggiunto per risolvere l'errore di ApiConstants
import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/qr_generator_widget.dart';
import '../../services/mobile_scanner_service.dart';
import '../../services/qr_pdf_service.dart';
import 'widgets/apiario_map_widget.dart';
import 'apiario_form_screen.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';
import '../../widgets/weather_widget.dart';
import '../../database/dao/controllo_arnia_dao.dart';
import '../../services/controllo_service.dart';

class ApiarioDetailScreen extends StatefulWidget {
  final int apiarioId;
  final bool isCommunity;

  ApiarioDetailScreen({required this.apiarioId, this.isCommunity = false});

  @override
  _ApiarioDetailScreenState createState() => _ApiarioDetailScreenState();
}

class _ApiarioDetailScreenState extends State<ApiarioDetailScreen> with SingleTickerProviderStateMixin {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  bool _isRefreshing = false;
  Map<String, dynamic>? _apiario;
  List<dynamic> _arnie = [];
  List<dynamic> _trattamenti = [];
  List<dynamic> _fioriture = [];
  // Melari attivi per tutte le arnie dell'apiario
  List<dynamic> _melari = [];
  // Ultimo controllo per ciascuna arnia (arniaId → dati grezzi DAO)
  Map<int, Map<String, dynamic>?> _ultimiControlli = {};
  // true quando ApiarioMapWidget è in edit mode → blocca swipe del TabBarView
  bool _mapEditMode = false;

  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Rebuild quando si cambia tab, così il FAB si aggiorna
    _tabController.addListener(() => setState(() {}));
    _loadApiario();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadApiario() async {
    setState(() { _isRefreshing = true; });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Carica dati locali
      final apiari = await storageService.getStoredData('apiari');
      final apiario = apiari.firstWhere(
        (a) => a['id'] == widget.apiarioId,
        orElse: () => null,
      );
      
      if (apiario != null) {
        _apiario = apiario;

        // Carica dati correlati da locale come fallback rapido
        final allArnie = await storageService.getStoredData('arnie');
        _arnie = allArnie.where((a) => a['apiario'] == widget.apiarioId).toList();

        final allTrattamenti = await storageService.getStoredData('trattamenti');
        _trattamenti = allTrattamenti.where((t) => t['apiario'] == widget.apiarioId).toList();

        final allFioriture = await storageService.getStoredData('fioriture');
        _fioriture = allFioriture.where((f) => f['apiario'] == widget.apiarioId).toList();

        // Mostra subito i dati dalla cache (inclusi telaini da SQLite), poi aggiorna dal server
        await _loadUltimiControlli(syncServer: false);
        if (mounted) setState(() {});

        // Aggiorna sempre da server: arnie
        try {
          final arnieData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/arnie/');
          List<dynamic> fetched = [];
          if (arnieData is List) {
            fetched = arnieData;
          } else if (arnieData is Map && arnieData.containsKey('results')) {
            fetched = arnieData['results'] as List;
          }
          if (fetched.isNotEmpty) {
            _arnie = fetched;
            // Aggiorna cache SharedPreferences (merge con arnie di altri apiari)
            _updateArnieCache(storageService, fetched);
          }
        } catch (e) {
          debugPrint('Error fetching arnie from apiario endpoint, trying global: $e');
          // Fallback: endpoint globale filtrato lato client
          try {
            final allArnieData = await apiService.get(ApiConstants.arnieUrl);
            List<dynamic> all = [];
            if (allArnieData is List) {
              all = allArnieData;
            } else if (allArnieData is Map && allArnieData.containsKey('results')) {
              all = allArnieData['results'] as List;
            }
            final filtered = all.where((a) => a['apiario'] == widget.apiarioId).toList();
            if (filtered.isNotEmpty) {
              _arnie = filtered;
              _updateArnieCache(storageService, filtered);
            }
          } catch (e2) {
            debugPrint('Error fetching arnie from global endpoint: $e2');
          }
        }

        try {
          // Usa il filtro ?apiario= supportato dal backend
          final trattamentiData = await apiService.get(
              '${ApiConstants.trattamentiUrl}?apiario=${widget.apiarioId}');
          if (trattamentiData is List) {
            _trattamenti = trattamentiData;
          } else if (trattamentiData is Map &&
              trattamentiData.containsKey('results')) {
            _trattamenti = trattamentiData['results'] as List;
          }
        } catch (e) {
          debugPrint('Error fetching trattamenti from API: $e');
        }

      } else {
        // Se non troviamo l'apiario in locale, prova a caricarlo dal server
        final apiarioData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/');
        _apiario = apiarioData;

        // Carica dati correlati
        final arnieData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/arnie/');
        _arnie = arnieData;

        await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/controlli/');
      }
      
      // Ordina arnie per numero
      _arnie.sort((a, b) => a['numero'].compareTo(b['numero']));

      // Carica melari: prima da cache locale, poi aggiorna dal server
      try {
        final allMelari = await storageService.getStoredData('melari');
        _melari = allMelari
            .where((m) => m['apiario_id'] == widget.apiarioId && m['stato'] == 'posizionato')
            .toList();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error loading melari from cache: $e');
      }
      try {
        final melariData = await apiService.get('${ApiConstants.melariUrl}?apiario_id=${widget.apiarioId}');
        List<dynamic> fetched = [];
        if (melariData is List) {
          fetched = melariData;
        } else if (melariData is Map && melariData.containsKey('results')) {
          fetched = melariData['results'] as List;
        }
        if (fetched.isNotEmpty) {
          _melari = fetched.where((m) => m['stato'] == 'posizionato').toList();
          // Aggiorna cache unendo con melari degli altri apiari
          final allMelari = await storageService.getStoredData('melari');
          final others = allMelari.where((m) => m['apiario_id'] != widget.apiarioId).toList();
          await storageService.saveData('melari', [...others, ...fetched]);
        }
      } catch (e) {
        debugPrint('Error fetching melari from server: $e');
      }

      // Ordina trattamenti per data (più recenti prima)
      _trattamenti.sort((a, b) => b['data_inizio'].compareTo(a['data_inizio']));

      // Ordina fioriture per data (attive prima)
      _fioriture.sort((a, b) {
        if (a['is_active'] == b['is_active']) {
          return b['data_inizio'].compareTo(a['data_inizio']);
        }
        return a['is_active'] ? -1 : 1;
      });

      // Carica l'ultimo controllo per ciascuna arnia (con sync dal server)
      await _loadUltimiControlli(syncServer: true);

    } catch (e) {
      debugPrint('Error loading apiario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.apiarioDetailErrorLoad)),
      );
    } finally {
      setState(() { _isRefreshing = false; });
    }
  }

  Future<void> _loadUltimiControlli({bool syncServer = false}) async {
    final dao = ControlloArniaDao();

    // Sync dal server in parallelo per ogni arnia (usa endpoint arnie/{id}/controlli/)
    if (syncServer && _arnie.isNotEmpty) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final controlloService = ControlloService(apiService);
        await Future.wait(_arnie.map((arnia) {
          final id = arnia['id'] as int?;
          if (id != null) return controlloService.getControlliByArnia(id);
          return Future.value(<Map<String, dynamic>>[]);
        }));
      } catch (e) {
        debugPrint('Error syncing controlli from server: $e');
      }
    }

    final Map<int, Map<String, dynamic>?> map = {};
    for (final arnia in _arnie) {
      final id = arnia['id'] as int?;
      if (id != null) map[id] = await dao.getLatestByArnia(id);
    }
    if (mounted) setState(() => _ultimiControlli = map);
  }

  /// Aggiorna la cache SharedPreferences delle arnie: sostituisce quelle
  /// dell'apiario corrente con [freshArnie] mantenendo le arnie di altri apiari.
  Future<void> _updateArnieCache(StorageService storageService, List<dynamic> freshArnie) async {
    try {
      final allCached = await storageService.getStoredData('arnie');
      final otherApiari = allCached.where((a) => a['apiario'] != widget.apiarioId).toList();
      await storageService.saveData('arnie', [...otherApiari, ...freshArnie]);
    } catch (e) {
      debugPrint('Error updating arnie cache: $e');
    }
  }

  void _navigateToArniaDetail(int arniaId) {
    Navigator.of(context).pushNamed(
      AppConstants.arniaDetailRoute,
      arguments: arniaId,
    ).then((_) => _loadApiario());
  }
  
  void _navigateToArniaCreate() {
    Navigator.of(context).pushNamed(
      AppConstants.creaArniaRoute,
      arguments: widget.apiarioId,
    ).then((_) => _loadApiario());
  }
  
  Widget _buildMeteoTab() {
    if (_apiario == null) return const SizedBox.shrink();

    final lat = _apiario!['latitudine'];
    final lon = _apiario!['longitudine'];
    final nome = _apiario!['nome'] ?? 'Apiario';

    // Monitoraggio meteo disabilitato
    if (_apiario!['monitoraggio_meteo'] == false) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny_outlined, size: 64,
                color: ThemeConstants.textSecondaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_s.apiarioDetailNoMeteo,
                style: TextStyle(
                    color: ThemeConstants.textSecondaryColor, fontSize: 16)),
            const SizedBox(height: 16),
            if (!widget.isCommunity)
              ElevatedButton.icon(
                onPressed: _editApiario,
                icon: const Icon(Icons.settings),
                label: Text(_s.apiarioDetailActivateMeteo),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
              ),
          ],
        ),
      );
    }

    // Coordinate mancanti
    if (lat == null || lon == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64,
                color: ThemeConstants.textSecondaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_s.apiarioDetailNoCoords,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: ThemeConstants.textSecondaryColor, fontSize: 16)),
            const SizedBox(height: 16),
            if (!widget.isCommunity)
              ElevatedButton.icon(
                onPressed: _editApiario,
                icon: const Icon(Icons.edit_location_alt),
                label: Text(_s.apiarioDetailSetCoords),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
              ),
          ],
        ),
      );
    }

    return WeatherWidget(
      latitude: double.parse(lat.toString()),
      longitude: double.parse(lon.toString()),
      locationName: nome,
    );
  }

  void _editApiario() {
    if (_apiario == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApiarioFormScreen(apiario: _apiario),
      ),
    ).then((_) => _loadApiario());
  }

  void _confirmDeleteApiario() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_s.apiarioDetailDeleteTitle),
        content: Text(_s.apiarioDetailDeleteMsg(_apiario?['nome'] ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_s.dialogCancelBtn),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteApiario();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(_s.btnDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApiario() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.delete('${ApiConstants.apiariUrl}${widget.apiarioId}/');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.apiarioDetailDeletedOk)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.apiarioDetailDeleteError(e.toString()))),
      );
    }
  }

  Future<void> _printArnieQrSheet() async {
    if (_apiario == null || _arnie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.apiarioDetailNoPdfArnie)),
      );
      return;
    }
    try {
      await QrPdfService().printQrSheet(apiario: _apiario!, arnie: _arnie);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_s.apiarioDetailPdfError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    if (_apiario == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_s.apiarioDetailLoading)),
        body: const SingleChildScrollView(
          child: Column(
            children: [
              SkeletonDetailHeader(),
              SizedBox(height: 8),
              SkeletonDetailHeader(),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_apiario!['nome']),
        actions: [
          if (!widget.isCommunity) ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _editApiario,
              tooltip: _s.apiarioDetailTooltipEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _confirmDeleteApiario,
              tooltip: _s.apiarioDetailTooltipDelete,
            ),
          ],
          // Pulsante QR: mostra QR apiario + opzione stampa PDF arnie
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: _s.apiarioDetailTooltipQr,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16, 16, 16,
                    16 + MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // QR del singolo apiario
                      QrGeneratorWidget(
                        entity: _apiario!,
                        service: MobileScannerService(),
                      ),
                      if (_arnie.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text(
                              'Stampa foglio QR arnie (${_arnie.length})',
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _printArnieQrSheet();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _s.navArnie),
            Tab(text: _s.apiarioDetailLblTrattamenti),
            Tab(text: _s.apiarioTabMeteo),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: TabBarView(
          controller: _tabController,
          physics: _mapEditMode ? const NeverScrollableScrollPhysics() : null,
          children: [
          // Tab Arnie – mappa interattiva a schermo intero con frame strip integrato
          ApiarioMapWidget(
            arnie: _arnie,
            apiarioId: widget.apiarioId,
            onArniaTap: _navigateToArniaDetail,
            onAddArnia: _navigateToArniaCreate,
            onEditModeChanged: (active) => setState(() => _mapEditMode = active),
            onRefresh: _loadApiario,
            ultimiControlli: _ultimiControlli,
            melariData: _melari,
          ),


          // Tab Trattamenti
          _trattamenti.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _s.apiarioDetailNoTrattamenti,
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!widget.isCommunity)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppConstants.trattamentoCreateRoute,
                              arguments: widget.apiarioId,
                            ).then((_) => _loadApiario());
                          },
                          icon: Icon(Icons.add),
                          label: Text(_s.apiarioDetailAddTrattamento),
                          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!widget.isCommunity)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(_s.apiarioDetailNewTrattamento),
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(
                                    AppConstants.trattamentoCreateRoute,
                                    arguments: widget.apiarioId,
                                  )
                                  .then((_) => _loadApiario()),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _trattamenti.length,
                  itemBuilder: (context, index) {
                    final trattamento = _trattamenti[index];
                    final stato = trattamento['stato'];
                    
                    // Colore in base allo stato
                    Color statusColor;
                    if (stato == 'in_corso') {
                      statusColor = Colors.orange;
                    } else if (stato == 'programmato') {
                      statusColor = Colors.blue;
                    } else if (stato == 'completato') {
                      statusColor = Colors.green;
                    } else {
                      statusColor = Colors.grey;
                    }
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    trattamento['tipo_trattamento_nome'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    stato == 'in_corso'
                                        ? _s.dashStatusInCorso
                                        : stato == 'programmato'
                                            ? _s.dashStatusProgrammato
                                            : stato == 'completato'
                                                ? _s.dashStatusCompletato
                                                : _s.trattamentoStatusAnnullato,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  trattamento['data_fine'] != null
                                      ? _s.dashTrattamentoDates(
                                          trattamento['data_inizio'],
                                          trattamento['data_fine'])
                                      : _s.trattamentiInizio(trattamento['data_inizio']),
                                  style: TextStyle(
                                    color: ThemeConstants.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            
                            if (trattamento['data_fine_sospensione'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _s.trattamentiFineSOSP(trattamento['data_fine_sospensione']),
                                      style: TextStyle(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (trattamento['blocco_covata_attivo'] == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.block,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _s.trattamentoFormBloccoCovataActive,
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            if (trattamento['note'] != null && trattamento['note'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  trattamento['note'],
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    AppConstants.trattamentoDetailRoute,
                                    arguments: trattamento['id'] as int,
                                  ).then((_) => _loadApiario()),
                                  child: Text(_s.apiarioDetailBtnDettagli),
                                ),
                                SizedBox(width: 8),
                                if (stato == 'in_corso' || stato == 'programmato')
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pushNamed(
                                      AppConstants.trattamentoCreateRoute,
                                      arguments: {'trattamentoId': trattamento['id'] as int},
                                    ),
                                    child: Text(_s.btnEdit),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                      ),  // ListView.builder
                    ),    // Expanded
                  ],      // Column children
                ),        // Column

          // Tab Meteo
          _buildMeteoTab(),
        ],
      ),
              ),
            ],
          ),
          // ── pulsante (i) info in basso a sinistra ──────────────
          if (!_mapEditMode)
          Positioned(
            bottom: 84,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'apiario_info',
              onPressed: _showApiarioInfoSheet,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              tooltip: _s.apiarioDetailTooltipInfo,
              child: const Icon(Icons.info_outline),
            ),
          ),
        ],
      ),
      // Sul tab mappa (index 0) lo SpeedDial interno al widget gestisce tutto
      floatingActionButton: _tabController.index == 0
          ? null
          : FloatingActionButton(
              onPressed: _navigateToArniaCreate,
              child: const Icon(Icons.add),
              tooltip: _s.apiarioDetailTooltipAddArnia,
            ),
    );
  }

  void _showApiarioInfoSheet() {
    if (_apiario == null) return;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(_apiario!['nome'] ?? 'Apiario',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _infoRow(Icons.location_on, _s.apiarioDetailInfoPos,
                  _apiario!['posizione'] ?? _s.dashPositionNone),
              if (_apiario!['latitudine'] != null)
                _infoRow(Icons.map, _s.apiarioDetailInfoCoord,
                    'Lat: ${_apiario!['latitudine']}, Long: ${_apiario!['longitudine']}'),
              _infoRow(Icons.wb_sunny, _s.apiarioFormMeteoTitle,
                  (_apiario!['monitoraggio_meteo'] == true)
                      ? _s.apiarioDetailInfoMeteoOn
                      : _s.apiarioDetailInfoMeteoOff),
              _infoRow(Icons.visibility, _s.apiarioDetailInfoVis,
                  _apiario!['visibilita_mappa'] == 'privato'
                      ? _s.apiarioFormVisibOwner
                      : _apiario!['visibilita_mappa'] == 'gruppo'
                          ? _s.apiarioFormVisibGroup
                          : _s.apiarioFormVisibAll),
              _infoRow(Icons.group, _s.apiarioDetailInfoSharing,
                  (_apiario!['condiviso_con_gruppo'] == true)
                      ? _s.apiarioDetailInfoShared
                      : _s.apiarioDetailInfoNotShared),
              if (_apiario!['note'] != null && (_apiario!['note'] as String).isNotEmpty) ...[
                const Divider(height: 24),
                Text(_s.apiarioDetailLblNote,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_apiario!['note']),
              ],
              const Divider(height: 24),
              Text(_s.apiarioDetailLblStatistiche,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip('${_arnie.length}', _s.navArnie, ThemeConstants.primaryColor),
                  _statChip(
                    '${_arnie.where((a) => a['attiva'] == true).length}',
                    _s.labelActive, ThemeConstants.secondaryColor),
                  _statChip(
                    '${_trattamenti.where((t) => t['stato'] == 'in_corso' || t['stato'] == 'programmato').length}',
                    _s.apiarioDetailLblTrattamenti, Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ThemeConstants.textSecondaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: ThemeConstants.textSecondaryColor)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: ThemeConstants.textSecondaryColor)),
      ],
    );
  }
}
