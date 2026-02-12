import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/melario.dart';
import '../../models/invasettamento.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

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
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final melariRes = await _apiService.get(ApiConstants.melariUrl);
      final smielatureRes = await _apiService.get(ApiConstants.produzioniUrl);
      final invasettamentiRes = await _apiService.get(ApiConstants.invasettamentiUrl);

      setState(() {
        _melari = (melariRes as List).map((item) => Melario.fromJson(item)).toList();
        _smielature = (smielatureRes as List).map((item) => item as Map<String, dynamic>).toList();
        _invasettamenti = (invasettamentiRes as List).map((item) => Invasettamento.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Melari e Produzioni'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Melari'),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                    _buildMelariTab(),
                    _buildSmielatureTab(),
                    _buildInvasettamentoTab(),
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
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Aggiungi melario'),
                content: Text('Per aggiungere un melario, vai alla pagina di dettaglio di un\'arnia.'),
                actions: [
                  TextButton(
                    child: Text('Annulla'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text('Vai alle arnie'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppConstants.arniaListRoute);
                    },
                  ),
                ],
              ),
            );
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

  // ==================== MELARI TAB ====================

  Widget _buildMelariTab() {
    if (_melari.isEmpty) {
      return Center(
        child: Text(
          'Nessun melario trovato.\nAggiungi melari dalle schede delle singole arnie.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final melariPosizionati = _melari.where((m) => m.stato == 'posizionato').toList();
    final melariRimossi = _melari.where((m) => m.stato == 'rimosso').toList();
    final melariInSmielatura = _melari.where((m) => m.stato == 'in_smielatura').toList();
    final melariSmielati = _melari.where((m) => m.stato == 'smielato').toList();

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (melariPosizionati.isNotEmpty) ...[
            _buildMelariSection('Melari Posizionati', melariPosizionati, Colors.green),
            const SizedBox(height: 16),
          ],
          if (melariInSmielatura.isNotEmpty) ...[
            _buildMelariSection('Melari in Smielatura', melariInSmielatura, Colors.orange),
            const SizedBox(height: 16),
          ],
          if (melariRimossi.isNotEmpty) ...[
            _buildMelariSection('Melari Rimossi', melariRimossi, Colors.blue),
            const SizedBox(height: 16),
          ],
          if (melariSmielati.isNotEmpty) ...[
            _buildMelariSection('Melari Smielati', melariSmielati, Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildMelariSection(String title, List<Melario> melari, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Divider(color: color),
        ...melari.map((melario) => MelarioListItem(
          melario: melario,
          onStatusChanged: _refreshAll,
          apiService: _apiService,
        )),
      ],
    );
  }

  // ==================== SMIELATURE TAB ====================

  Widget _buildSmielatureTab() {
    if (_smielature.isEmpty) {
      return Center(
        child: Text('Nessuna smielatura registrata', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
      );
    }

    // Summary calculations
    double totalKg = 0;
    final Map<String, double> byTipo = {};
    for (final s in _smielature) {
      final qty = double.tryParse(s['quantita_miele']?.toString() ?? '0') ?? 0;
      totalKg += qty;
      final tipo = s['tipo_miele']?.toString() ?? 'Altro';
      byTipo[tipo] = (byTipo[tipo] ?? 0) + qty;
    }

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_drink, color: Colors.amber.shade700),
                      SizedBox(width: 8),
                      Text('Riepilogo Produzioni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Totale', '${totalKg.toStringAsFixed(1)} kg'),
                      _buildSummaryItem('Smielature', '${_smielature.length}'),
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

          // Smielature list
          ...List.generate(_smielature.length, (i) {
            final s = _smielature[i];
            final melariCount = (s['melari'] as List?)?.length ?? s['melari_count'] ?? 0;
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.local_drink, color: Colors.amber),
                title: Text('${s['tipo_miele']} - ${s['quantita_miele']} kg'),
                subtitle: Text('${s['data']} - ${s['apiario_nome']} - $melariCount melari'),
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
    );
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
    if (_invasettamenti.isEmpty) {
      return Center(
        child: Text('Nessun invasettamento registrato', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
      );
    }

    // Summary calculations
    final Map<int, int> vasettiPerFormato = {};
    double totalKgInvasettati = 0;
    for (final inv in _invasettamenti) {
      vasettiPerFormato[inv.formatoVasetto] = (vasettiPerFormato[inv.formatoVasetto] ?? 0) + inv.numeroVasetti;
      totalKgInvasettati += inv.kgTotali ?? 0;
    }

    // Total kg from smielature for comparison
    double totalKgSmielati = 0;
    for (final s in _smielature) {
      totalKgSmielati += double.tryParse(s['quantita_miele']?.toString() ?? '0') ?? 0;
    }

    return RefreshIndicator(
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
          ...List.generate(_invasettamenti.length, (i) {
            final inv = _invasettamenti[i];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.inventory_2, color: Colors.teal),
                title: Text('${inv.tipoMiele} - ${inv.formatoVasetto}g x${inv.numeroVasetti}'),
                subtitle: Text('${inv.data} - ${inv.kgTotali?.toStringAsFixed(2) ?? 0} kg${inv.lotto != null ? ' - Lotto: ${inv.lotto}' : ''}'),
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
    );
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
}

class MelarioListItem extends StatelessWidget {
  final Melario melario;
  final VoidCallback onStatusChanged;
  final ApiService apiService;

  MelarioListItem({
    required this.melario,
    required this.onStatusChanged,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: _getStatusIcon(),
        title: Text('Melario #${melario.id} - Arnia ${melario.arniaNumero}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Posizionamento: ${melario.dataPosizionamento}'),
            if (melario.dataRimozione != null)
              Text('Rimozione: ${melario.dataRimozione}'),
            Text('${melario.numeroTelaini} telaini - Posizione ${melario.posizione}'),
            if (melario.pesoStimato != null)
              Text('Peso stimato: ${melario.pesoStimato!.toStringAsFixed(2)} kg',
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.amber.shade700)),
          ],
        ),
        isThreeLine: true,
        trailing: _buildActionButton(context),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Dettaglio Melario'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ID: ${melario.id}'),
                    Text('Arnia: ${melario.arniaNumero}'),
                    Text('Apiario: ${melario.apiarioNome}'),
                    Text('Stato: ${_getStatusDisplay()}'),
                    Text('Numero telaini: ${melario.numeroTelaini}'),
                    Text('Posizione: ${melario.posizione}'),
                    Text('Data posizionamento: ${melario.dataPosizionamento}'),
                    if (melario.dataRimozione != null)
                      Text('Data rimozione: ${melario.dataRimozione}'),
                    if (melario.pesoStimato != null)
                      Text('Peso stimato: ${melario.pesoStimato!.toStringAsFixed(2)} kg'),
                    if (melario.note != null && melario.note!.isNotEmpty)
                      Text('Note: ${melario.note}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Chiudi'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusDisplay() {
    switch (melario.stato) {
      case 'posizionato': return 'Posizionato';
      case 'rimosso': return 'Rimosso';
      case 'in_smielatura': return 'In Smielatura';
      case 'smielato': return 'Smielato';
      default: return melario.stato;
    }
  }

  Widget _getStatusIcon() {
    switch (melario.stato) {
      case 'posizionato': return Icon(Icons.check_circle, color: Colors.green);
      case 'rimosso': return Icon(Icons.remove_circle, color: Colors.blue);
      case 'in_smielatura': return Icon(Icons.hourglass_top, color: Colors.orange);
      case 'smielato': return Icon(Icons.done_all, color: Colors.grey);
      default: return Icon(Icons.help);
    }
  }

  Widget? _buildActionButton(BuildContext context) {
    final deleteButton = IconButton(
      icon: Icon(Icons.delete, color: Colors.red),
      tooltip: 'Elimina melario',
      onPressed: () => _confirmDeleteMelario(context),
    );

    switch (melario.stato) {
      case 'posizionato':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.blue),
              tooltip: 'Rimuovi melario',
              onPressed: () => _showRemoveDialog(context),
            ),
            deleteButton,
          ],
        );
      case 'rimosso':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.local_drink, color: Colors.orange),
              tooltip: 'Invia in smielatura',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Invia in smielatura'),
                    content: Text('Confermi di voler inviare questo melario in smielatura?'),
                    actions: [
                      TextButton(child: Text('Annulla'), onPressed: () => Navigator.of(context).pop(false)),
                      TextButton(child: Text('Conferma'), onPressed: () => Navigator.of(context).pop(true)),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await apiService.post('${ApiConstants.melariUrl}${melario.id}/smielatura/', {});
                    onStatusChanged();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
                  }
                }
              },
            ),
            deleteButton,
          ],
        );
      default:
        return deleteButton;
    }
  }

  void _showRemoveDialog(BuildContext context) {
    final pesoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rimuovi melario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Confermi di voler rimuovere questo melario dall\'arnia?'),
            SizedBox(height: 16),
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Peso stimato (kg)',
                hintText: 'Es: 12.5',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(child: Text('Annulla'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: Text('Conferma'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final peso = double.tryParse(pesoController.text);
                // First update peso_stimato if provided
                if (peso != null) {
                  await apiService.put(
                    '${ApiConstants.melariUrl}${melario.id}/',
                    {...melario.toJson(), 'peso_stimato': peso, 'stato': 'rimosso', 'data_rimozione': DateTime.now().toIso8601String().split('T')[0]},
                  );
                } else {
                  await apiService.put(
                    '${ApiConstants.melariUrl}${melario.id}/',
                    {...melario.toJson(), 'stato': 'rimosso', 'data_rimozione': DateTime.now().toIso8601String().split('T')[0]},
                  );
                }
                onStatusChanged();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMelario(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina Melario'),
        content: Text('Sei sicuro di voler eliminare il melario #${melario.id} dell\'arnia ${melario.arniaNumero}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiService.delete('${ApiConstants.melariUrl}${melario.id}/');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Melario eliminato con successo')));
                onStatusChanged();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante l\'eliminazione: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
