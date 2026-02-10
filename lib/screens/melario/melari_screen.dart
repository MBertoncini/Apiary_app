import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/melario.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class MelariScreen extends StatefulWidget {
  @override
  _MelariScreenState createState() => _MelariScreenState();
}

class _MelariScreenState extends State<MelariScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Melario>> _melariFuture;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _refreshMelari();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshMelari() async {
    setState(() {
      _melariFuture = _loadMelari();
    });
  }

  Future<List<Melario>> _loadMelari() async {
    try {
      final response = await _apiService.get(ApiConstants.melariUrl);
      if (response is List) {
        return response
            .map((item) => Melario.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading melari: $e');
      throw e;
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
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshMelari,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.melariRoute),
      body: FutureBuilder<List<Melario>>(
        future: _melariFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento dei melari: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Tab Melari vuota
                Center(
                  child: Text(
                    'Nessun melario trovato.\nAggiungi melari dalle schede delle singole arnie.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                // Tab Smielature vuota
                Center(
                  child: Text(
                    'Nessuna smielatura registrata',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          } else {
            final melari = snapshot.data!;

            return TabBarView(
              controller: _tabController,
              children: [
                // Tab Melari
                _buildMelariTab(melari),

                // Tab Smielature - Per ora mostriamo una pagina placeholdere
                Center(
                  child: Text(
                    'Le smielature saranno disponibili presto',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Builder(builder: (context) {
      final currentTab = _tabController.index;

      if (currentTab == 0) {
        // Melari tab
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
      } else {
        // Smielature tab
        return FloatingActionButton(
          child: Icon(Icons.add),
          tooltip: 'Nuova smielatura',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Nuova smielatura'),
                content: Text('Per registrare una smielatura, vai alla pagina di dettaglio di un apiario.'),
                actions: [
                  TextButton(
                    child: Text('Annulla'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text('Vai agli apiari'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppConstants.apiarioListRoute);
                    },
                  ),
                ],
              ),
            );
          },
        );
      }
    });
  }

  Widget _buildMelariTab(List<Melario> melari) {
    if (melari.isEmpty) {
      return Center(
        child: Text(
          'Nessun melario trovato.\nAggiungi melari dalle schede delle singole arnie.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Raggruppa melari per stato
    final melariPosizionati = melari.where((m) => m.stato == 'posizionato').toList();
    final melariRimossi = melari.where((m) => m.stato == 'rimosso').toList();
    final melariInSmielatura = melari.where((m) => m.stato == 'in_smielatura').toList();
    final melariSmielati = melari.where((m) => m.stato == 'smielato').toList();

    return RefreshIndicator(
      onRefresh: _refreshMelari,
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
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Divider(color: color),
        ...melari.map((melario) => MelarioListItem(
          melario: melario,
          onStatusChanged: _refreshMelari,
          apiService: _apiService,
        )),
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
                    if (melario.note != null && melario.note!.isNotEmpty)
                      Text('Note: ${melario.note}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Chiudi'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
      case 'posizionato':
        return 'Posizionato';
      case 'rimosso':
        return 'Rimosso';
      case 'in_smielatura':
        return 'In Smielatura';
      case 'smielato':
        return 'Smielato';
      default:
        return melario.stato;
    }
  }

  Widget _getStatusIcon() {
    switch (melario.stato) {
      case 'posizionato':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'rimosso':
        return Icon(Icons.remove_circle, color: Colors.blue);
      case 'in_smielatura':
        return Icon(Icons.hourglass_top, color: Colors.orange);
      case 'smielato':
        return Icon(Icons.done_all, color: Colors.grey);
      default:
        return Icon(Icons.help);
    }
  }

  Widget? _buildActionButton(BuildContext context) {
    final deleteButton = IconButton(
      icon: Icon(Icons.delete, color: Colors.red),
      tooltip: 'Elimina melario',
      onPressed: () => _confirmDeleteMelario(context),
    );

    // Pulsanti variabili in base allo stato
    switch (melario.stato) {
      case 'posizionato':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.blue),
              tooltip: 'Rimuovi melario',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Rimuovi melario'),
                    content: Text('Confermi di voler rimuovere questo melario dall\'arnia?'),
                    actions: [
                      TextButton(
                        child: Text('Annulla'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text('Conferma'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await apiService.post(
                      '${ApiConstants.melariUrl}${melario.id}/rimuovi/',
                      {},
                    );
                    onStatusChanged();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore: $e')),
                    );
                  }
                }
              },
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
                      TextButton(
                        child: Text('Annulla'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text('Conferma'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await apiService.post(
                      '${ApiConstants.melariUrl}${melario.id}/smielatura/',
                      {},
                    );
                    onStatusChanged();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore: $e')),
                    );
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

  void _confirmDeleteMelario(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina Melario'),
        content: Text(
          'Sei sicuro di voler eliminare il melario #${melario.id} dell\'arnia ${melario.arniaNumero}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiService.delete(
                  '${ApiConstants.melariUrl}${melario.id}/',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Melario eliminato con successo')),
                );
                onStatusChanged();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
                );
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
