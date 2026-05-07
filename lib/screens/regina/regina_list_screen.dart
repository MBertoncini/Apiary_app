import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../models/regina.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/skeleton_widgets.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/beehive_illustrations.dart';

class ReginaListScreen extends StatefulWidget {
  @override
  _ReginaListScreenState createState() => _ReginaListScreenState();
}

class _ReginaListScreenState extends State<ReginaListScreen> with TickerProviderStateMixin {
  List<dynamic> _apiari = [];
  List<Regina> _regine = [];
  Map<int, int> _arniaToApiario = {};
  Map<int, int> _coloniaToApiario = {};
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isOffline = false;
  String? _errorMessage;
  
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = _regine.isEmpty;
      _isRefreshing = _regine.isNotEmpty;
      _errorMessage = null;
    });

    final storageService = Provider.of<StorageService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // 1. Carica Apiari (per i Tab)
      final apiariResponse = await apiService.get(ApiConstants.apiariUrl);
      List<dynamic> apiari = [];
      if (apiariResponse is List) {
        apiari = apiariResponse;
      } else if (apiariResponse is Map && apiariResponse.containsKey('results')) {
        apiari = apiariResponse['results'] as List;
      }
      
      // 2. Carica Arnie (per il mapping regina -> apiario)
      final arnieResponse = await apiService.get(ApiConstants.arnieUrl);
      List<dynamic> arnie = [];
      if (arnieResponse is List) {
        arnie = arnieResponse;
      } else if (arnieResponse is Map && arnieResponse.containsKey('results')) {
        arnie = arnieResponse['results'] as List;
      }
      
      Map<int, int> arniaToApiario = {};
      for (var a in arnie) {
        if (a['id'] != null && a['apiario'] != null) {
          arniaToApiario[a['id']] = a['apiario'];
        }
      }

      // 3. Carica Colonie (per il mapping regina -> apiario via colonia,
      //    necessario quando la colonia vive in un nucleo o quando il payload
      //    Regina non porta più il campo arnia)
      Map<int, int> coloniaToApiario = {};
      List<dynamic> colonie = [];
      try {
        final colonieResponse = await apiService.get(ApiConstants.colonieUrl);
        if (colonieResponse is List) {
          colonie = colonieResponse;
        } else if (colonieResponse is Map && colonieResponse.containsKey('results')) {
          colonie = colonieResponse['results'] as List;
        }
        for (var c in colonie) {
          if (c['id'] != null && c['apiario'] != null) {
            coloniaToApiario[c['id']] = c['apiario'];
          }
        }
      } catch (e) {
        debugPrint('Errore caricamento colonie (uso solo arnia mapping): $e');
      }

      // 4. Carica Regine
      final regineResponse = await apiService.get(ApiConstants.regineUrl);
      List<Regina> regine = [];
      if (regineResponse is List) {
        regine = regineResponse.map((item) => Regina.fromJson(item)).toList();
      } else if (regineResponse is Map && regineResponse.containsKey('results')) {
        regine = (regineResponse['results'] as List).map((item) => Regina.fromJson(item)).toList();
      }

      if (mounted) {
        setState(() {
          _apiari = apiari..sort((a, b) => a['nome'].compareTo(b['nome']));
          _regine = regine;
          _arniaToApiario = arniaToApiario;
          _coloniaToApiario = coloniaToApiario;
          _isLoading = false;
          _isRefreshing = false;
          _isOffline = false;
          
          // Re-inizializza il TabController se il numero di apiari è cambiato
          final oldIndex = _tabController?.index ?? 0;
          _tabController?.dispose();
          _tabController = TabController(
            length: _apiari.length + 1, // +1 per "Tutte"
            vsync: this,
            initialIndex: oldIndex < (_apiari.length + 1) ? oldIndex : 0,
          );
        });
      }

      // Salva in cache
      await storageService.saveData('regine', regine.map((r) => r.toJson()).toList());
      await storageService.saveData('apiari', apiari);
      await storageService.saveData('arnie', arnie);
      await storageService.saveData('colonie', colonie);

    } catch (e) {
      debugPrint('Errore caricamento regine: $e');

      // Fallback cache
      final cachedRegine = await storageService.getStoredData('regine');
      final cachedApiari = await storageService.getStoredData('apiari');
      final cachedArnie = await storageService.getStoredData('arnie');
      final cachedColonie = await storageService.getStoredData('colonie');

      if (mounted) {
        setState(() {
          if (cachedRegine.isNotEmpty) {
            _regine = cachedRegine.map((item) => Regina.fromJson(item)).toList();
            _apiari = List<dynamic>.from(cachedApiari)..sort((a, b) => a['nome'].compareTo(b['nome']));
            
            Map<int, int> arniaToApiario = {};
            for (var a in cachedArnie) {
              if (a['id'] != null && a['apiario'] != null) {
                arniaToApiario[a['id']] = a['apiario'];
              }
            }
            _arniaToApiario = arniaToApiario;

            Map<int, int> coloniaToApiario = {};
            for (var c in cachedColonie) {
              if (c['id'] != null && c['apiario'] != null) {
                coloniaToApiario[c['id']] = c['apiario'];
              }
            }
            _coloniaToApiario = coloniaToApiario;

            _isOffline = true;
            
            _tabController?.dispose();
            _tabController = TabController(
              length: _apiari.length + 1,
              vsync: this,
            );
          } else {
            _errorMessage = 'Impossibile caricare le regine. Controlla la connessione.';
          }
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  List<Regina> _getRegineForApiario(int? apiarioId) {
    if (apiarioId == null) return _regine; // Tutte

    return _regine.where((r) {
      // Prima prova via colonia (sorgente di verità: copre anche le colonie
      // ospitate in nucleo e i payload Regina senza campo arnia)
      final viaColonia = r.coloniaId != null ? _coloniaToApiario[r.coloniaId] : null;
      if (viaColonia != null) return viaColonia == apiarioId;

      // Fallback regine vecchie senza coloniaId
      return _arniaToApiario[r.arniaId] == apiarioId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // Trigger rebuild su cambio lingua
    final s = _s;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(s.reginaListTitle),
            if (_isOffline)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.cloud_off, size: 18, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Albero genealogico',
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamed(AppConstants.reginaGenealogiaRoute),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _loadData,
          ),
        ],
        bottom: _isLoading || _apiari.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'Tutte'),
                  ..._apiari.map((a) => Tab(text: a['nome'])),
                ],
              ),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.reginaListRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isLoading
                ? const SkeletonListView()
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _loadData,
                      )
                    : _apiari.isEmpty && _regine.isEmpty
                        ? _buildEmptyState(s)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildReginaList(_getRegineForApiario(null)),
                              ..._apiari.map((a) => _buildReginaList(_getRegineForApiario(a['id']))),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_florist_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(s.reginaListEmptyTitle, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(s.reginaListEmptySubtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(s.reginaListBtnRetry),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildReginaList(List<Regina> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Nessuna regina in questo apiario',
          style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return ReginaListItem(regina: list[index]);
      },
    );
  }
}

