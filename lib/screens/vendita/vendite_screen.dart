import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../models/vendita.dart';
import '../../models/cliente.dart';

class VenditeScreen extends StatefulWidget {
  @override
  _VenditeScreenState createState() => _VenditeScreenState();
}

class _VenditeScreenState extends State<VenditeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;
  List<Vendita> _vendite = [];
  List<Cliente> _clienti = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { setState(() {}); });
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final venditeRes = await _apiService.get(ApiConstants.venditeUrl);
      final clientiRes = await _apiService.get(ApiConstants.clientiUrl);
      setState(() {
        _vendite = (venditeRes as List).map((e) => Vendita.fromJson(e)).toList();
        _clienti = (clientiRes as List).map((e) => Cliente.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = 'Errore: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendite'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Vendite'), Tab(text: 'Clienti')],
        ),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadData)],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.venditeRoute),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_errorMessage!), SizedBox(height: 8),
                  ElevatedButton(onPressed: _loadData, child: Text('Riprova')),
                ]))
              : TabBarView(
                  controller: _tabController,
                  children: [_buildVenditeTab(), _buildClientiTab()],
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.pushNamed(context, AppConstants.venditaCreateRoute).then((_) => _loadData());
          } else {
            Navigator.pushNamed(context, AppConstants.clienteCreateRoute).then((_) => _loadData());
          }
        },
      ),
    );
  }

  Widget _buildVenditeTab() {
    if (_vendite.isEmpty) {
      return Center(child: Text('Nessuna vendita registrata', style: TextStyle(fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _vendite.length,
        itemBuilder: (context, index) {
          final v = _vendite[index];
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.receipt_long, color: ThemeConstants.primaryColor),
              title: Text(v.clienteNome ?? 'Cliente #${v.cliente}'),
              subtitle: Text('${v.data} - ${v.dettagli.length} articoli'),
              trailing: Text('${v.totale?.toStringAsFixed(2) ?? '0.00'} \u20AC',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () => Navigator.pushNamed(context, AppConstants.venditaDetailRoute, arguments: v.id).then((_) => _loadData()),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientiTab() {
    if (_clienti.isEmpty) {
      return Center(child: Text('Nessun cliente registrato', style: TextStyle(fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _clienti.length,
        itemBuilder: (context, index) {
          final c = _clienti[index];
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.person, color: ThemeConstants.primaryColor),
              title: Text(c.nome),
              subtitle: Text([if (c.telefono != null) c.telefono!, if (c.email != null) c.email!].join(' - ')),
              trailing: Text('${c.venditeCount ?? 0} vendite'),
              onTap: () => Navigator.pushNamed(context, AppConstants.clienteCreateRoute, arguments: c.id).then((_) => _loadData()),
            ),
          );
        },
      ),
    );
  }
}
