import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/melario.dart';
import '../../models/invasettamento.dart';
import '../../models/arnia.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/offline_banner.dart';

class MelariScreen extends StatefulWidget {
  @override
  _MelariScreenState createState() => _MelariScreenState();
}

class _MelariScreenState extends State<MelariScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;

  List<Melario> _melari = [];
  List<Map<String, dynamic>> _smielature = [];
  List<Invasettamento> _invasettamenti = [];
  List<Arnia> _arnie = [];
  bool _isLoading = true;
  bool _isRefreshing = true;
  String? _errorMessage;
  // null = tutti; '' = personali; non-empty = nome gruppo
  String? _filtroGruppo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _refreshAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    _errorMessage = null;

    // Fase 1: cache — mostra subito
    final cached = await Future.wait([
      storageService.getStoredData('melari'),
      storageService.getStoredData('smielature'),
      storageService.getStoredData('invasettamenti'),
      storageService.getStoredData('arnie'),
    ]);
    final hasCache = cached[0].isNotEmpty || cached[3].isNotEmpty;
    if (hasCache) {
      _melari        = cached[0].map((item) => Melario.fromJson(item)).toList();
      _smielature    = cached[1].map((item) => item as Map<String, dynamic>).toList();
      _invasettamenti = cached[2].map((item) => Invasettamento.fromJson(item)).toList();
      _arnie         = cached[3].map((item) => Arnia.fromJson(item)).toList();
      _isLoading = false;
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Fase 2: aggiornamento dal server
    try {
      final results = await Future.wait([
        _apiService.get(ApiConstants.melariUrl),
        _apiService.get(ApiConstants.produzioniUrl),
        _apiService.get(ApiConstants.invasettamentiUrl),
        _apiService.get(ApiConstants.arnieUrl),
      ]);
      final List melariList        = results[0] is List ? results[0] : (results[0]['results'] as List? ?? []);
      final List smielatureList    = results[1] is List ? results[1] : (results[1]['results'] as List? ?? []);
      final List invasettamentiList = results[2] is List ? results[2] : (results[2]['results'] as List? ?? []);
      final List arnieList         = results[3] is List ? results[3] : (results[3]['results'] as List? ?? []);

      _melari        = melariList.map((item) => Melario.fromJson(item)).toList();
      _smielature    = smielatureList.map((item) => item as Map<String, dynamic>).toList();
      _invasettamenti = invasettamentiList.map((item) => Invasettamento.fromJson(item)).toList();
      _arnie         = arnieList.map((item) => Arnia.fromJson(item)).toList();

      final saves = <Future>[];
      if (melariList.isNotEmpty)        saves.add(storageService.saveData('melari', melariList));
      if (smielatureList.isNotEmpty)    saves.add(storageService.saveData('smielature', smielatureList));
      if (invasettamentiList.isNotEmpty) saves.add(storageService.saveData('invasettamenti', invasettamentiList));
      if (arnieList.isNotEmpty)         saves.add(storageService.saveData('arnie', arnieList));
      await Future.wait(saves);
    } catch (e) {
      if (!hasCache) _errorMessage = 'Errore nel caricamento: $e';
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Melari e Produzioni'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.hive, size: 18), text: 'Alveari'),
            Tab(text: 'Smielature'),
            Tab(text: 'Invasettamento'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.melariRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isRefreshing && _melari.isEmpty && _arnie.isEmpty
                ? const SizedBox.shrink()
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            SizedBox(height: 8),
                            ElevatedButton(onPressed: _refreshAll, child: Text('Riprova')),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildVistaAlveariTab(),
                          _buildSmielatureTab(),
                          _buildInvasettamentoTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Builder(builder: (context) {
      final currentTab = _tabController.index;

      if (currentTab == 0) {
        return FloatingActionButton(
          child: Icon(Icons.add),
          tooltip: 'Aggiungi melario',
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.melarioCreateRoute)
                .then((result) { if (result == true) _refreshAll(); });
          },
        );
      } else if (currentTab == 1) {
        return FloatingActionButton(
          child: Icon(Icons.add),
          tooltip: 'Nuova smielatura',
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.smielaturaCreateRoute)
                .then((_) => _refreshAll());
          },
        );
      } else {
        return FloatingActionButton(
          child: Icon(Icons.add),
          tooltip: 'Nuovo invasettamento',
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.invasettamentoCreateRoute)
                .then((_) => _refreshAll());
          },
        );
      }
    });
  }

  // ==================== GROUP FILTER ====================

  /// Collect all unique gruppo names present across melari + smielature + invasettamenti.
  List<String> get _allGruppiNomi {
    final nomi = <String>{};
    for (final m in _melari) {
      if (m.apiarioGruppoNome != null) nomi.add(m.apiarioGruppoNome!);
    }
    for (final s in _smielature) {
      final g = s['apiario_gruppo_nome'] as String?;
      if (g != null) nomi.add(g);
    }
    for (final i in _invasettamenti) {
      if (i.apiarioGruppoNome != null) nomi.add(i.apiarioGruppoNome!);
    }
    return nomi.toList()..sort();
  }

  Widget _buildGruppoFilterBar() {
    final gruppiNomi = _allGruppiNomi;
    if (gruppiNomi.isEmpty) return SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ChoiceChip(
            label: Text('Tutti'),
            selected: _filtroGruppo == null,
            onSelected: (_) => setState(() { _filtroGruppo = null; }),
          ),
          SizedBox(width: 6),
          ChoiceChip(
            label: Text('Personali'),
            selected: _filtroGruppo == '',
            onSelected: (_) => setState(() { _filtroGruppo = ''; }),
          ),
          ...gruppiNomi.map((nome) => Padding(
            padding: EdgeInsets.only(left: 6),
            child: ChoiceChip(
              label: Text(nome),
              selected: _filtroGruppo == nome,
              selectedColor: ThemeConstants.primaryColor.withOpacity(0.25),
              onSelected: (_) => setState(() { _filtroGruppo = nome; }),
            ),
          )),
        ],
      ),
    );
  }

  bool _matchesFiltro(String? gruppoNome) {
    if (_filtroGruppo == null) return true;
    if (_filtroGruppo == '') return gruppoNome == null;
    return gruppoNome == _filtroGruppo;
  }

  // ==================== MELARI TAB ====================

  // ==================== SMIELATURE TAB ====================

  Widget _buildSmielatureTab() {
    final filtered = _smielature
        .where((s) => _matchesFiltro(s['apiario_gruppo_nome'] as String?))
        .toList();

    if (filtered.isEmpty) {
      return Column(children: [
        _buildGruppoFilterBar(),
        Expanded(child: Center(
          child: Text('Nessuna smielatura registrata', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        )),
      ]);
    }

    double totalKg = 0;
    final Map<String, double> byTipo = {};
    for (final s in filtered) {
      final qty = double.tryParse(s['quantita_miele']?.toString() ?? '0') ?? 0;
      totalKg += qty;
      final tipo = s['tipo_miele']?.toString() ?? 'Altro';
      byTipo[tipo] = (byTipo[tipo] ?? 0) + qty;
    }

    return Column(children: [
      _buildGruppoFilterBar(),
      Expanded(child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.local_drink, color: Colors.amber.shade700),
                      SizedBox(width: 8),
                      Text('Riepilogo Produzioni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Totale', '${totalKg.toStringAsFixed(1)} kg'),
                        _buildSummaryItem('Smielature', '${filtered.length}'),
                        _buildSummaryItem('Tipi', '${byTipo.length}'),
                      ],
                    ),
                    if (byTipo.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Divider(),
                      ...byTipo.entries.map((e) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('${e.value.toStringAsFixed(1)} kg'),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ...List.generate(filtered.length, (i) {
              final s = filtered[i];
              final melariCount = (s['melari'] as List?)?.length ?? s['melari_count'] ?? 0;
              final gruppoNome = s['apiario_gruppo_nome'] as String?;
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.local_drink, color: Colors.amber),
                  title: Text('${s['tipo_miele']} - ${s['quantita_miele']} kg'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s['data']} - ${s['apiario_nome']} - $melariCount melari'),
                      if (gruppoNome != null)
                        Row(children: [
                          Icon(Icons.group, size: 11, color: ThemeConstants.primaryColor),
                          SizedBox(width: 3),
                          Text(gruppoNome, style: TextStyle(fontSize: 11, color: ThemeConstants.primaryColor)),
                        ]),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, AppConstants.smielaturaDetailRoute, arguments: s['id'])
                        .then((_) => _refreshAll());
                  },
                ),
              );
            }),
          ],
        ),
      )),
    ]);
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  // ==================== INVASETTAMENTO TAB ====================

  Widget _buildInvasettamentoTab() {
    final filtered = _invasettamenti
        .where((inv) => _matchesFiltro(inv.apiarioGruppoNome))
        .toList();

    if (filtered.isEmpty) {
      return Column(children: [
        _buildGruppoFilterBar(),
        Expanded(child: Center(
          child: Text('Nessun invasettamento registrato', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        )),
      ]);
    }

    // Summary calculations
    final Map<int, int> vasettiPerFormato = {};
    double totalKgInvasettati = 0;
    for (final inv in filtered) {
      vasettiPerFormato[inv.formatoVasetto] = (vasettiPerFormato[inv.formatoVasetto] ?? 0) + inv.numeroVasetti;
      totalKgInvasettati += inv.kgTotali ?? 0;
    }

    // Total kg from smielature for comparison
    double totalKgSmielati = 0;
    for (final s in _smielature) {
      totalKgSmielati += double.tryParse(s['quantita_miele']?.toString() ?? '0') ?? 0;
    }

    return Column(children: [
      _buildGruppoFilterBar(),
      Expanded(child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
          // Summary card
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.teal.shade700),
                      SizedBox(width: 8),
                      Text('Riepilogo Invasettamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItemColored('Invasettato', '${totalKgInvasettati.toStringAsFixed(1)} kg', Colors.teal),
                      _buildSummaryItemColored('Raccolto', '${totalKgSmielati.toStringAsFixed(1)} kg', Colors.amber.shade800),
                    ],
                  ),
                  if (vasettiPerFormato.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Divider(),
                    ...vasettiPerFormato.entries.map((e) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vasetti ${e.key}g', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('${e.value} vasetti'),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Invasettamenti list
          ...List.generate(filtered.length, (i) {
            final inv = filtered[i];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.inventory_2, color: Colors.teal),
                title: Text('${inv.tipoMiele} - ${inv.formatoVasetto}g x${inv.numeroVasetti}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${inv.data} - ${inv.kgTotali?.toStringAsFixed(2) ?? 0} kg${inv.lotto != null ? ' - Lotto: ${inv.lotto}' : ''}'),
                    if (inv.apiarioGruppoNome != null)
                      Row(children: [
                        Icon(Icons.group, size: 11, color: ThemeConstants.primaryColor),
                        SizedBox(width: 3),
                        Text(inv.apiarioGruppoNome!, style: TextStyle(fontSize: 11, color: ThemeConstants.primaryColor)),
                      ]),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    PopupMenuItem(value: 'delete', child: Text('Elimina')),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.pushNamed(context, AppConstants.invasettamentoCreateRoute, arguments: {
                        'id': inv.id,
                        'smielatura': inv.smielatura,
                        'data': inv.data,
                        'tipo_miele': inv.tipoMiele,
                        'formato_vasetto': inv.formatoVasetto,
                        'numero_vasetti': inv.numeroVasetti,
                        'lotto': inv.lotto,
                        'note': inv.note,
                      }).then((_) => _refreshAll());
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Conferma eliminazione'),
                          content: Text('Eliminare questo invasettamento?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ANNULLA')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('ELIMINA')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await _apiService.delete('${ApiConstants.invasettamentiUrl}${inv.id}/');
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invasettamento eliminato')));
                          _refreshAll();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
                        }
                      }
                    }
                  },
                ),
              ),
            );
          }),
        ],
        ),
      )),
    ]);
  }

  Widget _buildSummaryItemColored(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  // ==================== VISTA ALVEARI TAB ====================

  static const double _superW = 140.0;
  static const double _superH = 44.0;
  static const double _nidoH  = 80.0;

  Widget _buildVistaAlveariTab() {
    final activeMelari = _melari
        .where((m) => m.stato == 'posizionato' || m.stato == 'in_smielatura')
        .toList();

    // Group melari by arnia ID
    final Map<int, List<Melario>> melariByArnia = {};
    for (final m in activeMelari) {
      melariByArnia.putIfAbsent(m.arnia, () => []).add(m);
    }

    // Group arnie by apiario
    final Map<int, List<Arnia>> arnieByApiario = {};
    for (final a in _arnie.where((a) => a.attiva)) {
      arnieByApiario.putIfAbsent(a.apiario, () => []).add(a);
    }

    // Collect all apiario IDs (from arnie and from melari)
    final apiarioNomi = <int, String>{};
    for (final m in _melari) {
      apiarioNomi[m.apiarioId] = m.apiarioNome;
    }
    for (final a in _arnie) {
      apiarioNomi[a.apiario] = a.apiarioNome;
    }
    final allApiarioIds = apiarioNomi.keys.toList()..sort();

    if (allApiarioIds.isEmpty) {
      return Center(child: Text('Nessun dato disponibile'));
    }

    final totPosizionati  = _melari.where((m) => m.stato == 'posizionato').length;
    final totInSmielatura = _melari.where((m) => m.stato == 'in_smielatura').length;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHiveStats(totPosizionati, totInSmielatura),
          const SizedBox(height: 12),
          _buildHiveLegend(),
          const SizedBox(height: 16),
          ...allApiarioIds.map((apiarioId) {
            final arnieInApiario = (arnieByApiario[apiarioId] ?? [])
              ..sort((a, b) => a.numero.compareTo(b.numero));

            // Collect arnia IDs that have melari but may not be in _arnie list
            final arniaIdsFromMelari = _melari
                .where((m) => m.apiarioId == apiarioId)
                .map((m) => m.arnia)
                .toSet();
            final arniaIdsFromArnie = arnieInApiario.map((a) => a.id).toSet();
            final extraIds = arniaIdsFromMelari.difference(arniaIdsFromArnie);

            // Build a combined ordered list of Arnia objects
            final arnieToShow = [...arnieInApiario];
            for (final extraId in extraIds) {
              final m = _melari.firstWhere((m) => m.arnia == extraId, orElse: () => _melari.first);
              arnieToShow.add(Arnia(
                id: extraId, apiario: apiarioId, apiarioNome: apiarioNomi[apiarioId] ?? '',
                numero: m.arniaNumero, colore: '', coloreHex: '#F5A623',
                dataInstallazione: '', attiva: true,
              ));
            }
            arnieToShow.sort((a, b) => a.numero.compareTo(b.numero));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apiarioNomi[apiarioId] ?? 'Apiario $apiarioId',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.primaryColor,
                  ),
                ),
                Divider(color: ThemeConstants.primaryColor.withOpacity(0.3)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: arnieToShow.map((arnia) {
                      final melariOnArnia = melariByArnia[arnia.id] ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildHiveCol(arnia, melariOnArnia),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHiveCol(Arnia arnia, List<Melario> melariOnArnia) {
    // Sort: highest posizione at top visually (rendered first in column)
    final activeMelari = melariOnArnia
        .where((m) => m.stato == 'posizionato' || m.stato == 'in_smielatura')
        .toList()
      ..sort((a, b) => b.posizione.compareTo(a.posizione));

    final hasQE = activeMelari.any((m) => m.escludiRegina);

    Color arniaColor;
    try {
      arniaColor = Color(int.parse(arnia.coloreHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      arniaColor = const Color(0xFFF5A623);
    }

    return SizedBox(
      width: _superW + 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Add melario button
          _buildAddSuperBtn(arnia.id),
          const SizedBox(height: 4),
          // Melari stacked
          ...activeMelari.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildMelarioBox(m),
          )),
          // Queen excluder
          if (hasQE) ...[
            _buildQEBar(),
            const SizedBox(height: 2),
          ],
          // Nido
          _buildNidoBox(),
          const SizedBox(height: 3),
          // Base board
          Container(
            width: _superW + 10,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF3D200A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Legs
          SizedBox(
            width: _superW - 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildLeg(), _buildLeg()],
            ),
          ),
          const SizedBox(height: 8),
          // Label
          _buildArniaLabel(arnia.numero, arniaColor, activeMelari.length),
        ],
      ),
    );
  }

  Widget _buildMelarioBox(Melario m) {
    final isPosizionato  = m.stato == 'posizionato';
    final isInSmielatura = m.stato == 'in_smielatura';

    List<Color> gradientColors;
    Color borderColor;
    Color textColor;

    if (isPosizionato) {
      gradientColors = [const Color(0xFFFFCF70), const Color(0xFFF5A623), const Color(0xFFE08C15)];
      borderColor = const Color(0xFFC07A0A);
      textColor   = const Color(0xFF5C3A00);
    } else if (isInSmielatura) {
      gradientColors = [const Color(0xFFFFAF5A), const Color(0xFFFF7A00), const Color(0xFFE06200)];
      borderColor = const Color(0xFFC05000);
      textColor   = Colors.white;
    } else {
      gradientColors = [const Color(0xFFD8EEF5), const Color(0xFFB8D8E8)];
      borderColor = Colors.grey.shade400;
      textColor   = Colors.grey.shade700;
    }

    String tipoLabel;
    switch (m.tipoMelario) {
      case 'tre_quarti': tipoLabel = '3/4'; break;
      case 'meta':       tipoLabel = '1/2'; break;
      default:           tipoLabel = 'Std'; break;
    }

    return GestureDetector(
      onTap: () => _showMelarioBottomSheet(m),
      child: Container(
        width: _superW,
        height: _superH,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
            stops: gradientColors.length == 3 ? const [0.0, 0.55, 1.0] : const [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 2, offset: const Offset(0, 1))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🍯 ${m.numeroTelaini} favi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
                Text('Pos. ${m.posizione} · $tipoLabel',
                    style: TextStyle(fontSize: 9, color: textColor.withOpacity(0.75))),
              ],
            ),
            if (isInSmielatura)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text('Smiel.', style: TextStyle(fontSize: 8, color: textColor)),
              )
            else if (isPosizionato)
              Icon(Icons.touch_app, size: 14, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildQEBar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _superW,
          height: 7,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC8B08A), width: 1),
            borderRadius: BorderRadius.circular(1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: CustomPaint(painter: _QEPainter()),
          ),
        ),
        Positioned(
          right: -26,
          top: -3,
          child: Text('QE',
              style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildNidoBox() {
    return Container(
      width: _superW,
      constraints: const BoxConstraints(minHeight: _nidoH),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA06840), Color(0xFF7A4E2A), Color(0xFF5C3518)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3D200A), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🐝 NIDO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFE4B5).withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeg() {
    return Container(
      width: 10,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF3D200A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
    );
  }

  Widget _buildAddSuperBtn(int arniaId) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppConstants.melarioCreateRoute,
          arguments: {'arniaId': arniaId},
        ).then((result) { if (result == true) _refreshAll(); });
      },
      child: Container(
        width: _superW,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF5A623), width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 14, color: Color(0xFFF5A623)),
            const Text(' Melario',
                style: TextStyle(fontSize: 11, color: Color(0xFFF5A623), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildArniaLabel(int numero, Color color, int melariCount) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('Arnia #$numero',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(
          melariCount == 0
              ? 'nessun melario'
              : '$melariCount melari${melariCount == 1 ? 'o' : 'i'}',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildHiveStats(int posizionati, int inSmielatura) {
    return Row(
      children: [
        Expanded(child: Card(
          color: const Color(0xFFFFF3D0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(children: [
              Text('$posizionati',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF5A623))),
              Text('Posizionati', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ]),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: Card(
          color: const Color(0xFFFFF0E0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(children: [
              Text('$inSmielatura',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF7A00))),
              Text('In smielatura', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ]),
          ),
        )),
      ],
    );
  }

  Widget _buildHiveLegend() {
    return Wrap(
      spacing: 12, runSpacing: 4,
      children: [
        _legendItem(const Color(0xFF7A4E2A), 'Nido'),
        _legendItem(const Color(0xFFF5A623), 'Posizionato'),
        _legendItem(const Color(0xFFFF7A00), 'In smielatura'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  void _showMelarioBottomSheet(Melario m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Melario #${m.id}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${m.numeroTelaini} telaini · Posizione ${m.posizione} · ${_tipoLabel(m.tipoMelario)}'),
            if (m.pesoStimato != null)
              Text('Peso stimato: ${m.pesoStimato!.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            if (m.stato == 'posizionato')
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                title: const Text('Rimuovi melario'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRemoveDialogFromView(m);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Elimina melario'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteFromView(m);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'tre_quarti': return '3/4';
      case 'meta':       return '1/2';
      default:           return 'Standard';
    }
  }

  void _showRemoveDialogFromView(Melario m) {
    final pesoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi melario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confermi di voler rimuovere questo melario?'),
            const SizedBox(height: 16),
            TextField(
              controller: pesoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso stimato (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final peso = double.tryParse(pesoCtrl.text);
                await _apiService.put(
                  '${ApiConstants.melariUrl}${m.id}/',
                  {
                    ...m.toJson(),
                    'stato': 'rimosso',
                    'data_rimozione': DateTime.now().toIso8601String().split('T')[0],
                    if (peso != null) 'peso_stimato': peso,
                  },
                );
                _refreshAll();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
              }
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFromView(Melario m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina melario'),
        content: Text('Eliminare il melario #${m.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.delete('${ApiConstants.melariUrl}${m.id}/');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Melario eliminato')));
                _refreshAll();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
              }
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

class _QEPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0C0A0)
      ..strokeWidth = 3;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += 6;
    }
  }

  @override
  bool shouldRepaint(_QEPainter oldDelegate) => false;
}