class ReginaListItem extends StatelessWidget {
  final Regina regina;

  const ReginaListItem({Key? key, required this.regina}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    
    final Color reginaColor = reginaInkColorFor(regina.colore);
    final Color avatarBg = (regina.colore == 'bianco' ? Colors.grey : reginaColor).withOpacity(0.2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: regina.sospettaAssente ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: regina.sospettaAssente
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: avatarBg,
          child: HandDrawnQueenBee(size: 35, color: reginaColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.reginaListItemTitle((regina.arniaNumero ?? regina.arniaId.toString()).toString()),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (regina.sospettaAssente)
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${s.reginaListRazza}: ${_getRazzaDisplay(s, regina.razza)}'),
            Text('${s.reginaListOrigine}: ${_getOrigineDisplay(s, regina.origine)}'),
            Text('${s.reginaListIntrodotta}: ${regina.dataInserimento}'),
            if (regina.sospettaAssente)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'SOSPETTA ASSENTE',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (regina.id != null) {
            Navigator.of(context).pushNamed(
              AppConstants.reginaDetailRoute,
              arguments: regina.id,
            );
          }
        },
      ),
    );
  }

  String _getRazzaDisplay(AppStrings s, String razza) {
    switch (razza.toLowerCase()) {
      case 'ligustica':  return 'A. m. ligustica';
      case 'carnica':    return 'A. m. carnica';
      case 'buckfast':   return 'Buckfast';
      case 'caucasica':  return 'A. m. caucasica';
      case 'sicula':     return 'A. m. sicula';
      default:           return razza.isNotEmpty ? razza : s.labelNa;
    }
  }

  String _getOrigineDisplay(AppStrings s, String origine) {
    switch (origine.toLowerCase()) {
      case 'acquistata':  return s.arniaDetailOrigineAcquistata;
      case 'allevata':    return s.arniaDetailOrigineAllevata;
      case 'sciamatura':  return s.arniaDetailOrigineSciamatura;
      case 'emergenza':   return s.arniaDetailOrigineEmergenza;
      case 'sconosciuta': return s.arniaDetailOrigineSconosciuta;
      default:            return origine.isNotEmpty ? origine : s.labelNa;
    }
  }
}
