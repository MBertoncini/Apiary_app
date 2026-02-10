import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/trattamento.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class TrattamentiScreen extends StatefulWidget {
  @override
  _TrattamentiScreenState createState() => _TrattamentiScreenState();
}

class _TrattamentiScreenState extends State<TrattamentiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<TrattamentoSanitario>> _trattamentiFuture;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _refreshTrattamenti();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTrattamenti() async {
    setState(() {
      _trattamentiFuture = _loadTrattamenti();
    });
  }

  Future<List<TrattamentoSanitario>> _loadTrattamenti() async {
    try {
      final response = await _apiService.get(ApiConstants.trattamentiUrl);
      if (response is List) {
        return response
            .map((item) => TrattamentoSanitario.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading trattamenti: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trattamenti Sanitari'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Attivi'),
            Tab(text: 'Completati'),
            Tab(text: 'Tutti'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshTrattamenti,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.trattamentiRoute),
      body: FutureBuilder<List<TrattamentoSanitario>>(
        future: _trattamentiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento dei trattamenti: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nessun trattamento sanitario trovato',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Nuovo trattamento'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppConstants.nuovoTrattamentoRoute);
                    },
                  ),
                ],
              ),
            );
          } else {
            final trattamenti = snapshot.data!;
            final trattamentiAttivi = trattamenti
                .where((t) => t.stato == 'programmato' || t.stato == 'in_corso')
                .toList();
            final trattamentiCompletati = trattamenti
                .where((t) => t.stato == 'completato')
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                // Tab Trattamenti Attivi
                _buildTrattamentiList(trattamentiAttivi, 'Nessun trattamento attivo'),

                // Tab Trattamenti Completati
                _buildTrattamentiList(trattamentiCompletati, 'Nessun trattamento completato'),

                // Tab Tutti i Trattamenti
                _buildTrattamentiList(trattamenti, 'Nessun trattamento trovato'),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(AppConstants.nuovoTrattamentoRoute);
        },
      ),
    );
  }

  Widget _buildTrattamentiList(List<TrattamentoSanitario> trattamenti, String emptyMessage) {
    if (trattamenti.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTrattamenti,
      child: ListView.builder(
        itemCount: trattamenti.length,
        itemBuilder: (context, index) {
          final trattamento = trattamenti[index];
          return TrattamentoListItem(
            trattamento: trattamento,
            onStatusChanged: () => _refreshTrattamenti(),
            apiService: _apiService,
          );
        },
      ),
    );
  }
}

class TrattamentoListItem extends StatelessWidget {
  final TrattamentoSanitario trattamento;
  final VoidCallback onStatusChanged;
  final ApiService apiService;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  TrattamentoListItem({
    required this.trattamento,
    required this.onStatusChanged,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _getStatusIcon(),
        title: Text(trattamento.tipoTrattamentoNome),
        subtitle: Text('Apiario: ${trattamento.apiarioNome}'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inizio: ${trattamento.dataInizio}'),
                if (trattamento.dataFine != null)
                  Text('Fine: ${trattamento.dataFine}'),
                if (trattamento.dataFineSospensione != null)
                  Text('Fine sospensione: ${trattamento.dataFineSospensione}'),
                const SizedBox(height: 8),
                if (trattamento.note != null && trattamento.note!.isNotEmpty)
                  Text('Note: ${trattamento.note}'),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon() {
    // Icona variabile in base allo stato
    switch (trattamento.stato) {
      case 'programmato':
        return Icon(Icons.schedule, color: Colors.orange);
      case 'in_corso':
        return Icon(Icons.play_circle_filled, color: Colors.blue);
      case 'completato':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'annullato':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.help);
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final deleteButton = ElevatedButton.icon(
      icon: Icon(Icons.delete, size: 18),
      label: Text('Elimina'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _confirmDeleteTrattamento(context),
    );

    // Pulsanti variabili in base allo stato
    switch (trattamento.stato) {
      case 'programmato':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: Text('Avvia'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () async {
                try {
                  await apiService.post(
                    '${ApiConstants.trattamentiUrl}${trattamento.id}/stato/in_corso/',
                    {},
                  );
                  onStatusChanged();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              },
            ),
            ElevatedButton(
              child: Text('Annulla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await apiService.post(
                    '${ApiConstants.trattamentiUrl}${trattamento.id}/stato/annullato/',
                    {},
                  );
                  onStatusChanged();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              },
            ),
            deleteButton,
          ],
        );
      case 'in_corso':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: Text('Completa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                try {
                  await apiService.post(
                    '${ApiConstants.trattamentiUrl}${trattamento.id}/stato/completato/',
                    {},
                  );
                  onStatusChanged();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              },
            ),
            ElevatedButton(
              child: Text('Annulla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await apiService.post(
                    '${ApiConstants.trattamentiUrl}${trattamento.id}/stato/annullato/',
                    {},
                  );
                  onStatusChanged();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              },
            ),
            deleteButton,
          ],
        );
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [deleteButton],
        );
    }
  }

  void _confirmDeleteTrattamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina Trattamento'),
        content: Text(
          'Sei sicuro di voler eliminare il trattamento "${trattamento.tipoTrattamentoNome}"?',
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
                  '${ApiConstants.trattamentiUrl}${trattamento.id}/',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Trattamento eliminato con successo')),
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
