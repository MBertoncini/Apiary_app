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
import '../../services/auth_service.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
          await ApiCacheHelper.saveToCache('pagamenti', _pagamenti);
          await ApiCacheHelper.saveToCache('quote', _quote);
        } catch (e) {
          print('Errore API, utilizzo cache: $e');
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
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.pushNamed(context, AppConstants.pagamentoCreateRoute)
                .then((_) => _loadData());
          } else {
            Navigator.pushNamed(context, AppConstants.quoteRoute)
                .then((_) => _loadData());
          }
        },
        child: Icon(Icons.add),
        tooltip: _tabController.index == 0 ? 'Nuovo Pagamento' : 'Nuova Quota',
      ),
    );
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
            SizedBox(height: 16),
            Text(
              'Nessun pagamento registrato',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
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
    
    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _pagamenti.length,
        itemBuilder: (context, index) {
          final pagamento = _pagamenti[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                pagamento.descrizione,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                backgroundColor: ThemeConstants.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.euro,
                  color: ThemeConstants.primaryColor,
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
        },
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
            SizedBox(height: 16),
            Text(
              'Nessuna quota trovata',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
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
}