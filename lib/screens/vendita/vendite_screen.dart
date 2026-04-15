import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';
import '../../models/vendita.dart';
import '../../models/cliente.dart';
import '../../models/gruppo.dart';

class VenditeScreen extends StatefulWidget {
  @override
  _VenditeScreenState createState() => _VenditeScreenState();
}

class _VenditeScreenState extends State<VenditeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;
  late StorageService _storageService;
  List<Vendita> _vendite = [];
  List<Cliente> _clienti = [];
  List<Gruppo> _gruppi = [];
  // null = tutti (personali + gruppo), -1 = solo personali, >0 = gruppo specifico
  int? _filtroGruppoId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  static const String _cacheKeyVendite = 'vendite';
  static const String _cacheKeyClienti = 'clienti';

  // Month names now come from l10n: s.monthNames

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { setState(() {}); });
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService     = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _errorMessage = null;

    // Phase 1: cache — read before any setState so skeleton doesn't flash
    final cachedVendite = await _storageService.getStoredData(_cacheKeyVendite);
    final cachedClienti = await _storageService.getStoredData(_cacheKeyClienti);
    if (cachedVendite.isNotEmpty) {
      _vendite = cachedVendite.map((e) => Vendita.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (cachedClienti.isNotEmpty) {
      _clienti = cachedClienti.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (mounted) setState(() { _isLoading = false; _isRefreshing = true; });

    try {
      final results = await Future.wait([
        _apiService.get(ApiConstants.venditeUrl),
        _apiService.get(ApiConstants.clientiUrl),
      ]);
      final venditeList = results[0] is List ? results[0] as List : (results[0]['results'] as List? ?? []);
      final clientiList = results[1] is List ? results[1] as List : (results[1]['results'] as List? ?? []);

      await Future.wait([
        _storageService.saveData(_cacheKeyVendite, venditeList),
        _storageService.saveData(_cacheKeyClienti, clientiList),
      ]);

      // Gruppi fetched separately — failure must not prevent vendite/clienti cache
      List<dynamic> gruppiList = [];
      try {
        final gr = await _apiService.get(ApiConstants.gruppiUrl);
        gruppiList = gr is List ? gr : (gr['results'] as List? ?? []);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _vendite = venditeList.map((e) => Vendita.fromJson(e as Map<String, dynamic>)).toList();
          _clienti = clientiList.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
          _gruppi  = gruppiList.map((e) => Gruppo.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_vendite.isEmpty && _clienti.isEmpty) {
        setState(() { _errorMessage = '${Provider.of<LanguageService>(context, listen: false).strings.qrNavErrorTitle}: $e'; _isLoading = false; _isRefreshing = false; });
      } else {
        setState(() { _isLoading = false; _isRefreshing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Provider.of<LanguageService>(context, listen: false).strings.venditeOfflineMsg)),
        );
      }
    }
  }

  // ── Filtering ────────────────────────────────────────────────────

  List<Vendita> get _venditeFiltered {
    if (_filtroGruppoId == null) return _vendite;
    if (_filtroGruppoId == -1)   return _vendite.where((v) => v.gruppoId == null).toList();
    return _vendite.where((v) => v.gruppoId == _filtroGruppoId).toList();
  }

  List<Cliente> get _clientiFiltered {
    if (_filtroGruppoId == null) return _clienti;
    if (_filtroGruppoId == -1)   return _clienti.where((c) => c.gruppoId == null).toList();
    return _clienti.where((c) => c.gruppoId == _filtroGruppoId).toList();
  }

  Widget _buildGruppoFilterBar() {
    if (_gruppi.isEmpty) return SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(Provider.of<LanguageService>(context, listen: false).strings.labelAll),
            selected: _filtroGruppoId == null,
            onSelected: (_) => setState(() { _filtroGruppoId = null; }),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: Text(Provider.of<LanguageService>(context, listen: false).strings.labelPersonal),
            selected: _filtroGruppoId == -1,
            onSelected: (_) => setState(() { _filtroGruppoId = -1; }),
          ),
          ..._gruppi.map((g) => Padding(
            padding: EdgeInsets.only(left: 6),
            child: ChoiceChip(
              label: Text(g.nome),
              selected: _filtroGruppoId == g.id,
              selectedColor: ThemeConstants.primaryColor.withOpacity(0.25),
              onSelected: (_) => setState(() { _filtroGruppoId = g.id; }),
            ),
          )),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Color _canaleColor(String canale) {
    switch (canale) {
      case 'mercatino': return Colors.orange.shade400;
      case 'negozio':   return Colors.blue.shade400;
      case 'online':    return Colors.purple.shade400;
      case 'privato':   return Colors.green.shade500;
      default:          return Colors.grey.shade500;
    }
  }

  String _canaleLabel(String canale) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final map = {
      'mercatino': s.venditeCanaleMercatino,
      'negozio':   s.venditeCanaleNegozio,
      'online':    s.venditeCanaleOnline,
      'privato':   s.venditeCanalePravato,
      'altro':     s.venditeCanaleAltro,
    };
    return map[canale] ?? canale;
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.venditeTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: s.venditeTabVendite), Tab(text: s.venditeTabClienti)],
        ),
        actions: const [],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.venditeRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isLoading
                ? const SkeletonListView()
                : _errorMessage != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_errorMessage!), const SizedBox(height: 8),
                        ElevatedButton(onPressed: _loadData, child: Text(s.btnRetry)),
                      ]))
                    : TabBarView(
                        controller: _tabController,
                        children: [_buildVenditeTab(), _buildClientiTab()],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: _tabController.index == 0 ? s.venditeFabTooltip : s.venditeClientiFabTooltip,
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.pushNamed(context, AppConstants.venditaCreateRoute).then((_) => _loadData());
          } else {
            Navigator.pushNamed(context, AppConstants.clienteCreateRoute).then((_) => _loadData());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVenditeTab() {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final now = DateTime.now();
    final filtered = _venditeFiltered;
    final meseCorrente = filtered.where((v) {
      final d = DateTime.tryParse(v.data);
      return d != null && d.year == now.year && d.month == now.month;
    }).toList();
    final totaleMese = meseCorrente.fold<double>(0, (sum, v) => sum + (v.totale ?? 0));

    return Column(
      children: [
        _buildGruppoFilterBar(),
        // Summary bar
        Container(
          width: double.infinity,
          color: ThemeConstants.primaryColor.withOpacity(0.12),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.monthNames[now.month - 1]} ${now.year}',
                style: TextStyle(fontWeight: FontWeight.bold, color: ThemeConstants.primaryColor),
              ),
              Text(
                s.venditeBannerSummary(meseCorrente.length, totaleMese.toStringAsFixed(2)),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        if (filtered.isEmpty)
          Expanded(child: Center(child: Text(Provider.of<LanguageService>(context, listen: false).strings.venditeNoVendite, style: const TextStyle(fontSize: 16))))
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final v = filtered[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.pushNamed(
                        context, AppConstants.venditaDetailRoute, arguments: v.id,
                      ).then((_) => _loadData()),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long, color: ThemeConstants.primaryColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.displayName,
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 2),
                                  Text('${v.data}  ·  ${Provider.of<LanguageService>(context, listen: false).strings.venditeArticoli(v.dettagli.length)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  if (v.gruppoNome != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Row(children: [
                                        Icon(Icons.group, size: 11, color: ThemeConstants.primaryColor),
                                        SizedBox(width: 3),
                                        Text(v.gruppoNome!, style: TextStyle(fontSize: 11, color: ThemeConstants.primaryColor)),
                                      ]),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${v.totale?.toStringAsFixed(2) ?? '0.00'} €',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _canaleColor(v.canale),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_canaleLabel(v.canale),
                                      style: TextStyle(fontSize: 11, color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClientiTab() {
    final filtered = _clientiFiltered;
    return Column(
      children: [
        _buildGruppoFilterBar(),
        if (filtered.isEmpty)
          Expanded(child: Center(child: Text(Provider.of<LanguageService>(context, listen: false).strings.venditeNoClienti, style: const TextStyle(fontSize: 16))))
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final c = filtered[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.person, color: ThemeConstants.primaryColor),
                      title: Text(c.nome),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.telefono != null || c.email != null)
                            Text([
                              if (c.telefono != null) c.telefono!,
                              if (c.email != null) c.email!,
                            ].join(' - ')),
                          if (c.gruppoNome != null)
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Row(children: [
                                Icon(Icons.group, size: 12, color: ThemeConstants.primaryColor),
                                SizedBox(width: 4),
                                Text(c.gruppoNome!, style: TextStyle(fontSize: 11, color: ThemeConstants.primaryColor)),
                              ]),
                            ),
                        ],
                      ),
                      trailing: Text(Provider.of<LanguageService>(context, listen: false).strings.venditeClienteVendite(c.venditeCount ?? 0)),
                      onTap: () => Navigator.pushNamed(
                        context, AppConstants.clienteCreateRoute, arguments: c.id,
                      ).then((_) => _loadData()),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
