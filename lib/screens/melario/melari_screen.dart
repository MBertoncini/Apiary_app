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
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/offline_banner.dart';
import '../cantina/cantina_screen.dart';
import 'widgets/melari_apiario_mini_map.dart';

class MelariScreen extends StatefulWidget {
  @override
  _MelariScreenState createState() => _MelariScreenState();
}

class _MelariScreenState extends State<MelariScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;
  final GlobalKey<CantinaScreenState> _cantinaKey = GlobalKey<CantinaScreenState>();

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  List<Melario> _melari = [];
  List<Map<String, dynamic>> _smielature = [];
  List<Invasettamento> _invasettamenti = [];
  List<Arnia> _arnie = [];
  // ignore: unused_field
  bool _isLoading = true;
  bool _isRefreshing = true;
  String? _errorMessage;
  // null = tutti; '' = personali; non-empty = nome gruppo
  String? _filtroGruppo;

  // null = tutti gli anni
  int? _selectedYear;

  // Mini-mappa: arnia evidenziata e chiavi per scroll-to
  int? _highlightedArniaId;
  final Map<int, GlobalKey> _arniaColumnKeys = {};
  final Map<int, ScrollController> _apiarioHScrollCtrls = {};

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
    for (final c in _apiarioHScrollCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _scrollToArniaColumn(int arniaId, ScrollController ctrl,
      List<Arnia> orderedArnie) {
    final key = _arniaColumnKeys[arniaId];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.2,
        curve: Curves.easeOut,
      );
      return;
    }
    // Fallback: stima posizione per indice
    final idx = orderedArnie.indexWhere((a) => a.id == arniaId);
    if (idx < 0 || !ctrl.hasClients) return;
    const colWidth = _superW + 20 + 20; // width + right padding
    final target = (idx * colWidth).clamp(0.0, ctrl.position.maxScrollExtent);
    ctrl.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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

    // Fase 2: aggiornamento dal server.
    // IMPORTANTE: usare getAll (segue la paginazione DRF). Senza, con più di
    // 20 melari/arnie l'utente vedeva sparire elementi quando ne aggiungeva
    // un nuovo (l'item finiva fuori dalla finestra dei primi 20).
    try {
      final results = await Future.wait([
        _apiService.getAll(ApiConstants.melariUrl),
        _apiService.getAll(ApiConstants.produzioniUrl),
        _apiService.getAll(ApiConstants.invasettamentiUrl),
        _apiService.getAll(ApiConstants.arnieUrl),
      ]);
      final melariList        = results[0];
      final smielatureList    = results[1];
      final invasettamentiList = results[2];
      final arnieList         = results[3];

      _melari        = melariList.map((item) => Melario.fromJson(item)).toList();
      _smielature    = smielatureList.map((item) => item as Map<String, dynamic>).toList();
      _invasettamenti = invasettamentiList.map((item) => Invasettamento.fromJson(item)).toList();
      _arnie         = arnieList.map((item) => Arnia.fromJson(item)).toList();

      // Salva sempre le liste fetchate (anche se vuote): se l'utente ha
      // eliminato l'ultimo melario, la cache deve riflettere lo stato vuoto
      // e non quello stale.
      await Future.wait([
        storageService.saveData('melari', melariList),
        storageService.saveData('smielature', smielatureList),
        storageService.saveData('invasettamenti', invasettamentiList),
        storageService.saveData('arnie', arnieList),
      ]);
    } catch (e) {
      if (!hasCache) _errorMessage = 'Errore nel caricamento: $e';
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.melariTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.hive, size: 18), text: s.melariTabAlveari),
            Tab(icon: Icon(Icons.local_drink, size: 18), text: s.melariTabSmielature),
            Tab(icon: Icon(Icons.warehouse, size: 18), text: s.melariCantinaTitolo),
          ],
        ),
        actions: [],
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
                            ElevatedButton(onPressed: _refreshAll, child: Text(s.btnRetry)),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildVistaAlveariTab(),
                          _buildSmielatureTab(),
                          CantinaScreen(key: _cantinaKey, embedded: true),
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
          tooltip: _s.melariTooltipAdd,
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.melarioCreateRoute)
                .then((result) { if (result == true) _refreshAll(); });
          },
        );
      } else if (currentTab == 1) {
        return FloatingActionButton.extended(
          icon: Icon(Icons.add),
          label: Text(_s.melariBtnNuovaSmielatura),
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.smielaturaCreateRoute)
                .then((_) => _refreshAll());
          },
        );
      } else {
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(_s.cantinaBtnNuovoMaturatore),
          onPressed: () => _cantinaKey.currentState?.openAddMaturatore(),
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
            label: Text(_s.melariTabTutti),
            selected: _filtroGruppo == null,
            onSelected: (_) => setState(() { _filtroGruppo = null; }),
          ),
          SizedBox(width: 6),
          ChoiceChip(
            label: Text(_s.melariTabPersonali),
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

  List<int> _availableYears() {
    final years = <int>{};
    for (final sm in _smielature) {
      final d = sm['data']?.toString() ?? '';
      if (d.length >= 4) { final y = int.tryParse(d.substring(0, 4)); if (y != null) years.add(y); }
    }
    for (final inv in _invasettamenti) {
      if (inv.data.length >= 4) { final y = int.tryParse(inv.data.substring(0, 4)); if (y != null) years.add(y); }
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  Widget _buildAnnoFilterBar(List<int> years) {
    final s = _s;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(s.melariAnnoTutti),
              selected: _selectedYear == null,
              onSelected: (_) => setState(() => _selectedYear = null),
            ),
          ),
          ...years.map((y) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text('$y'),
              selected: _selectedYear == y,
              onSelected: (_) => setState(() => _selectedYear = y),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSmielatureTab() {
    final years = _availableYears();

    final filteredByGruppo = _smielature
        .where((s) => _matchesFiltro(s['apiario_gruppo_nome'] as String?))
        .toList();

    final filtered = filteredByGruppo.where((s) {
      if (_selectedYear == null) return true;
      final d = s['data']?.toString() ?? '';
      return d.length >= 4 && int.tryParse(d.substring(0, 4)) == _selectedYear;
    }).toList();

    final filteredInv = _invasettamenti.where((inv) {
      if (_selectedYear == null) return true;
      return inv.data.length >= 4 && int.tryParse(inv.data.substring(0, 4)) == _selectedYear;
    }).toList();

    if (filteredByGruppo.isEmpty) {
      return Column(children: [
        _buildGruppoFilterBar(),
        Expanded(child: Center(
          child: Text(_s.melariNoSmielature, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        )),
      ]);
    }

    double totalKg = 0;
    final Map<String, double> byTipo = {};
    for (final sm in filtered) {
      final qty = double.tryParse(sm['quantita_miele']?.toString() ?? '0') ?? 0;
      totalKg += qty;
      final tipo = sm['tipo_miele']?.toString() ?? 'Altro';
      byTipo[tipo] = (byTipo[tipo] ?? 0) + qty;
    }

    // Invasettamenti aggregati per formato
    final Map<int, int> vasettiPerFormato = {};
    int totVasetti = 0;
    for (final inv in filteredInv) {
      vasettiPerFormato[inv.formatoVasetto] = (vasettiPerFormato[inv.formatoVasetto] ?? 0) + inv.numeroVasetti;
      totVasetti += inv.numeroVasetti;
    }
    final sortedFormati = vasettiPerFormato.keys.toList()..sort();

    return Column(children: [
      _buildGruppoFilterBar(),
      if (years.isNotEmpty) _buildAnnoFilterBar(years),
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
                      Text(_s.melariRiepilogoProd, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_selectedYear != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$_selectedYear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(_s.melariSummaryTotale, '${totalKg.toStringAsFixed(1)} kg'),
                        _buildSummaryItem(_s.melariSummarySmielature, '${filtered.length}'),
                        _buildSummaryItem(_s.melariSummaryTipi, '${byTipo.length}'),
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
                    // Sezione vasetti invasettati
                    if (totVasetti > 0) ...[
                      SizedBox(height: 12),
                      Divider(),
                      Row(children: [
                        Icon(Icons.inventory_2, size: 14, color: Colors.teal.shade700),
                        SizedBox(width: 6),
                        Text(_s.melariSummaryVasetti,
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade700)),
                        Spacer(),
                        Text('$totVasetti', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                      ]),
                      SizedBox(height: 4),
                      ...sortedFormati.map((fmt) => Padding(
                        padding: EdgeInsets.only(top: 2, left: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_s.melariSummaryVasettiFormato(fmt, vasettiPerFormato[fmt]!),
                                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ..._buildSmielatureLista(filtered),
          ],
        ),
      )),
    ]);
  }

  // Smielatura "attiva" = ancora con miele residuo e non archiviata.
  // Le esaurite/archiviate finiscono in una sezione "Storico" collassabile,
  // così il flusso operativo resta pulito ma lo storico resta consultabile
  // (e il riepilogo annuale già lo include perché legge tutta `filtered`).
  bool _smielaturaAttiva(Map<String, dynamic> sm) {
    final archiviata = sm['archiviata'] == true;
    final esaurita = sm['is_esaurita'] == true;
    return !archiviata && !esaurita;
  }

  List<Widget> _buildSmielatureLista(List<Map<String, dynamic>> filtered) {
    final attive = filtered.where(_smielaturaAttiva).toList();
    final storico = filtered.where((s) => !_smielaturaAttiva(s)).toList();
    if (filtered.isEmpty) {
      return [
        Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(_s.melariNoSmielature, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        )),
      ];
    }
    return [
      if (attive.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_s.melariNoSmielatureAttive,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
        )
      else
        ...attive.map(_buildSmielaturaCard),
      if (storico.isNotEmpty) _buildStoricoSmielature(storico),
    ];
  }

  Widget _buildSmielaturaCard(Map<String, dynamic> sm) {
    final melariCount = (sm['melari'] as List?)?.length ?? sm['melari_count'] ?? 0;
    final gruppoNome = sm['apiario_gruppo_nome'] as String?;
    final residui = double.tryParse(sm['kg_residui']?.toString() ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.local_drink, color: Colors.amber),
        title: Text(_s.melariSmielaturaItem(
            sm['tipo_miele']?.toString() ?? '',
            sm['quantita_miele']?.toString() ?? '0')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_s.melariSmielaturaSubtitle(
                sm['data']?.toString() ?? '',
                sm['apiario_nome']?.toString() ?? '',
                melariCount)),
            if (residui != null && residui > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(_s.melariSmielaturaResidui(residui.toStringAsFixed(1)),
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
              ),
            if (gruppoNome != null)
              Row(children: [
                Icon(Icons.group, size: 11, color: ThemeConstants.primaryColor),
                const SizedBox(width: 3),
                Text(gruppoNome, style: TextStyle(fontSize: 11, color: ThemeConstants.primaryColor)),
              ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            PopupMenuItem(value: 'open', child: Text(_s.melariMenuApri)),
            PopupMenuItem(value: 'archivia', child: Text(_s.melariMenuArchivia)),
          ],
          onSelected: (v) {
            if (v == 'open') {
              Navigator.pushNamed(context, AppConstants.smielaturaDetailRoute, arguments: sm['id'])
                  .then((_) => _refreshAll());
            } else if (v == 'archivia') {
              _archiviaSmielatura(sm['id'] as int, true);
            }
          },
        ),
        onTap: () {
          Navigator.pushNamed(context, AppConstants.smielaturaDetailRoute, arguments: sm['id'])
              .then((_) => _refreshAll());
        },
      ),
    );
  }

  Widget _buildStoricoSmielature(List<Map<String, dynamic>> storico) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(children: [
          Text(_s.melariStoricoSmielature,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${storico.length}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ),
        ]),
        children: storico.map((sm) {
          final archiviata = sm['archiviata'] == true;
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            color: Colors.grey.shade50,
            child: ListTile(
              dense: true,
              leading: Icon(
                archiviata ? Icons.archive : Icons.check_circle,
                color: archiviata ? Colors.grey : Colors.green.shade600,
                size: 20,
              ),
              title: Text(
                _s.melariSmielaturaItem(
                    sm['tipo_miele']?.toString() ?? '',
                    sm['quantita_miele']?.toString() ?? '0'),
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                _s.melariSmielaturaSubtitle(
                    sm['data']?.toString() ?? '',
                    sm['apiario_nome']?.toString() ?? '',
                    (sm['melari'] as List?)?.length ?? 0),
                style: const TextStyle(fontSize: 11),
              ),
              trailing: archiviata
                  ? IconButton(
                      icon: const Icon(Icons.unarchive, size: 20),
                      tooltip: _s.melariMenuRipristina,
                      onPressed: () => _archiviaSmielatura(sm['id'] as int, false),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, AppConstants.smielaturaDetailRoute, arguments: sm['id'])
                    .then((_) => _refreshAll());
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _archiviaSmielatura(int id, bool archiviata) async {
    try {
      await _apiService.post(
        '${ApiConstants.produzioniUrl}$id/archivia/',
        {'archiviata': archiviata},
      );
      // Patch ottimistico cache locale per coerenza UI immediata
      final idx = _smielature.indexWhere((s) => s['id'] == id);
      if (idx != -1) {
        setState(() {
          _smielature[idx] = {..._smielature[idx], 'archiviata': archiviata};
        });
      }
      _refreshAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.msgErrorGeneric(e.toString()))),
      );
    }
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

  // ignore: unused_element
  Widget _buildInvasettamentoTab() {
    final filtered = _invasettamenti
        .where((inv) => _matchesFiltro(inv.apiarioGruppoNome))
        .toList();

    if (filtered.isEmpty) {
      return Column(children: [
        _buildGruppoFilterBar(),
        Expanded(child: Center(
          child: Text(_s.melariNoInvasettamento, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
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
                      Text(_s.melariRiepilogoInvasettamento, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItemColored(_s.melariSummaryInvasettato, '${totalKgInvasettati.toStringAsFixed(1)} kg', Colors.teal),
                      _buildSummaryItemColored(_s.melariSummaryRaccolto, '${totalKgSmielati.toStringAsFixed(1)} kg', Colors.amber.shade800),
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
                          Text(_s.melariVasettiLabel(e.key.toString()), style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('${e.value} ${_s.melariVasetti}'),
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
                title: Text(_s.melariInvasettamentoItem(inv.tipoMiele, inv.formatoVasetto.toString(), inv.numeroVasetti)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_s.melariInvasettamentoSubtitle(inv.data, inv.kgTotali?.toStringAsFixed(2) ?? '0', inv.lotto)),
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
                    PopupMenuItem(value: 'edit', child: Text(_s.melariMenuEdit)),
                    PopupMenuItem(value: 'delete', child: Text(_s.melariMenuDelete)),
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
                          title: Text(_s.melariDeleteInvasettTitle),
                          content: Text(_s.melariDeleteInvasettMsg),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_s.dialogCancelBtn)),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_s.btnDeleteCaps)),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await _apiService.delete('${ApiConstants.invasettamentiUrl}${inv.id}/');
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.melariDeleteInvasettOk)));
                          _refreshAll();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.melariDeleteInvasettError(e.toString()))));
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
      if (m.arnia != null) {
        melariByArnia.putIfAbsent(m.arnia!, () => []).add(m);
      }
    }

    // Group arnie by apiario
    final Map<int, List<Arnia>> arnieByApiario = {};
    for (final a in _arnie.where((a) => a.attiva)) {
      arnieByApiario.putIfAbsent(a.apiario, () => []).add(a);
    }

    // Collect all apiario IDs (from arnie and from melari)
    final apiarioNomi = <int, String>{};
    for (final m in _melari) {
      if (m.apiarioId != null) apiarioNomi[m.apiarioId!] = m.apiarioNome ?? '';
    }
    for (final a in _arnie) {
      apiarioNomi[a.apiario] = a.apiarioNome;
    }
    final allApiarioIds = apiarioNomi.keys.toList()..sort();

    if (allApiarioIds.isEmpty) {
      return Center(child: Text(_s.melariNoData));
    }

    final totPosizionati = _melari.where((m) => m.stato == 'posizionato').length;
    // "Da smielare": melari rimossi dall'arnia oppure (per dati storici)
    // esplicitamente messi in coda di smielatura. Sono i candidati per la
    // prossima Smielatura nel form dedicato.
    final totDaSmielare = _melari
        .where((m) => m.stato == 'rimosso' || m.stato == 'in_smielatura')
        .length;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHiveStats(totPosizionati, totDaSmielare),
          const SizedBox(height: 12),
          _buildHiveLegend(),
          const SizedBox(height: 16),
          ...allApiarioIds.map((apiarioId) {
            final arnieInApiario = (arnieByApiario[apiarioId] ?? [])
              ..sort((a, b) => a.numero.compareTo(b.numero));

            // Collect arnia IDs that have melari but may not be in _arnie list
            final arniaIdsFromMelari = _melari
                .where((m) => m.apiarioId == apiarioId && m.arnia != null)
                .map((m) => m.arnia!)
                .toSet();
            final arniaIdsFromArnie = arnieInApiario.map((a) => a.id).toSet();
            final extraIds = arniaIdsFromMelari.difference(arniaIdsFromArnie);

            // Build a combined ordered list of Arnia objects
            final arnieToShow = [...arnieInApiario];
            for (final extraId in extraIds) {
              final melariForId = _melari.where((m) => m.arnia == extraId);
              if (melariForId.isEmpty) continue;
              final m = melariForId.first;
              arnieToShow.add(Arnia(
                id: extraId, apiario: apiarioId, apiarioNome: apiarioNomi[apiarioId] ?? '',
                numero: m.arniaNumero ?? 0, colore: '', coloreHex: '#F5A623',
                dataInstallazione: '', attiva: true,
              ));
            }
            arnieToShow.sort((a, b) => a.numero.compareTo(b.numero));

            final hScrollCtrl = _apiarioHScrollCtrls.putIfAbsent(
                apiarioId, () => ScrollController());
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
                MelariApiarioMiniMap(
                  apiarioId: apiarioId,
                  arnie: arnieToShow,
                  melariByArnia: melariByArnia,
                  highlightedArniaId: _highlightedArniaId != null &&
                          arnieToShow.any((a) => a.id == _highlightedArniaId)
                      ? _highlightedArniaId
                      : null,
                  onArniaTap: (id) {
                    setState(() => _highlightedArniaId = id);
                    _scrollToArniaColumn(id, hScrollCtrl, arnieToShow);
                  },
                ),
                SingleChildScrollView(
                  controller: hScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: arnieToShow.map((arnia) {
                      final melariOnArnia = melariByArnia[arnia.id] ?? [];
                      final key = _arniaColumnKeys.putIfAbsent(
                          arnia.id, () => GlobalKey());
                      return Padding(
                        key: key,
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildHiveCol(arnia, melariOnArnia, apiarioId),
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

  Widget _buildHiveCol(Arnia arnia, List<Melario> melariOnArnia, int apiarioId) {
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

    final isHighlighted = _highlightedArniaId == arnia.id;

    // DragTarget di colonna: cattura i drop su spazio "vuoto" della colonna
    // (non sopra a un altro melario), gestendo lo spostamento in arnia anche
    // quando l'arnia di destinazione non ha melari.
    return DragTarget<Melario>(
      onWillAcceptWithDetails: (details) =>
          details.data.arnia != arnia.id &&
          details.data.stato == 'posizionato',
      onAcceptWithDetails: (details) =>
          _moveMelarioToArnia(details.data, arnia.id, apiarioId),
      builder: (ctx, candidates, rejected) {
        final isDragOver = candidates.isNotEmpty;
        return GestureDetector(
          onTap: () => setState(() {
            _highlightedArniaId =
                _highlightedArniaId == arnia.id ? null : arnia.id;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _superW + 20,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDragOver
                  ? ThemeConstants.primaryColor.withOpacity(0.18)
                  : isHighlighted
                      ? ThemeConstants.primaryColor.withOpacity(0.10)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isDragOver
                  ? Border.all(
                      color: ThemeConstants.primaryColor,
                      width: 2,
                      style: BorderStyle.solid)
                  : isHighlighted
                      ? Border.all(
                          color: ThemeConstants.primaryColor, width: 1.6)
                      : Border.all(color: Colors.transparent, width: 1.6),
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Add melario button
            _buildAddSuperBtn(arnia.id, apiarioId),
            const SizedBox(height: 4),
            // Melari impilati: long-press per trascinare e scambiare con un
            // altro melario (stessa arnia → swap posizione; arnia diversa →
            // swap arnia + posizione).
            Column(
              mainAxisSize: MainAxisSize.min,
              children: activeMelari
                  .map((m) => Padding(
                        key: ValueKey('melario-${m.id}'),
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _buildDraggableMelario(m),
                      ))
                  .toList(),
            ),
            // Queen excluder
            if (hasQE) ...[
              _buildQEBar(),
              const SizedBox(height: 2),
            ],
            // Nido
            _buildNidoBox(arniaColor),
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
            _buildArniaLabel(arnia.numero, activeMelari.length),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableMelario(Melario m) {
    final box = _buildMelarioBox(m);
    // Solo i melari "posizionato" possono essere trascinati per lo swap;
    // quelli in_smielatura sono mostrati ma non spostabili.
    final canDrag = m.stato == 'posizionato';
    final draggableChild = canDrag
        ? LongPressDraggable<Melario>(
            data: m,
            delay: const Duration(milliseconds: 250),
            feedback: Material(
              color: Colors.transparent,
              elevation: 4,
              child: Opacity(opacity: 0.9, child: box),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: box),
            child: box,
          )
        : box;
    return DragTarget<Melario>(
      onWillAcceptWithDetails: (details) =>
          details.data.id != m.id && canDrag,
      onAcceptWithDetails: (details) => _swapMelari(details.data, m),
      builder: (ctx, candidates, rejected) {
        if (candidates.isNotEmpty) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: ThemeConstants.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: draggableChild,
          );
        }
        return draggableChild;
      },
    );
  }

  Future<void> _swapMelari(Melario a, Melario b) async {
    if (a.id == b.id) return;

    // Risolvi le colonie di destinazione PRIMA dell'aggiornamento ottimistico:
    // se serve uno spostamento di arnia ma la colonia non è ricavabile, è
    // meglio bloccare subito che dover fare rollback.
    int? coloniaForA = b.colonia ?? b.coloniaId;
    int? coloniaForB = a.colonia ?? a.coloniaId;
    if (a.arnia != b.arnia) {
      coloniaForA ??= await _resolveColoniaForArnia(b.arnia ?? -1);
      coloniaForB ??= await _resolveColoniaForArnia(a.arnia ?? -1);
      if (coloniaForA == null || coloniaForB == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
                'Impossibile scambiare i melari: nessuna colonia attiva sull\'arnia di destinazione.')),
          );
        }
        return;
      }
    }

    // Calcola nuovi valori (swap di posizione e di colonia/arnia).
    final newA = a.copyWith(
      posizione: b.posizione,
      colonia: coloniaForA,
      coloniaId: coloniaForA,
      arnia: b.arnia,
      arniaNumero: b.arniaNumero,
      apiarioId: b.apiarioId,
      apiarioNome: b.apiarioNome,
      apiarioGruppoNome: b.apiarioGruppoNome,
    );
    final newB = b.copyWith(
      posizione: a.posizione,
      colonia: coloniaForB,
      coloniaId: coloniaForB,
      arnia: a.arnia,
      arniaNumero: a.arniaNumero,
      apiarioId: a.apiarioId,
      apiarioNome: a.apiarioNome,
      apiarioGruppoNome: a.apiarioGruppoNome,
    );

    // Snapshot per rollback
    final snapshot = List<Melario>.from(_melari);
    final storageService = Provider.of<StorageService>(context, listen: false);

    // Aggiornamento ottimistico
    setState(() {
      final idxA = _melari.indexWhere((x) => x.id == a.id);
      final idxB = _melari.indexWhere((x) => x.id == b.id);
      if (idxA != -1) _melari[idxA] = newA;
      if (idxB != -1) _melari[idxB] = newB;
    });

    try {
      // Una sola PATCH per melario: il backend non ha unique constraint su
      // (colonia, posizione), quindi non serve il "parcheggio" temporaneo.
      await Future.wait([
        _apiService.patch(
          '${ApiConstants.melariUrl}${a.id}/',
          {
            if (coloniaForA != null) 'colonia': coloniaForA,
            'posizione': newA.posizione,
          },
        ),
        _apiService.patch(
          '${ApiConstants.melariUrl}${b.id}/',
          {
            if (coloniaForB != null) 'colonia': coloniaForB,
            'posizione': newB.posizione,
          },
        ),
      ]);

      await storageService.saveData(
          'melari', _melari.map((m) => m.toJson()).toList());
    } catch (e) {
      debugPrint('Errore swap melari: $e');
      if (mounted) {
        setState(() => _melari = snapshot);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nello swap dei melari: $e')),
        );
        _refreshAll();
      }
    }
  }

  Future<int?> _resolveColoniaForArnia(int arniaId) async {
    // Prima prova a leggerla dai melari già caricati su quella arnia.
    for (final m in _melari) {
      if (m.arnia == arniaId && (m.colonia ?? m.coloniaId) != null) {
        return m.colonia ?? m.coloniaId;
      }
    }
    try {
      final res = await _apiService
          .get('${ApiConstants.arnieUrl}$arniaId/colonia_attiva/');
      if (res is Map<String, dynamic>) return res['id'] as int?;
    } catch (_) {}
    return null;
  }

  Future<void> _moveMelarioToArnia(
      Melario m, int destArniaId, int destApiarioId) async {
    if (m.arnia == destArniaId) return;

    // Calcola la prossima posizione libera sulla destinazione: stessa regola
    // del form (prima posizione libera dal basso). In assenza di buchi cade
    // su max+1, quindi resta coerente con "aggiungi in cima allo stack".
    final occupiedOnDest = <int>{};
    for (final x in _melari) {
      if (x.arnia == destArniaId &&
          (x.stato == 'posizionato' || x.stato == 'in_smielatura')) {
        occupiedOnDest.add(x.posizione);
      }
    }
    int newPos = 1;
    while (occupiedOnDest.contains(newPos)) {
      newPos++;
    }

    final destColonia = await _resolveColoniaForArnia(destArniaId);
    if (destColonia == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Impossibile spostare: nessuna colonia attiva sull\'arnia di destinazione.')),
        );
      }
      return;
    }

    // Recupera nome arnia/apiario di destinazione (best-effort) dal cache locale.
    final destArnia = _arnie.firstWhere(
      (a) => a.id == destArniaId,
      orElse: () => Arnia(
        id: destArniaId,
        apiario: destApiarioId,
        apiarioNome: '',
        numero: 0,
        colore: '',
        coloreHex: '#F5A623',
        dataInstallazione: '',
        attiva: true,
      ),
    );

    final snapshot = List<Melario>.from(_melari);
    final storageService = Provider.of<StorageService>(context, listen: false);

    setState(() {
      final idx = _melari.indexWhere((x) => x.id == m.id);
      if (idx != -1) {
        _melari[idx] = m.copyWith(
          colonia: destColonia,
          coloniaId: destColonia,
          arnia: destArniaId,
          arniaNumero: destArnia.numero,
          apiarioId: destApiarioId,
          apiarioNome: destArnia.apiarioNome,
          posizione: newPos,
        );
      }
    });

    try {
      await _apiService.patch(
        '${ApiConstants.melariUrl}${m.id}/',
        {'colonia': destColonia, 'posizione': newPos},
      );
      await storageService.saveData(
          'melari', _melari.map((x) => x.toJson()).toList());
    } catch (e) {
      debugPrint('Errore spostamento melario: $e');
      if (mounted) {
        setState(() => _melari = snapshot);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nello spostamento del melario: $e')),
        );
        _refreshAll();
      }
    }
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
                Text(_s.melariFaviLabel(m.numeroTelaini),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
                Text(_s.melariPosTipoLabel(m.posizione, tipoLabel),
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
              Icon(Icons.drag_indicator, size: 14, color: textColor.withOpacity(0.55)),
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

  Widget _buildNidoBox(Color arniaColor) {
    return Container(
      width: _superW,
      constraints: const BoxConstraints(minHeight: _nidoH),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(Colors.white.withOpacity(0.2), arniaColor),
            arniaColor,
            Color.alphaBlend(Colors.black.withOpacity(0.2), arniaColor),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Color.alphaBlend(Colors.black.withOpacity(0.4), arniaColor),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _s.melariHiveLblNido,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: arniaColor.computeLuminance() > 0.5
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.8),
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

  Widget _buildAddSuperBtn(int arniaId, int apiarioId) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppConstants.melarioCreateRoute,
          arguments: {'arniaId': arniaId, 'apiarioId': apiarioId},
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
            Text(' ${_s.melariMelarioLabel}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFF5A623), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildArniaLabel(int numero, int melariCount) {
    return Column(
      children: [
        Text(_s.melariArniaNumLabel(numero),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(
          melariCount == 0 ? _s.melariNoMelari : _s.melariCountMelari(melariCount),
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildHiveStats(int posizionati, int daSmielare) {
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
              Text(_s.melariPosizionati, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
              Text('$daSmielare',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF7A00))),
              Text(_s.melariInSmielatura, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
        _legendItem(Colors.blueGrey.shade300, _s.melariHiveLegendNido),
        _legendItem(const Color(0xFFF5A623), _s.melariHiveLegendPosizionato),
        _legendItem(const Color(0xFFFF7A00), _s.melariHiveLegendInSmielatura),
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
    final dataPos = DateTime.tryParse(m.dataPosizionamento);
    final dataPosFmt = dataPos != null
        ? '${dataPos.day.toString().padLeft(2, "0")}/${dataPos.month.toString().padLeft(2, "0")}/${dataPos.year}'
        : m.dataPosizionamento;
    final giorni = dataPos != null
        ? DateTime.now().difference(dataPos).inDays
        : null;
    final statoLabel = _statoMelarioLabel(m.stato);
    final faviLabel = m.statoFavi == 'fogli_cerei' ? 'Fogli cerei' : 'Già costruiti';

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: m.stato == 'in_smielatura'
                          ? const Color(0xFFFF7A00)
                          : const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.layers, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_s.melariMelarioId(m.id),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (m.arniaNumero != null)
                          Text('Arnia ${m.arniaNumero}'
                              '${m.apiarioNome != null ? " · ${m.apiarioNome}" : ""}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(statoLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _infoRow(Icons.calendar_today, 'Data posizionamento', dataPosFmt),
              if (giorni != null)
                _infoRow(Icons.timelapse, 'Giorni in arnia',
                    giorni == 0 ? 'oggi' : (giorni == 1 ? '1 giorno' : '$giorni giorni')),
              _infoRow(Icons.view_week, 'Telaini', '${m.numeroTelaini}'),
              _infoRow(Icons.layers, 'Posizione', '${m.posizione}°'),
              _infoRow(Icons.grid_on, 'Tipo', _tipoLabel(m.tipoMelario)),
              _infoRow(Icons.style, 'Stato favi', faviLabel),
              _infoRow(Icons.block, 'Escludi regina', m.escludiRegina ? 'Sì' : 'No'),
              if (m.pesoStimato != null)
                _infoRow(Icons.scale, 'Peso stimato',
                    '${m.pesoStimato!.toStringAsFixed(1)} kg'),
              if (m.note != null && m.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(m.note!),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              if (m.stato == 'posizionato' || m.stato == 'in_smielatura')
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit, color: Colors.indigo),
                  title: Text(_s.melariMenuEdit),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context)
                        .pushNamed(AppConstants.melarioCreateRoute,
                            arguments: {'editingMelario': m})
                        .then((result) { if (result == true) _refreshAll(); });
                  },
                ),
              if (m.stato == 'posizionato')
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                  title: Text(_s.melariRemoveMelarioTitle),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRemoveDialogFromView(m);
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(_s.melariEliminaMelarioTitle),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteFromView(m);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _statoMelarioLabel(String stato) {
    switch (stato) {
      case 'posizionato':   return 'Posizionato';
      case 'in_smielatura': return 'In smielatura';
      case 'rimosso':       return 'Rimosso';
      case 'smielato':      return 'Smielato';
      default:              return stato;
    }
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
        title: Text(_s.melariRemoveMelarioDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_s.melariRemoveMelarioMsg),
            const SizedBox(height: 16),
            TextField(
              controller: pesoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _s.melariLblPesoStimato,
                border: const OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_s.dialogCancelBtn)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _removeMelarioOptimistic(m, double.tryParse(pesoCtrl.text));
            },
            child: Text(_s.melariConfirmBtn),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMelarioOptimistic(Melario m, double? peso) async {
    final dataRimozione = DateTime.now().toIso8601String().split('T')[0];
    final snapshot = List<Melario>.from(_melari);
    final storageService = Provider.of<StorageService>(context, listen: false);

    // Aggiornamento ottimistico: il melario sparisce dalla vista alveari
    // (filtrata su posizionato/in_smielatura) e va a popolare il counter
    // "Da smielare".
    setState(() {
      final idx = _melari.indexWhere((x) => x.id == m.id);
      if (idx != -1) {
        _melari[idx] = m.copyWith(
          stato: 'rimosso',
          dataRimozione: dataRimozione,
          pesoStimato: peso ?? m.pesoStimato,
        );
      }
    });

    try {
      await _apiService.removeMelario(
        m.id,
        data: {
          'data_rimozione': dataRimozione,
          if (peso != null) 'peso_stimato': peso,
        },
      );
      await storageService.saveData(
          'melari', _melari.map((x) => x.toJson()).toList());
    } catch (e) {
      debugPrint('Errore rimozione melario: $e');
      if (mounted) {
        setState(() => _melari = snapshot);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.melariRemoveMelarioError(e.toString()))),
        );
        _refreshAll();
      }
    }
  }

  void _confirmDeleteFromView(Melario m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.melariEliminaMelarioTitle),
        content: Text(_s.melariDeleteMelarioMsg(m.id)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_s.dialogCancelBtn)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.delete('${ApiConstants.melariUrl}${m.id}/');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.melariDeleteMelarioOk)));
                }
                _refreshAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_s.melariDeleteMelarioError(e.toString()))),
                  );
                }
              }
            },
            child: Text(_s.btnDelete),
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
