import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'utils/route_generator.dart';
import 'constants/app_constants.dart';
import 'constants/theme_constants.dart';
import 'screens/splash_screen.dart';

class ApiarioManagerApp extends StatelessWidget {
  Future<void> _refreshData() async {
    await _loadData();
  }
  
  void _navigateToApiarioDetail(int apiarioId) {
    Navigator.of(context).pushNamed(
      AppConstants.apiarioDetailRoute,
      arguments: apiarioId,
    );
  }
  
  void _navigateToApiarioCreate() {
    Navigator.of(context).pushNamed(AppConstants.apiarioCreateRoute);
  }
  
  String _formatLastSync() {
    return "${_lastSyncTime.day.toString().padLeft(2, '0')}/${_lastSyncTime.month.toString().padLeft(2, '0')}/${_lastSyncTime.year} ${_lastSyncTime.hour.toString().padLeft(2, '0')}:${_lastSyncTime.minute.toString().padLeft(2, '0')}";
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ThemeConstants.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildApiarioCard(dynamic apiario) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _navigateToApiarioDetail(apiario['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      apiario['nome'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                apiario['posizione'] ?? 'Posizione non specificata',
                style: TextStyle(
                  color: ThemeConstants.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrattamentoCard(dynamic trattamento) {
    // Formatta le date
    String dataInizio = trattamento['data_inizio'] ?? 'N/D';
    String dataFine = trattamento['data_fine'] ?? 'In corso';
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trattamento['tipo_trattamento_nome'] ?? 'Trattamento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trattamento['stato'] == 'in_corso' 
                        ? Colors.orange.withOpacity(0.2) 
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trattamento['stato'] == 'in_corso' 
                        ? 'In corso' 
                        : trattamento['stato'] == 'programmato'
                            ? 'Programmato'
                            : 'Completato',
                    style: TextStyle(
                      fontSize: 12,
                      color: trattamento['stato'] == 'in_corso' 
                          ? Colors.orange.shade800 
                          : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: ThemeConstants.textSecondaryColor),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trattamento['apiario_nome'] ?? 'Apiario',
                    style: TextStyle(color: ThemeConstants.textSecondaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: ThemeConstants.textSecondaryColor),
                SizedBox(width: 4),
                Text(
                  'Dal $dataInizio al $dataFine',
                  style: TextStyle(color: ThemeConstants.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiorituraCard(dynamic fioritura) {
    bool isActive = fioritura['is_active'] ?? false;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fioritura['pianta'] ?? 'Fioritura',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Attiva' : 'Terminata',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (fioritura['apiario_nome'] != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: ThemeConstants.textSecondaryColor),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      fioritura['apiario_nome'],
                      style: TextStyle(color: ThemeConstants.textSecondaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: ThemeConstants.textSecondaryColor),
                SizedBox(width: 4),
                Text(
                  'Dal ${fioritura['data_inizio']} ${fioritura['data_fine'] != null ? 'al ${fioritura['data_fine']}' : ''}',
                  style: TextStyle(color: ThemeConstants.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getActiveTrattamentiCount() {
    return _trattamenti.where((t) => 
      t['stato'] == 'in_corso' || t['stato'] == 'programmato').length;
  }
  
  int _getActiveFioritureCount() {
    return _fioriture.where((f) => f['is_active'] == true).length;
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.dashboardRoute),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Benvenuto
                    Text(
                      'Benvenuto, ${user?.fullName ?? 'Apicoltore'}',
                      style: ThemeConstants.headingStyle,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ultima sincronizzazione: ${_formatLastSync()}',
                      style: TextStyle(
                        color: ThemeConstants.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Riepilogo
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Apiari',
                            _apiari.length.toString(),
                            Icons.hive,
                            ThemeConstants.primaryColor,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Trattamenti attivi',
                            _getActiveTrattamentiCount().toString(),
                            Icons.medication,
                            Colors.orange,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Fioriture attive',
                            _getActiveFioritureCount().toString(),
                            Icons.local_florist,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    
                    // Apiari
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'I tuoi apiari',
                          style: ThemeConstants.subheadingStyle,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppConstants.apiarioListRoute);
                          },
                          child: Text('Vedi tutti'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    if (_apiari.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.hive_outlined,
                                size: 48,
                                color: ThemeConstants.textSecondaryColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nessun apiario disponibile',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _navigateToApiarioCreate,
                                child: Text('Crea nuovo apiario'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var i = 0; i < _apiari.length && i < 3; i++)
                            _buildApiarioCard(_apiari[i]),
                          if (_apiari.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(AppConstants.apiarioListRoute);
                                },
                                child: Text('Vedi tutti gli apiari'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 44),
                                ),
                              ),
                            ),
                        ],
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Trattamenti sanitari
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trattamenti sanitari attivi',
                          style: ThemeConstants.subheadingStyle,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to trattamenti list
                          },
                          child: Text('Vedi tutti'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    if (_getActiveTrattamentiCount() == 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 48,
                                color: ThemeConstants.textSecondaryColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nessun trattamento attivo',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var trattamento in _trattamenti.where((t) => 
                            t['stato'] == 'in_corso' || t['stato'] == 'programmato').take(3))
                            _buildTrattamentoCard(trattamento),
                        ],
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Fioriture
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fioriture attive',
                          style: ThemeConstants.subheadingStyle,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to fioriture list
                          },
                          child: Text('Vedi tutte'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    if (_getActiveFioritureCount() == 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.local_florist_outlined,
                                size: 48,
                                color: ThemeConstants.textSecondaryColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nessuna fioritura attiva',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var fioritura in _fioriture.where((f) => f['is_active'] == true).take(3))
                            _buildFiorituraCard(fioritura),
                        ],
                      ),
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToApiarioCreate,
        child: Icon(Icons.add),
        tooltip: 'Aggiungi apiario',
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService),
        ),
        Provider(create: (_) => StorageService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeConstants.getTheme(),
        onGenerateRoute: RouteGenerator.generateRoute,
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
