import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';  // Aggiunto per risolvere l'errore di ApiConstants
import '../../services/api_service.dart';
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
  
  ApiarioDetailScreen({required this.apiarioId});
  
  @override
  _ApiarioDetailScreenState createState() => _ApiarioDetailScreenState();
}

class _ApiarioDetailScreenState extends State<ApiarioDetailScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
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
          if (fetched.isNotEmpty) _arnie = fetched;
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
            if (filtered.isNotEmpty) _arnie = filtered;
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
        SnackBar(content: Text('Errore durante il caricamento dei dati')),
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

  void _navigateToArniaDetail(int arniaId) {
    Navigator.of(context).pushNamed(
      AppConstants.arniaDetailRoute,
      arguments: arniaId,
    );
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
            Text('Monitoraggio meteo non attivato',
                style: TextStyle(
                    color: ThemeConstants.textSecondaryColor, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _editApiario,
              icon: const Icon(Icons.settings),
              label: const Text('Attiva monitoraggio meteo'),
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
            Text('Coordinate non impostate per questo apiario',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: ThemeConstants.textSecondaryColor, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _editApiario,
              icon: const Icon(Icons.edit_location_alt),
              label: const Text('Imposta coordinate'),
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
        title: Text('Elimina Apiario'),
        content: Text(
          'Sei sicuro di voler eliminare "${_apiario?['nome']}"?\n\n'
          'Verranno eliminate anche tutte le arnie, controlli, trattamenti e dati associati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteApiario();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Elimina'),
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
        SnackBar(content: Text('Apiario eliminato con successo')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  Future<void> _printArnieQrSheet() async {
    if (_apiario == null || _arnie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna arnia disponibile per la stampa')),
      );
      return;
    }
    try {
      await QrPdfService().printQrSheet(apiario: _apiario!, arnie: _arnie);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la generazione del PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_apiario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caricamento...')),
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
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editApiario,
            tooltip: 'Modifica apiario',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _confirmDeleteApiario,
            tooltip: 'Elimina apiario',
          ),
          // Pulsante QR: mostra QR apiario + opzione stampa PDF arnie
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'QR Code',
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
            Tab(text: 'Arnie'),
            Tab(text: 'Trattamenti'),
            Tab(text: 'Meteo'),
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
            onNucleoConverted: _loadApiario,
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
                        'Nessun trattamento sanitario registrato',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppConstants.trattamentoCreateRoute,
                            arguments: widget.apiarioId,
                          ).then((_) => _loadApiario());
                        },
                        icon: Icon(Icons.add),
                        label: Text('Aggiungi trattamento'),
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
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nuovo trattamento'),
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
                                        ? 'In corso' 
                                        : stato == 'programmato'
                                            ? 'Programmato'
                                            : stato == 'completato'
                                                ? 'Completato'
                                                : 'Annullato',
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
                                  'Dal ${trattamento['data_inizio']}',
                                  style: TextStyle(
                                    color: ThemeConstants.textSecondaryColor,
                                  ),
                                ),
                                if (trattamento['data_fine'] != null)
                                  Text(
                                    ' al ${trattamento['data_fine']}',
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
                                      'Sospensione fino al ${trattamento['data_fine_sospensione']}',
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
                                      'Blocco covata attivo',
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
                                    AppConstants.trattamentoCreateRoute,
                                    arguments: {'trattamentoId': trattamento['id'] as int},
                                  ),
                                  child: Text('Dettagli'),
                                ),
                                SizedBox(width: 8),
                                if (stato == 'in_corso' || stato == 'programmato')
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pushNamed(
                                      AppConstants.trattamentoCreateRoute,
                                      arguments: {'trattamentoId': trattamento['id'] as int},
                                    ),
                                    child: Text('Modifica'),
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
              tooltip: 'Informazioni apiario',
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
              tooltip: 'Aggiungi arnia',
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
              _infoRow(Icons.location_on, 'Posizione', _apiario!['posizione'] ?? 'Non specificata'),
              if (_apiario!['latitudine'] != null)
                _infoRow(Icons.map, 'Coordinate',
                    'Lat: ${_apiario!['latitudine']}, Long: ${_apiario!['longitudine']}'),
              _infoRow(Icons.wb_sunny, 'Monitoraggio meteo',
                  (_apiario!['monitoraggio_meteo'] == true) ? 'Attivo' : 'Disattivato'),
              _infoRow(Icons.visibility, 'Visibilità mappa',
                  _apiario!['visibilita_mappa'] == 'privato'
                      ? 'Solo proprietario'
                      : _apiario!['visibilita_mappa'] == 'gruppo'
                          ? 'Membri del gruppo'
                          : 'Tutti gli utenti'),
              _infoRow(Icons.group, 'Condivisione gruppi',
                  (_apiario!['condiviso_con_gruppo'] == true)
                      ? 'Condiviso con il gruppo'
                      : 'Non condiviso'),
              if (_apiario!['note'] != null && (_apiario!['note'] as String).isNotEmpty) ...[
                const Divider(height: 24),
                Text('Note', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_apiario!['note']),
              ],
              const Divider(height: 24),
              Text('Statistiche',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip('${_arnie.length}', 'Arnie', ThemeConstants.primaryColor),
                  _statChip(
                    '${_arnie.where((a) => a['attiva'] == true).length}',
                    'Attive', ThemeConstants.secondaryColor),
                  _statChip(
                    '${_trattamenti.where((t) => t['stato'] == 'in_corso' || t['stato'] == 'programmato').length}',
                    'Trattamenti', Colors.orange),
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
