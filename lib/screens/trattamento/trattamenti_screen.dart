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
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class TrattamentiScreen extends StatefulWidget {
  @override
  _TrattamentiScreenState createState() => _TrattamentiScreenState();
}

class _TrattamentiScreenState extends State<TrattamentiScreen> with SingleTickerProviderStateMixin {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  late TabController _tabController;
  late ApiService _apiService;
  List<TrattamentoSanitario> _trattamenti = [];
  // ignore: unused_field
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
    Provider.of<LanguageService>(context); // rebuild on language change
    final s = _s;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.trattamentiTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.trattamentiTabAttivi),
            Tab(text: s.trattamentiTabCompletati),
            Tab(text: s.labelAll),
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
    final s = _s;
    if (_isRefreshing && _trattamenti.isEmpty) return const SizedBox.shrink();
    if (_trattamenti.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.trattamentiNoData, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(s.trattamentiBtnNew),
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
              _buildTrattamentiList(attivi, s.trattamentiNoAttivi),
              _buildTrattamentiList(completati, s.trattamentiNoCompletati),
              _buildTrattamentiList(trattamenti, s.trattamentiNoData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGruppoFilterBar(List<String> gruppiNomi) {
    final s = _s;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(s.labelAll),
            selected: _filtroGruppo == null,
            onSelected: (_) => setState(() { _filtroGruppo = null; }),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: Text(s.labelPersonal),
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

  String _metodoLabel(String metodo, AppStrings s) {
    switch (metodo) {
      case 'strisce':    return s.trattamentiMetodoStrisce;
      case 'gocciolato': return s.trattamentiMetodoGocciolato;
      case 'sublimato':  return s.trattamentiMetodoSublimato;
      default:           return s.arniaDetailChangeMotivoAltro;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final metodo = trattamento.metodoApplicazione;
    final subtitleParts = [
      '${s.labelApiario}: ${trattamento.apiarioNome}',
      if (metodo != null && metodo.isNotEmpty) _metodoLabel(metodo, s),
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
                          _metodoLabel(trattamento.metodoApplicazione!, s),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                Text(s.trattamentiInizio(trattamento.dataInizio)),
                if (trattamento.dataFine != null)
                  Text(s.trattamentiFine(trattamento.dataFine!)),
                if (trattamento.dataFineSospensione != null)
                  Text(s.trattamentiFineSOSP(trattamento.dataFineSospensione!)),
                if (trattamento.arnie != null && trattamento.arnie!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.trattamentiArnieSelezionate(trattamento.arnie!.length),
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                const SizedBox(height: 8),
                if (trattamento.note != null && trattamento.note!.isNotEmpty)
                  Text(s.trattamentiNote(trattamento.note!)),
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
        final s = Provider.of<LanguageService>(context, listen: false).strings;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.trattamentiError(e.toString()))));
      }
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final deleteButton = ElevatedButton.icon(
      icon: const Icon(Icons.delete_forever, size: 16),
      label: Text(s.btnDelete),
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
                label: Text(s.trattamentiBtnAvvia),
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
                label: Text(s.trattamentiBtnAnnullaStatus),
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
                label: Text(s.trattamentiBtnCompleta),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ).merge(_compactButtonStyle),
                onPressed: () => _changeStato(context, 'completato'),
              ),
            ),
            const SizedBox(width: 6),
            // "Interrompi" = interrompi il trattamento prima del termine
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text(s.trattamentiBtnInterrompi),
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
      case 'annullato':
        return Row(
          children: [
            // "Ripristina" = annulla l'annullamento (annullato → programmato)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: Text(s.trattamentiBtnRipristina),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ).merge(_compactButtonStyle),
                onPressed: () => _changeStato(context, 'programmato'),
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
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.trattamentiDeleteTitle),
        content: Text(s.trattamentiDeleteMsg(trattamento.tipoTrattamentoNome)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.dialogCancelBtn),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiService.delete(
                  '${ApiConstants.trattamentiUrl}${trattamento.id}/',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.trattamentiDeletedOk)),
                  );
                }
                onStatusChanged();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.trattamentiDeleteError(e.toString()))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(s.btnDelete),
          ),
        ],
      ),
    );
  }
}
