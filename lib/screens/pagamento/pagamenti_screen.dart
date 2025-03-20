// lib/screens/pagamento/pagamenti_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/pagamento.dart';
import '../../services/pagamento_service.dart';
import '../../services/api_service.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPagamenti();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPagamenti() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);
      
      final pagamenti = await pagamentoService.getPagamenti();
      
      setState(() {
        _pagamenti = pagamenti;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il caricamento dei pagamenti: $e';
        _isLoading = false;
      });
    }
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
            Tab(text: 'Quote'),
          ],
        ),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.pagamentiRoute),
      body: TabBarView(
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
                .then((_) => _loadPagamenti());
          } else {
            Navigator.pushNamed(context, AppConstants.quoteRoute)
                .then((_) => _loadPagamenti());
          }
        },
        child: Icon(Icons.add),
        tooltip: _tabController.index == 0 ? 'Nuovo Pagamento' : 'Nuova Quota',
      ),
    );
  }
  
  Widget _buildPagamentiTab() {
    if (_isLoading) {
      return LoadingWidget();
    }
    
    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadPagamenti,
      );
    }
    
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
                    .then((_) => _loadPagamenti());
              },
            ),
          ],
        ),
      );
    }
    
    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');
    
    return RefreshIndicator(
      onRefresh: _loadPagamenti,
      child: ListView.builder(
        itemCount: _pagamenti.length,
        itemBuilder: (context, index) {
          final pagamento = _pagamenti[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(pagamento.descrizione),
              subtitle: Text('${pagamento.utenteUsername} - ${formatDate.format(DateTime.parse(pagamento.data))}'),
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
                ).then((_) => _loadPagamenti());
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildQuoteTab() {
    // Da implementare successivamente
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
            'Gestione Quote',
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
                  .then((_) => _loadPagamenti());
            },
          ),
        ],
      ),
    );
  }
}