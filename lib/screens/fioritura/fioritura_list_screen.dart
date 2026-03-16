import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/fioritura.dart';
import '../../services/api_service.dart';
import '../../services/fioritura_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/offline_banner.dart';

class FiorituraListScreen extends StatefulWidget {
  @override
  _FiorituraListScreenState createState() => _FiorituraListScreenState();
}

class _FiorituraListScreenState extends State<FiorituraListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FiorituraService _service;
  late StorageService _storageService;

  List<Fioritura> _mie = [];
  List<Fioritura> _community = [];
  bool _loading = true;
  bool _isRefreshing = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = FiorituraService(Provider.of<ApiService>(context, listen: false));
    _storageService = Provider.of<StorageService>(context, listen: false);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Phase 1: cache
    final cachedMie = await _storageService.getStoredData('fioriture_mie');
    final cachedCommunity = await _storageService.getStoredData('fioriture_community');
    if (cachedMie.isNotEmpty || cachedCommunity.isNotEmpty) {
      if (cachedMie.isNotEmpty) _mie = cachedMie.map((e) => Fioritura.fromJson(e as Map<String, dynamic>)).toList();
      if (cachedCommunity.isNotEmpty) _community = cachedCommunity.map((e) => Fioritura.fromJson(e as Map<String, dynamic>)).toList();
      _loading = false;
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Phase 2: API
    try {
      final mie = await _service.getFioriture();
      final community = await _service.getFioritueCommunity();
      await _storageService.saveData('fioriture_mie', mie.map((f) => f.toJson()).toList());
      await _storageService.saveData('fioriture_community', community.map((f) => f.toJson()).toList());
      if (mounted) {
        _mie = mie;
        _community = community;
      }
    } catch (e) {
      debugPrint('Errore caricamento fioriture: $e');
      if (mounted && _mie.isEmpty && _community.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento: $e')),
        );
      }
    }

    if (mounted) setState(() { _loading = false; _isRefreshing = false; });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Fioriture'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Le mie'),
            Tab(text: 'Community'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.fioritureListRoute),
      floatingActionButton: FloatingActionButton(
        heroTag: 'btnNuovaFioritura',
        tooltip: 'Aggiungi fioritura',
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
                hintText: 'Cerca per pianta o apiario...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isRefreshing && _mie.isEmpty && _community.isEmpty
                ? const SizedBox.shrink()
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
    if (fioriture.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_florist, size: 64, color: Colors.grey[300]),
            SizedBox(height: 12),
            Text(
              'Nessuna fioritura trovata',
              style: TextStyle(color: ThemeConstants.textSecondaryColor),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 80),
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
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Elimina fioritura'),
                      content: Text(
                          'Vuoi eliminare la fioritura "${fioriture[i].pianta}"?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Annulla')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Elimina',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await _service.deleteFioritura(fioriture[i].id);
                      _load();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore eliminazione: $e')),
                      );
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
    final isActive = fioritura.isActive;
    final color = isActive ? Colors.green : Colors.grey;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fioritura.pianta,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ThemeConstants.textPrimaryColor,
                      ),
                    ),
                  ),
                  if (fioritura.pubblica)
                    Tooltip(
                      message: 'Pubblica',
                      child: Icon(Icons.public, size: 16,
                          color: Colors.blue[400]),
                    ),
                  SizedBox(width: 4),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Attiva' : 'Non attiva',
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (showActions) ...[
                    SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18),
                      onSelected: (v) {
                        if (v == 'edit') onEdit?.call();
                        if (v == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Modifica'),
                                dense: true)),
                        PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                                leading: Icon(Icons.delete,
                                    color: Colors.red),
                                title: Text('Elimina',
                                    style: TextStyle(color: Colors.red)),
                                dense: true)),
                      ],
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  if (fioritura.apiarioNome != null) ...[
                    Icon(Icons.hive, size: 13,
                        color: ThemeConstants.textSecondaryColor),
                    SizedBox(width: 4),
                    Text(fioritura.apiarioNome!,
                        style: TextStyle(
                            fontSize: 12,
                            color: ThemeConstants.textSecondaryColor)),
                    SizedBox(width: 12),
                  ],
                  Icon(Icons.calendar_today, size: 13,
                      color: ThemeConstants.textSecondaryColor),
                  SizedBox(width: 4),
                  Text(
                    _dateRange(fioritura.dataInizio, fioritura.dataFine),
                    style: TextStyle(
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
                      SizedBox(width: 4),
                      Text(
                        '${fioritura.nConferme} conferme',
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue[400]),
                      ),
                      if (fioritura.intensitaMedia != null) ...[
                        SizedBox(width: 12),
                        Icon(Icons.star, size: 13, color: Colors.amber),
                        SizedBox(width: 2),
                        Text(
                          '${fioritura.intensitaMedia!.toStringAsFixed(1)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber[700]),
                        ),
                      ],
                      if (fioritura.confermaDaMe) ...[
                        SizedBox(width: 8),
                        Icon(Icons.check_circle, size: 13,
                            color: Colors.green),
                        SizedBox(width: 2),
                        Text('Tu',
                            style: TextStyle(
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

  String _dateRange(String start, String? end) {
    final s = _fmt(start);
    if (end == null) return 'Dal $s';
    return '$s → ${_fmt(end)}';
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
