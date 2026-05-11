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
import '../../widgets/apiario_filter_row.dart';

class ReginaListScreen extends StatefulWidget {
  @override
  _ReginaListScreenState createState() => _ReginaListScreenState();
}

class _ReginaListScreenState extends State<ReginaListScreen> {
  List<dynamic> _apiari = [];
  List<Regina> _regine = [];
  Map<int, int> _arniaToApiario = {};
  Map<int, int> _coloniaToApiario = {};
  
  /// Apiari attualmente selezionati. Vuoto = tutti gli apiari visibili.
  Set<int> _selectedApiari = {};

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Mostra subito la cache (se presente) e poi aggiorna dal server.
  /// Evita di ripartire ogni volta da uno skeleton vuoto.
  Future<void> _bootstrap() async {
    await _loadFromCache();
    await _loadData();
  }

  Future<void> _loadFromCache() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final cachedRegine = await storageService.getStoredData('regine');
    final cachedApiari = await storageService.getStoredData('apiari');
    final cachedArnie = await storageService.getStoredData('arnie');
    final cachedColonie = await storageService.getStoredData('colonie');

    if (!mounted || cachedRegine.isEmpty) return;

    final regine = cachedRegine.map((item) => Regina.fromJson(item)).toList();
    final apiari = List<dynamic>.from(cachedApiari)
      ..sort((a, b) => (a['nome'] as String).compareTo(b['nome'] as String));

    final Map<int, int> arniaToApiario = {};
    for (var a in cachedArnie) {
      if (a['id'] != null && a['apiario'] != null) {
        arniaToApiario[a['id']] = a['apiario'];
      }
    }
    final Map<int, int> coloniaToApiario = {};
    for (var c in cachedColonie) {
      if (c['id'] != null && c['apiario'] != null) {
        coloniaToApiario[c['id']] = c['apiario'];
      }
    }

    setState(() {
      _regine = regine;
      _apiari = apiari;
      _arniaToApiario = arniaToApiario;
      _coloniaToApiario = coloniaToApiario;
      _isLoading = false;
      _pruneSelection();
    });
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
      List<dynamic> regineRaw = const [];
      if (regineResponse is List) {
        regineRaw = regineResponse;
      } else if (regineResponse is Map && regineResponse.containsKey('results')) {
        regineRaw = regineResponse['results'] as List;
      }
      final regine = regineRaw.map((item) => Regina.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _apiari = apiari..sort((a, b) => a['nome'].compareTo(b['nome']));
          _regine = regine;
          _arniaToApiario = arniaToApiario;
          _coloniaToApiario = coloniaToApiario;
          _isLoading = false;
          _isRefreshing = false;
          _isOffline = false;
          _pruneSelection();
        });
      }

      // Salva in cache: usiamo la response originale del server per non perdere
      // i campi che `Regina.toJson` non emette (e per non normalizzare a 0
      // un eventuale `arnia: null` lato server).
      await storageService.saveData('regine', regineRaw);
      await storageService.saveData('apiari', apiari);
      await storageService.saveData('arnie', arnie);
      await storageService.saveData('colonie', colonie);

    } catch (e) {
      debugPrint('Errore caricamento regine: $e');

      if (!mounted) return;
      // Se abbiamo già dati in cache (caricati da _loadFromCache), mostriamo
      // semplicemente offline mode; altrimenti errore.
      setState(() {
        if (_regine.isNotEmpty) {
          _isOffline = true;
        } else {
          _errorMessage = 'Impossibile caricare le regine. Controlla la connessione.';
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// Rimuove dalla selezione apiari che non esistono più dopo il reload.
  void _pruneSelection() {
    final validIds = _apiari.map((a) => a['id'] as int).toSet();
    _selectedApiari = _selectedApiari.intersection(validIds);
  }

  void _toggleApiario(int id) {
    setState(() {
      if (_selectedApiari.contains(id)) {
        _selectedApiari.remove(id);
      } else {
        _selectedApiari.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedApiari.clear();
    });
  }

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  List<Regina> _getFilteredRegine() {
    if (_selectedApiari.isEmpty) return _regine;

    return _regine.where((r) {
      // Prima prova via colonia
      final viaColonia = r.coloniaId != null ? _coloniaToApiario[r.coloniaId] : null;
      if (viaColonia != null) return _selectedApiari.contains(viaColonia);

      // Fallback via arnia
      if (r.arniaId == null) return false;
      final viaArnia = _arniaToApiario[r.arniaId!];
      return viaArnia != null && _selectedApiari.contains(viaArnia);
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
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: ApiarioFilterRow(
                  apiari: _apiari,
                  selected: _selectedApiari,
                  onToggle: _toggleApiario,
                  onSelectAll: _selectAll,
                ),
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
                        : _buildReginaList(_getFilteredRegine()),
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
                s.reginaListItemTitle(regina.arniaNumero ?? regina.arniaId?.toString() ?? '?'),
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
