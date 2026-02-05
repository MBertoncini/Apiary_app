// lib/screens/pagamento/pagamenti_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/pagamento.dart';
import '../../models/quota_utente.dart';
import '../../services/pagamento_service.dart';
import '../../services/api_service.dart';
import '../../services/api_cache_helper.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class PagamentiScreen extends StatefulWidget {
  @override
  _PagamentiScreenState createState() => _PagamentiScreenState();
}

class _PagamentiScreenState extends State<PagamentiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Pagamento> _pagamenti = [];
  List<QuotaUtente> _quote = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);

      // Verifica la connettività
      final isConnected = await ApiCacheHelper.isConnected();

      if (isConnected) {
        // Carica da API
        try {
          final pagamenti = await pagamentoService.getPagamenti();
          final quote = await pagamentoService.getQuote();

          setState(() {
            _pagamenti = pagamenti;
            _quote = quote;
            _isLoading = false;
            _isOffline = false;
          });

          // Salva nella cache
          await ApiCacheHelper.saveToCache('pagamenti', _pagamenti.map((p) => p.toJson()).toList());
          await ApiCacheHelper.saveToCache('quote', _quote.map((q) => q.toJson()).toList());
        } catch (e) {
          debugPrint('Errore API, utilizzo cache: $e');
          _loadFromCache();
        }
      } else {
        // Se offline, carica dalla cache
        _loadFromCache();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il caricamento dei dati: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromCache() async {
    try {
      // Carica pagamenti dalla cache
      final cachedPagamenti = await ApiCacheHelper.loadFromCache<List<Pagamento>>(
        'pagamenti',
        (data) => (data as List).map((json) => Pagamento.fromJson(json)).toList()
      );

      // Carica quote dalla cache
      final cachedQuote = await ApiCacheHelper.loadFromCache<List<QuotaUtente>>(
        'quote',
        (data) => (data as List).map((json) => QuotaUtente.fromJson(json)).toList()
      );

      setState(() {
        _pagamenti = cachedPagamenti ?? [];
        _quote = cachedQuote ?? [];
        _isLoading = false;
        _isOffline = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il caricamento dei dati dalla cache: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Gestione Pagamenti'),
            if (_isOffline)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Tooltip(
                  message: 'Modalità offline - Dati caricati dalla cache',
                  child: Icon(Icons.offline_bolt, size: 18, color: Colors.amber),
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pagamenti'),
            Tab(text: 'Quote'),
            Tab(text: 'Bilancio'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            tooltip: 'Sincronizza dati',
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.pagamentiRoute),
      body: _isLoading
          ? LoadingWidget(message: 'Caricamento dati...')
          : _errorMessage != null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadData,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPagamentiTab(),
                    _buildQuoteTab(),
                    _buildBilancioTab(),
                  ],
                ),
      floatingActionButton: _tabController.index < 2
          ? FloatingActionButton(
              onPressed: () {
                if (_tabController.index == 0) {
                  Navigator.pushNamed(context, AppConstants.pagamentoCreateRoute)
                      .then((_) => _loadData());
                } else if (_tabController.index == 1) {
                  Navigator.pushNamed(context, AppConstants.quoteRoute)
                      .then((_) => _loadData());
                }
              },
              child: Icon(Icons.add),
              tooltip: _tabController.index == 0 ? 'Nuovo Pagamento' : 'Nuova Quota',
            )
          : null,
    );
  }

  // Verifica se un pagamento è legato ad attrezzatura/manutenzione
  bool _isAttrezzaturaPagamento(Pagamento pagamento) {
    final desc = pagamento.descrizione.toLowerCase();
    return desc.contains('attrezzatura') || desc.contains('manutenzione');
  }

  Widget _buildPagamentiTab() {
    if (_pagamenti.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun pagamento registrato',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Registra Pagamento'),
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.pagamentoCreateRoute)
                    .then((_) => _loadData());
              },
            ),
          ],
        ),
      );
    }

    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '\u20AC');
    final formatDate = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          // Link rapidi
          Card(
            margin: EdgeInsets.all(8),
            color: Colors.blue.withOpacity(0.05),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Link Rapidi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.build, size: 16),
                          label: Text('Gestione Attrezzature', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.pushNamed(context, AppConstants.attrezzatureRoute);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Le spese per attrezzature vengono registrate automaticamente nei pagamenti',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          // Lista pagamenti
          ...List.generate(_pagamenti.length, (index) {
            final pagamento = _pagamenti[index];
            final isAttrezzatura = _isAttrezzaturaPagamento(pagamento);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Row(
                  children: [
                    if (isAttrezzatura)
                      Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: 'Spesa attrezzatura',
                          child: Icon(Icons.build, size: 16, color: Colors.cyan),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        pagamento.descrizione,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${pagamento.utenteUsername} - ${formatDate.format(DateTime.parse(pagamento.data))}',
                  maxLines: 1,
                ),
                trailing: Text(
                  formatCurrency.format(pagamento.importo),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ThemeConstants.primaryColor,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: isAttrezzatura
                      ? Colors.cyan.withOpacity(0.1)
                      : ThemeConstants.primaryColor.withOpacity(0.1),
                  child: Icon(
                    isAttrezzatura ? Icons.build : Icons.euro,
                    color: isAttrezzatura ? Colors.cyan : ThemeConstants.primaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppConstants.pagamentoDetailRoute,
                    arguments: pagamento.id,
                  ).then((_) => _loadData());
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuoteTab() {
    if (_quote.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna quota trovata',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Gestisci Quote'),
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.quoteRoute)
                    .then((_) => _loadData());
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _quote.length,
        itemBuilder: (context, index) {
          final quota = _quote[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(quota.utenteUsername),
              subtitle: Text(quota.gruppoNome ?? 'Gruppo ${quota.gruppo}'),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${quota.percentuale}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, AppConstants.quoteRoute)
                    .then((_) => _loadData());
              },
            ),
          );
        },
      ),
    );
  }

  /// Calcola il bilancio per ogni gruppo, determinando quanto ogni membro
  /// deve dare o ricevere dagli altri.
  ///
  /// Formula: SALDO = TOTALE_PAGATO - (TOTALE_PAGAMENTI_GRUPPO * QUOTA% / 100)
  /// Se SALDO > 0: il membro ha pagato di più, gli altri gli devono dei soldi
  /// Se SALDO < 0: il membro deve pagare ancora
  Widget _buildBilancioTab() {
    // Raggruppa le quote per gruppo
    final Map<int, List<QuotaUtente>> quotePerGruppo = {};
    for (var quota in _quote) {
      if (quota.gruppo != null) {
        quotePerGruppo.putIfAbsent(quota.gruppo!, () => []);
        quotePerGruppo[quota.gruppo!]!.add(quota);
      }
    }

    if (quotePerGruppo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun bilancio disponibile',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Per calcolare il bilancio servono quote assegnate ai membri del gruppo e pagamenti registrati.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '\u20AC');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(8),
        children: [
          // Per ogni gruppo con quote, calcola il bilancio
          for (var entry in quotePerGruppo.entries) ...[
            _buildGruppoBilancio(entry.key, entry.value, formatCurrency),
          ],
        ],
      ),
    );
  }

  Widget _buildGruppoBilancio(int gruppoId, List<QuotaUtente> quoteGruppo, NumberFormat formatCurrency) {
    // Trova il nome del gruppo dalla prima quota
    final gruppoNome = quoteGruppo.first.gruppoNome ?? 'Gruppo $gruppoId';

    // Filtra i pagamenti di questo gruppo
    final pagamentiGruppo = _pagamenti.where((p) => p.gruppo == gruppoId).toList();

    // Calcola il totale dei pagamenti del gruppo
    final double totalePagamentiGruppo = pagamentiGruppo.fold(0.0, (sum, p) => sum + p.importo);

    // Calcola i dati per ogni membro
    final List<Map<String, dynamic>> bilancioMembri = [];

    for (var quota in quoteGruppo) {
      // Pagamenti di questo utente nel gruppo
      final pagamentiUtente = pagamentiGruppo.where((p) => p.utente == quota.utente).toList();
      final double totalePagato = pagamentiUtente.fold(0.0, (sum, p) => sum + p.importo);

      // Quanto dovrebbe pagare in base alla quota
      final double dovuto = totalePagamentiGruppo * (quota.percentuale / 100.0);

      // Saldo: positivo = ha pagato di più (credito), negativo = deve ancora pagare (debito)
      final double saldo = totalePagato - dovuto;

      bilancioMembri.add({
        'utenteId': quota.utente,
        'username': quota.utenteUsername,
        'percentuale': quota.percentuale,
        'totalePagato': totalePagato,
        'dovuto': dovuto,
        'saldo': saldo,
      });
    }

    // Calcola i trasferimenti necessari (chi deve dare a chi)
    final trasferimenti = _calcolaTrasferimenti(bilancioMembri);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del gruppo
            Row(
              children: [
                Icon(Icons.group, color: ThemeConstants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gruppoNome,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Totale spese gruppo: ${formatCurrency.format(totalePagamentiGruppo)}',
              style: TextStyle(
                color: ThemeConstants.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const Divider(height: 24),

            // Situazione di ogni membro
            for (var membro in bilancioMembri) ...[
              _buildMembroBilancioRow(membro, formatCurrency),
              const SizedBox(height: 8),
            ],

            // Trasferimenti necessari
            if (trasferimenti.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Trasferimenti necessari',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (var trasf in trasferimenti)
                _buildTrasferimentoRow(trasf, formatCurrency),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembroBilancioRow(Map<String, dynamic> membro, NumberFormat formatCurrency) {
    final double saldo = membro['saldo'];
    final bool isPositive = saldo >= 0;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive
            ? ThemeConstants.successColor.withOpacity(0.08)
            : ThemeConstants.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive
              ? ThemeConstants.successColor.withOpacity(0.3)
              : ThemeConstants.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ThemeConstants.primaryColor,
                child: Text(
                  membro['username'].toString().isNotEmpty
                      ? membro['username'][0].toUpperCase()
                      : '?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  membro['username'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${membro['percentuale']}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagato',
                      style: TextStyle(fontSize: 11, color: ThemeConstants.textSecondaryColor),
                    ),
                    Text(
                      formatCurrency.format(membro['totalePagato']),
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dovuto',
                      style: TextStyle(fontSize: 11, color: ThemeConstants.textSecondaryColor),
                    ),
                    Text(
                      formatCurrency.format(membro['dovuto']),
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo',
                      style: TextStyle(fontSize: 11, color: ThemeConstants.textSecondaryColor),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${formatCurrency.format(saldo)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isPositive ? ThemeConstants.successColor : ThemeConstants.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calcola i trasferimenti minimi necessari per bilanciare i debiti.
  /// Chi ha saldo negativo deve pagare chi ha saldo positivo.
  List<Map<String, dynamic>> _calcolaTrasferimenti(List<Map<String, dynamic>> bilancioMembri) {
    // Separa creditori e debitori
    final List<Map<String, dynamic>> creditori = [];
    final List<Map<String, dynamic>> debitori = [];

    for (var membro in bilancioMembri) {
      final double saldo = membro['saldo'];
      if (saldo > 0.01) {
        creditori.add({...membro, 'residuo': saldo});
      } else if (saldo < -0.01) {
        debitori.add({...membro, 'residuo': -saldo}); // residuo positivo per comodità
      }
    }

    final List<Map<String, dynamic>> trasferimenti = [];
    int i = 0, j = 0;

    while (i < debitori.length && j < creditori.length) {
      final double importo = debitori[i]['residuo'] < creditori[j]['residuo']
          ? debitori[i]['residuo']
          : creditori[j]['residuo'];

      if (importo > 0.01) {
        trasferimenti.add({
          'da': debitori[i]['username'],
          'a': creditori[j]['username'],
          'importo': importo,
        });
      }

      debitori[i]['residuo'] -= importo;
      creditori[j]['residuo'] -= importo;

      if (debitori[i]['residuo'] < 0.01) i++;
      if (creditori[j]['residuo'] < 0.01) j++;
    }

    return trasferimenti;
  }

  Widget _buildTrasferimentoRow(Map<String, dynamic> trasf, NumberFormat formatCurrency) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Text(
              trasf['da'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 18, color: Colors.blue),
          ),
          Flexible(
            flex: 3,
            child: Text(
              trasf['a'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency.format(trasf['importo']),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
