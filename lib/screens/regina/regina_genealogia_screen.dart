import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/regina.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';
import 'widgets/genealogia_tree_view.dart';

/// Vista albero genealogico delle regine, accessibile dall'icona toggle
/// nell'AppBar di `ReginaListScreen`. Albero unico con filtro dinamico
/// per apiario (multi-selezione fra quelli visibili — propri o di gruppo).
class ReginaGenealogiaScreen extends StatefulWidget {
  const ReginaGenealogiaScreen({Key? key}) : super(key: key);

  @override
  State<ReginaGenealogiaScreen> createState() => _ReginaGenealogiaScreenState();
}

class _ReginaGenealogiaScreenState extends State<ReginaGenealogiaScreen> {
  List<dynamic> _apiari = [];
  List<Regina> _regine = [];
  Map<int, int> _arniaToApiario = {};
  Map<int, int> _coloniaToApiario = {};
  Set<int> _allReginaIds = {};

  /// Apiari attualmente selezionati. Vuoto = tutti gli apiari visibili.
  Set<int> _selectedApiari = {};

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = _regine.isEmpty;
      _isRefreshing = _regine.isNotEmpty;
      _errorMessage = null;
    });

    final storage = Provider.of<StorageService>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);

    try {
      final apiariResp = await api.get(ApiConstants.apiariUrl);
      List<dynamic> apiari = _unwrap(apiariResp);

      final arnieResp = await api.get(ApiConstants.arnieUrl);
      final arnie = _unwrap(arnieResp);
      final arniaToApiario = <int, int>{};
      for (final a in arnie) {
        if (a['id'] != null && a['apiario'] != null) {
          arniaToApiario[a['id']] = a['apiario'];
        }
      }

      final coloniaToApiario = <int, int>{};
      List<dynamic> colonie = [];
      try {
        final colonieResp = await api.get(ApiConstants.colonieUrl);
        colonie = _unwrap(colonieResp);
        for (final c in colonie) {
          if (c['id'] != null && c['apiario'] != null) {
            coloniaToApiario[c['id']] = c['apiario'];
          }
        }
      } catch (_) {}

      final regineResp = await api.get(ApiConstants.regineUrl);
      final regine = _unwrap(regineResp)
          .map((j) => Regina.fromJson(j as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _apiari = apiari
          ..sort((a, b) => (a['nome'] as String).compareTo(b['nome'] as String));
        _regine = regine;
        _arniaToApiario = arniaToApiario;
        _coloniaToApiario = coloniaToApiario;
        _allReginaIds = regine
            .where((r) => r.id != null)
            .map((r) => r.id!)
            .toSet();
        _isLoading = false;
        _isRefreshing = false;
        _isOffline = false;
        _pruneSelection();
      });

      await storage.saveData(
          'regine', regine.map((r) => r.toJson()).toList());
      await storage.saveData('apiari', apiari);
      await storage.saveData('arnie', arnie);
      await storage.saveData('colonie', colonie);
    } catch (e) {
      debugPrint('Errore genealogia regine: $e');
      final cachedRegine = await storage.getStoredData('regine');
      final cachedApiari = await storage.getStoredData('apiari');
      final cachedArnie = await storage.getStoredData('arnie');
      final cachedColonie = await storage.getStoredData('colonie');

      if (!mounted) return;
      setState(() {
        if (cachedRegine.isNotEmpty) {
          _regine = cachedRegine
              .map((j) => Regina.fromJson(j as Map<String, dynamic>))
              .toList();
          _apiari = List<dynamic>.from(cachedApiari)
            ..sort((a, b) =>
                (a['nome'] as String).compareTo(b['nome'] as String));
          final arniaToApiario = <int, int>{};
          for (final a in cachedArnie) {
            if (a['id'] != null && a['apiario'] != null) {
              arniaToApiario[a['id']] = a['apiario'];
            }
          }
          _arniaToApiario = arniaToApiario;
          final coloniaToApiario = <int, int>{};
          for (final c in cachedColonie) {
            if (c['id'] != null && c['apiario'] != null) {
              coloniaToApiario[c['id']] = c['apiario'];
            }
          }
          _coloniaToApiario = coloniaToApiario;
          _allReginaIds =
              _regine.where((r) => r.id != null).map((r) => r.id!).toSet();
          _isOffline = true;
          _pruneSelection();
        } else {
          _errorMessage =
              'Impossibile caricare le regine. Controlla la connessione.';
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

  List<dynamic> _unwrap(dynamic resp) {
    if (resp is List) return resp;
    if (resp is Map && resp.containsKey('results')) {
      return resp['results'] as List;
    }
    return const [];
  }

  int? _apiarioOf(Regina r) {
    final viaColonia =
        r.coloniaId != null ? _coloniaToApiario[r.coloniaId] : null;
    return viaColonia ?? _arniaToApiario[r.arniaId];
  }

  List<Regina> _filteredRegine() {
    if (_selectedApiari.isEmpty) return _regine;
    return _regine.where((r) {
      final apId = _apiarioOf(r);
      return apId != null && _selectedApiari.contains(apId);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    final s = _s;
    final showFilter = !_isLoading && _apiari.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Genealogia'),
            if (_isOffline)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.cloud_off, size: 18, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            icon: const Icon(Icons.sync),
            onPressed: _loadData,
          ),
        ],
        bottom: showFilter
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _ApiarioFilterRow(
                  apiari: _apiari,
                  selected: _selectedApiari,
                  onToggle: _toggleApiario,
                  onSelectAll: _selectAll,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          const _HelpHint(),
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
                        : GenealogiaTreeView(
                            regine: _filteredRegine(),
                            idsKnownGlobally: _allReginaIds,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(s.reginaListEmptyTitle,
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(s.reginaListEmptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _ApiarioFilterRow extends StatelessWidget {
  final List<dynamic> apiari;
  final Set<int> selected;
  final void Function(int) onToggle;
  final VoidCallback onSelectAll;

  const _ApiarioFilterRow({
    required this.apiari,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final allActive = selected.isEmpty;
    return Container(
      height: 52,
      color: ThemeConstants.primaryColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('Tutti'),
              selected: allActive,
              showCheckmark: false,
              onSelected: (_) => onSelectAll(),
              backgroundColor: Colors.white.withOpacity(0.15),
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: allActive
                    ? ThemeConstants.primaryColor
                    : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              side: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ...apiari.map((a) {
            final id = a['id'] as int;
            final isSel = selected.contains(id);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(a['nome'] as String),
                selected: isSel,
                showCheckmark: false,
                onSelected: (_) => onToggle(id),
                backgroundColor: Colors.white.withOpacity(0.15),
                selectedColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSel ? ThemeConstants.primaryColor : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide(color: Colors.white.withOpacity(0.5)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HelpHint extends StatelessWidget {
  const _HelpHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ThemeConstants.primaryColor.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: const Row(
        children: [
          Icon(Icons.touch_app_outlined,
              size: 14, color: ThemeConstants.secondaryColor),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Asse verticale = anno · Tocca un nodo per i dettagli · Pizzica per zoomare',
              style: TextStyle(
                fontSize: 11,
                color: ThemeConstants.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
