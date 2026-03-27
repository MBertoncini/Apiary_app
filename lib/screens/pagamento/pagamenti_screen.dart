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
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/offline_banner.dart';

class PagamentiScreen extends StatefulWidget {
  @override
  _PagamentiScreenState createState() => _PagamentiScreenState();
}

class _PagamentiScreenState extends State<PagamentiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Pagamento> _pagamenti = [];
  List<QuotaUtente> _quote = [];
  bool _isRefreshing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    setState(() { _errorMessage = null; });

    final storageService = Provider.of<StorageService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final pagamentoService = PagamentoService(apiService);

    // Phase 1: cache
    final cachedPagamenti = await storageService.getStoredData('pagamenti');
    final cachedQuote = await storageService.getStoredData('quote');
    if (cachedPagamenti.isNotEmpty || cachedQuote.isNotEmpty) {
      if (cachedPagamenti.isNotEmpty) _pagamenti = cachedPagamenti.map((e) => Pagamento.fromJson(e as Map<String, dynamic>)).toList();
      if (cachedQuote.isNotEmpty) _quote = cachedQuote.map((e) => QuotaUtente.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Phase 2: API
    try {
      final pagamenti = await pagamentoService.getPagamenti();
      final quote = await pagamentoService.getQuote();
      await storageService.saveData('pagamenti', pagamenti.map((p) => p.toJson()).toList());
      await storageService.saveData('quote', quote.map((q) => q.toJson()).toList());
      _pagamenti = pagamenti;
      _quote = quote;
    } catch (e) {
      debugPrint('Errore API pagamenti: $e');
      if (_pagamenti.isEmpty && _quote.isEmpty) {
        _errorMessage = 'Errore durante il caricamento dei dati: $e';
      }
    }

    if (mounted) setState(() { _isRefreshing = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Pagamenti'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pagamenti'),
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
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isRefreshing && _pagamenti.isEmpty && _quote.isEmpty
                ? const SizedBox.shrink()
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _loadData,
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPagamentiTab(),
                          _buildBilancioTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.pagamentoCreateRoute)
                    .then((_) => _loadData());
              },
              child: Icon(Icons.add),
              tooltip: 'Nuovo Pagamento',
            )
          : null,
    );
  }

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
            final isSaldo = pagamento.isSaldo;

            Color leadingColor = isSaldo
                ? Colors.blue
                : isAttrezzatura
                    ? Colors.cyan
                    : ThemeConstants.primaryColor;

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Row(
                  children: [
                    if (isSaldo)
                      Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: 'Saldo bilancio',
                          child: Icon(Icons.swap_horiz, size: 16, color: Colors.blue),
                        ),
                      )
                    else if (isAttrezzatura)
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
                  isSaldo
                      ? '${pagamento.utenteUsername} → ${pagamento.destinatarioUsername} · ${formatDate.format(DateTime.parse(pagamento.data))}'
                      : '${pagamento.utenteUsername} · ${formatDate.format(DateTime.parse(pagamento.data))}',
                  maxLines: 1,
                ),
                trailing: Text(
                  formatCurrency.format(pagamento.importo),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: leadingColor,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: leadingColor.withOpacity(0.1),
                  child: Icon(
                    isSaldo
                        ? Icons.swap_horiz
                        : isAttrezzatura
                            ? Icons.build
                            : Icons.euro,
                    color: leadingColor,
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
    final gruppoNome = quoteGruppo.first.gruppoNome ?? 'Gruppo $gruppoId';

    // Tutti i pagamenti del gruppo
    final pagamentiGruppo = _pagamenti.where((p) => p.gruppo == gruppoId).toList();

    // Pagamenti di saldo (trasferimento diretto tra membri): esclusi dal totale spese
    final pagamentiSaldo = pagamentiGruppo.where((p) => p.isSaldo).toList();
    // Pagamenti ordinari: costituiscono le spese reali del gruppo
    final pagamentiRegolari = pagamentiGruppo.where((p) => !p.isSaldo).toList();

    final double totalePagamentiGruppo = pagamentiRegolari.fold(0.0, (sum, p) => sum + p.importo);

    final List<Map<String, dynamic>> bilancioMembri = [];

    for (var quota in quoteGruppo) {
      final double totalePagato = pagamentiRegolari
          .where((p) => p.utente == quota.utente)
          .fold(0.0, (sum, p) => sum + p.importo);

      final double dovuto = totalePagamentiGruppo * (quota.percentuale / 100.0);
      double saldo = totalePagato - dovuto;

      // Aggiusta il saldo con i pagamenti di saldo: chi paga migliora il suo saldo,
      // chi riceve riduce il suo credito
      for (var sp in pagamentiSaldo) {
        if (sp.utente == quota.utente) {
          saldo += sp.importo; // il pagante ha saldato il debito
        } else if (sp.destinatario == quota.utente) {
          saldo -= sp.importo; // il destinatario ha ricevuto, il suo credito scende
        }
      }

      bilancioMembri.add({
        'utenteId': quota.utente,
        'username': quota.utenteUsername,
        'percentuale': quota.percentuale,
        'totalePagato': totalePagato,
        'dovuto': dovuto,
        'saldo': saldo,
      });
    }

    final trasferimenti = _calcolaTrasferimenti(bilancioMembri);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del gruppo con tooltip quote
            Row(
              children: [
                Icon(Icons.group, color: ThemeConstants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gruppoNome,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Tooltip(
                  message: 'Gestisci quote',
                  child: InkWell(
                    onTap: () => _showQuotePopup(context, quoteGruppo, gruppoId),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pie_chart, size: 14, color: ThemeConstants.textSecondaryColor),
                          const SizedBox(width: 2),
                          Text(
                            'Quote',
                            style: TextStyle(fontSize: 11, color: ThemeConstants.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Totale spese gruppo: ${formatCurrency.format(totalePagamentiGruppo)}',
              style: TextStyle(color: ThemeConstants.textSecondaryColor, fontSize: 14),
            ),
            const Divider(height: 24),

            for (var membro in bilancioMembri) ...[
              _buildMembroBilancioRow(membro, formatCurrency),
              const SizedBox(height: 8),
            ],

            if (trasferimenti.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Trasferimenti necessari',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (var trasf in trasferimenti)
                _buildTrasferimentoRow(trasf, gruppoId, formatCurrency),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuotePopup(BuildContext context, List<QuotaUtente> quote, int gruppoId) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: ThemeConstants.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text('Quote gruppo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(Icons.edit, size: 14),
                  label: Text('Gestisci', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppConstants.quoteRoute)
                        .then((_) => _loadData());
                  },
                ),
              ],
            ),
            const Divider(),
            ...quote.map((q) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: ThemeConstants.primaryColor,
                    child: Text(
                      q.utenteUsername.isNotEmpty ? q.utenteUsername[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(q.utenteUsername)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${q.percentuale}%',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: ThemeConstants.secondaryColor),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
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

  List<Map<String, dynamic>> _calcolaTrasferimenti(List<Map<String, dynamic>> bilancioMembri) {
    final List<Map<String, dynamic>> creditori = [];
    final List<Map<String, dynamic>> debitori = [];

    for (var membro in bilancioMembri) {
      final double saldo = membro['saldo'];
      if (saldo > 0.01) {
        creditori.add({...membro, 'residuo': saldo});
      } else if (saldo < -0.01) {
        debitori.add({...membro, 'residuo': -saldo});
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
          'daId': debitori[i]['utenteId'],
          'a': creditori[j]['username'],
          'aId': creditori[j]['utenteId'],
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

  Widget _buildTrasferimentoRow(Map<String, dynamic> trasf, int gruppoId, NumberFormat formatCurrency) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
          ),
          Flexible(
            flex: 3,
            child: Text(
              trasf['a'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatCurrency.format(trasf['importo']),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Registra pagamento di saldo',
            child: InkWell(
              onTap: () => _registraSaldoPagamento(trasf, gruppoId),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_circle_outline, size: 16, color: Colors.blue.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _registraSaldoPagamento(Map<String, dynamic> trasf, int gruppoId) {
    Navigator.pushNamed(
      context,
      AppConstants.pagamentoCreateRoute,
      arguments: {
        'isSaldo': true,
        'gruppoId': gruppoId,
        'utenteId': trasf['daId'],
        'destinatarioId': trasf['aId'],
        'importo': trasf['importo'],
        'descrizione': 'Saldo bilancio: ${trasf['da']} → ${trasf['a']}',
      },
    ).then((_) => _loadData());
  }
}
