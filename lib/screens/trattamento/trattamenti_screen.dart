import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/trattamento.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/offline_banner.dart';

class TrattamentiScreen extends StatefulWidget {
  @override
  _TrattamentiScreenState createState() => _TrattamentiScreenState();
}

class _TrattamentiScreenState extends State<TrattamentiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;
  List<TrattamentoSanitario> _trattamenti = [];
  bool _isLoading = true;
  bool _isRefreshing = true;
  // null = tutti; '' = personali; non-empty = nome gruppo
  String? _filtroGruppo;

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
    final storageService = Provider.of<StorageService>(context, listen: false);

    // Fase 1: cache — mostra subito
    final cached = await storageService.getStoredData('trattamenti');
    if (cached.isNotEmpty) {
      _trattamenti = cached.map((item) => TrattamentoSanitario.fromJson(item)).toList();
      _isLoading = false;
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Fase 2: aggiornamento dal server
    try {
      final response = await _apiService.get(ApiConstants.trattamentiUrl);
      List<dynamic> items;
      if (response is List) {
        items = response;
      } else if (response is Map && response.containsKey('results')) {
        items = response['results'] as List;
      } else {
        items = [];
      }
      _trattamenti = items.map((item) => TrattamentoSanitario.fromJson(item)).toList();
      if (items.isNotEmpty) await storageService.saveData('trattamenti', items);
    } catch (e) {
      debugPrint('Error loading trattamenti: $e');
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
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
        actions: [],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.trattamentiRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(AppConstants.trattamentoCreateRoute);
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isRefreshing && _trattamenti.isEmpty) return const SizedBox.shrink();
    if (_trattamenti.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Nessun trattamento sanitario trovato', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Nuovo trattamento'),
              onPressed: () => Navigator.of(context).pushNamed(AppConstants.trattamentoCreateRoute),
            ),
          ],
        ),
      );
    }
    final trattamenti = _filtroGruppo == null
        ? _trattamenti
        : _filtroGruppo == ''
            ? _trattamenti.where((t) => t.apiarioGruppoNome == null).toList()
            : _trattamenti.where((t) => t.apiarioGruppoNome == _filtroGruppo).toList();
    final attivi = trattamenti.where((t) => t.stato == 'programmato' || t.stato == 'in_corso').toList();
    final completati = trattamenti.where((t) => t.stato == 'completato').toList();
    final gruppiNomi = _trattamenti.map((t) => t.apiarioGruppoNome).whereType<String>().toSet().toList()..sort();
    return Column(
      children: [
        if (gruppiNomi.isNotEmpty) _buildGruppoFilterBar(gruppiNomi),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTrattamentiList(attivi, 'Nessun trattamento attivo'),
              _buildTrattamentiList(completati, 'Nessun trattamento completato'),
              _buildTrattamentiList(trattamenti, 'Nessun trattamento trovato'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGruppoFilterBar(List<String> gruppiNomi) {
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

  String _metodoLabel(String metodo) {
    const labels = {
      'strisce': 'Strisce',
      'gocciolato': 'Gocciolato',
      'sublimato': 'Sublimato',
      'altro': 'Altro',
    };
    return labels[metodo] ?? metodo;
  }

  @override
  Widget build(BuildContext context) {
    final metodo = trattamento.metodoApplicazione;
    final subtitleParts = [
      'Apiario: ${trattamento.apiarioNome}',
      if (metodo != null && metodo.isNotEmpty) _metodoLabel(metodo),
    ];
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _getStatusIcon(),
        title: Text(trattamento.tipoTrattamentoNome),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitleParts.join(' · ')),
            if (trattamento.apiarioGruppoNome != null)
              Row(children: [
                Icon(Icons.group, size: 12, color: Colors.indigo),
                SizedBox(width: 3),
                Text(trattamento.apiarioGruppoNome!,
                    style: TextStyle(fontSize: 11, color: Colors.indigo)),
              ]),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trattamento.metodoApplicazione != null &&
                    trattamento.metodoApplicazione!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.science, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _metodoLabel(trattamento.metodoApplicazione!),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                Text('Inizio: ${trattamento.dataInizio}'),
                if (trattamento.dataFine != null)
                  Text('Fine: ${trattamento.dataFine}'),
                if (trattamento.dataFineSospensione != null)
                  Text('Fine sospensione: ${trattamento.dataFineSospensione}'),
                if (trattamento.arnie != null && trattamento.arnie!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Arnie: ${trattamento.arnie!.length} selezionate',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
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

  Future<void> _changeStato(BuildContext context, String nuovoStato) async {
    try {
      await apiService.patch(
        '${ApiConstants.trattamentiUrl}${trattamento.id}/',
        {'stato': nuovoStato},
      );
      onStatusChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final deleteButton = ElevatedButton.icon(
      icon: const Icon(Icons.delete_forever, size: 16),
      label: const Text('Elimina'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _confirmDeleteTrattamento(context),
    );

    // Pulsanti variabili in base allo stato
    final _compactButtonStyle = const ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    switch (trattamento.stato) {
      case 'programmato':
        return Row(
          children: [
            // "Avvia" = il trattamento è iniziato (programmato → in corso)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Avvia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ).merge(_compactButtonStyle),
                onPressed: () => _changeStato(context, 'in_corso'),
              ),
            ),
            const SizedBox(width: 6),
            // "Annulla" = il trattamento non verrà eseguito (resta in archivio)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Annulla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ).merge(_compactButtonStyle),
                onPressed: () => _changeStato(context, 'annullato'),
              ),
            ),
            const SizedBox(width: 6),
            // "Elimina" = rimuove definitivamente il record
            Expanded(child: deleteButton),
          ],
        );
      case 'in_corso':
        return Row(
          children: [
            // "Completa" = trattamento terminato con successo
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Completa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ).merge(_compactButtonStyle),
                onPressed: () => _changeStato(context, 'completato'),
              ),
            ),
            const SizedBox(width: 6),
            // "Annulla" = interrompi il trattamento prima del termine
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Interrompi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ).merge(_compactButtonStyle),
                onPressed: () => _changeStato(context, 'annullato'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: deleteButton),
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
