import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/fioritura.dart';
import '../../services/api_service.dart';
import '../../services/fioritura_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class FiorituraListScreen extends StatefulWidget {
  @override
  _FiorituraListScreenState createState() => _FiorituraListScreenState();
}

class _FiorituraListScreenState extends State<FiorituraListScreen>
    with SingleTickerProviderStateMixin {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  late TabController _tabController;

  List<Fioritura> _mie = [];
  List<Fioritura> _community = [];
  bool _isRefreshing = false;
  bool _cacheChecked = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    _errorMessage = null;

    final storageService = Provider.of<StorageService>(context, listen: false);
    final service = FiorituraService(Provider.of<ApiService>(context, listen: false));

    // Phase 1: cache — read before any setState so skeleton doesn't flash
    try {
      final cachedMie = await storageService.getStoredData('fioriture_mie');
      final cachedCommunity = await storageService.getStoredData('fioriture_community');
      _mie = cachedMie.map((e) => Fioritura.fromJson(e as Map<String, dynamic>)).toList();
      _community = cachedCommunity.map((e) => Fioritura.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Cache fioriture: $e');
    }
    if (mounted) setState(() { _cacheChecked = true; _isRefreshing = true; });

    // Phase 2: API — run in parallel so a slow /community/ doesn't block /mie/
    List<Fioritura>? mie;
    List<Fioritura>? community;
    final results = await Future.wait([
      service.getFioriture().then<List<Fioritura>?>((v) => v).catchError((e) {
        debugPrint('Errore fioriture mie: $e');
        return null;
      }),
      service.getFioritueCommunity().then<List<Fioritura>?>((v) => v).catchError((e) {
        debugPrint('Errore fioriture community: $e');
        return null;
      }),
    ]);
    mie = results[0];
    community = results[1];

    // Save to cache only on success (null = error, [] = success with no items)
    if (mie != null) await storageService.saveData('fioriture_mie', mie.map((f) => f.toJson()).toList());
    if (community != null) await storageService.saveData('fioriture_community', community.map((f) => f.toJson()).toList());

    if (mounted) {
      if (mie != null) _mie = mie;
      if (community != null) _community = community;
      if (mie == null && community == null && _mie.isEmpty && _community.isEmpty) {
        _errorMessage = _s.fiorituraListLoadError;
      }
      setState(() { _isRefreshing = false; });
    }
  }

  List<Fioritura> _filtered(List<Fioritura> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((f) =>
            f.pianta.toLowerCase().contains(q) ||
            (f.apiarioNome?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.fiorituraListTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.fiorituraTabMie),
            Tab(text: s.fiorituraTabCommunity),
          ],
        ),
        actions: [],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.fioritureListRoute),
      floatingActionButton: FloatingActionButton(
        heroTag: 'btnNuovaFioritura',
        tooltip: s.fiorituraFabTooltip,
        onPressed: () async {
          final result = await Navigator.of(context)
              .pushNamed(AppConstants.fiorituraCreateRoute);
          if (result == true) _load();
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: s.fiorituraSearchHint,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: !_cacheChecked
                ? const SizedBox.shrink()
                : _isRefreshing && _mie.isEmpty && _community.isEmpty
                ? const SkeletonListView()
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _load,
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_filtered(_mie), showActions: true),
                          _buildList(_filtered(_community), showActions: false),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Fioritura> fioriture, {required bool showActions}) {
    final s = _s;
    if (fioriture.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_florist, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              s.fiorituraListNoData,
              style: TextStyle(color: ThemeConstants.textSecondaryColor),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: fioriture.length,
        itemBuilder: (ctx, i) => _FiorituraCard(
          fioritura: fioriture[i],
          showActions: showActions,
          onTap: () async {
            final result = await Navigator.of(context).pushNamed(
              AppConstants.fiorituraDetailRoute,
              arguments: fioriture[i].id,
            );
            if (result == true) _load();
          },
          onEdit: showActions
              ? () async {
                  final result = await Navigator.of(context).pushNamed(
                    AppConstants.fiorituraCreateRoute,
                    arguments: fioriture[i],
                  );
                  if (result == true) _load();
                }
              : null,
          onDelete: showActions
              ? () async {
                  final localS = _s;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(localS.fiorituraDeleteTitle),
                      content: Text(localS.fiorituraListDeleteMsg(fioriture[i].pianta)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(localS.dialogCancelBtn)),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(localS.fiorituraMenuDelete,
                                style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await FiorituraService(Provider.of<ApiService>(context, listen: false)).deleteFioritura(fioriture[i].id);
                      _load();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_s.fiorituraDeleteError(e.toString()))),
                        );
                      }
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }
}

class _FiorituraCard extends StatelessWidget {
  final Fioritura fioritura;
  final bool showActions;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FiorituraCard({
    required this.fioritura,
    required this.showActions,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final isActive = fioritura.isActive;
    final color = isActive ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_florist, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fioritura.pianta,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ThemeConstants.textPrimaryColor,
                      ),
                    ),
                  ),
                  if (fioritura.pubblica)
                    Tooltip(
                      message: s.fiorituraCardPubblica,
                      child: Icon(Icons.public, size: 16,
                          color: Colors.blue[400]),
                    ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? s.fiorituraCardAttiva : s.fiorituraCardNonAttiva,
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (showActions) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (v) {
                        if (v == 'edit') onEdit?.call();
                        if (v == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                                leading: const Icon(Icons.edit),
                                title: Text(s.fiorituraMenuEdit),
                                dense: true)),
                        PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                                leading: const Icon(Icons.delete,
                                    color: Colors.red),
                                title: Text(s.fiorituraMenuDelete,
                                    style: const TextStyle(color: Colors.red)),
                                dense: true)),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (fioritura.apiarioNome != null) ...[
                    Icon(Icons.hive, size: 13,
                        color: ThemeConstants.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(fioritura.apiarioNome!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: ThemeConstants.textSecondaryColor)),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.calendar_today, size: 13,
                      color: ThemeConstants.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _dateRange(fioritura.dataInizio, fioritura.dataFine, s),
                    style: const TextStyle(
                        fontSize: 12,
                        color: ThemeConstants.textSecondaryColor),
                  ),
                ],
              ),
              if (fioritura.nConferme > 0 || fioritura.intensitaMedia != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 13,
                          color: Colors.blue[400]),
                      const SizedBox(width: 4),
                      Text(
                        s.fiorituraCardConferme(fioritura.nConferme),
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue[400]),
                      ),
                      if (fioritura.intensitaMedia != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          fioritura.intensitaMedia!.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber[700]),
                        ),
                      ],
                      if (fioritura.confermaDaMe) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, size: 13,
                            color: Colors.green),
                        const SizedBox(width: 2),
                        Text(s.fiorituraCardTu,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange(String start, String? end, AppStrings s) {
    final from = _fmt(start);
    if (end == null) return s.fiorituraDateFrom(from);
    return '$from → ${_fmt(end)}';
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
