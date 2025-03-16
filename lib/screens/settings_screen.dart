import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/drawer_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  String _lastSync = 'Mai';
  bool _isSyncing = false;
  int _cacheSize = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadSyncInfo();
  }
  
  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = AppConstants.appVersion;
      });
    }
  }
  
  Future<void> _loadSyncInfo() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final lastSyncTimestamp = await storageService.getLastSyncTimestamp();
      
      if (lastSyncTimestamp != null) {
        final lastSyncDate = DateTime.parse(lastSyncTimestamp);
        setState(() {
          _lastSync = '${lastSyncDate.day.toString().padLeft(2, '0')}/${lastSyncDate.month.toString().padLeft(2, '0')}/${lastSyncDate.year} ${lastSyncDate.hour.toString().padLeft(2, '0')}:${lastSyncDate.minute.toString().padLeft(2, '0')}';
        });
      }
      
      // Calcola dimensione cache approssimativa
      final apiari = await storageService.getStoredData('apiari');
      final arnie = await storageService.getStoredData('arnie');
      final controlli = await storageService.getStoredData('controlli');
      final regine = await storageService.getStoredData('regine');
      
      // Approssima 1KB per ogni elemento
      setState(() {
        _cacheSize = apiari.length + arnie.length + controlli.length + regine.length;
      });
    } catch (e) {
      print('Error loading sync info: $e');
    }
  }
  
  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Ottieni l'ultimo timestamp di sync
      final lastSync = await storageService.getLastSyncTimestamp();
      
      // Sincronizza dati
      final syncData = await apiService.syncData(lastSync: lastSync);
      await storageService.saveSyncData(syncData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sincronizzazione completata'),
          backgroundColor: ThemeConstants.successColor,
        ),
      );
      
      // Aggiorna info
      _loadSyncInfo();
    } catch (e) {
      print('Error during sync: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la sincronizzazione'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
  
  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancella cache'),
        content: Text('Sei sicuro di voler cancellare tutti i dati salvati? Dovrai sincronizzare nuovamente per recuperarli.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final storageService = Provider.of<StorageService>(context, listen: false);
              await storageService.clearDataCache();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cache cancellata'),
                  backgroundColor: ThemeConstants.successColor,
                ),
              );
              
              // Aggiorna info
              _loadSyncInfo();
            },
            child: Text('CONFERMA'),
            style: TextButton.styleFrom(
              foregroundColor: ThemeConstants.errorColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Sei sicuro di voler effettuare il logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
            },
            child: Text('LOGOUT'),
            style: TextButton.styleFrom(
              foregroundColor: ThemeConstants.errorColor,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Impostazioni'),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.settingsRoute),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profilo utente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profilo',
                    style: ThemeConstants.subheadingStyle,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: ThemeConstants.primaryColor,
                        child: Text(
                          (user?.username.isNotEmpty == true) 
                              ? user!.username[0].toUpperCase() 
                              : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Utente',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: ThemeConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _logout,
                    child: Text('LOGOUT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ThemeConstants.errorColor,
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Sincronizzazione
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sincronizzazione',
                    style: ThemeConstants.subheadingStyle,
                  ),
                  SizedBox(height: 16),
                  _buildSettingItem(
                    'Ultima sincronizzazione',
                    _lastSync,
                    Icons.sync,
                  ),
                  _buildSettingItem(
                    'Dimensione cache',
                    '${_cacheSize > 1024 ? (_cacheSize / 1024).toStringAsFixed(1) + ' MB' : _cacheSize.toString() + ' KB'}',
                    Icons.storage,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _syncData,
                          icon: _isSyncing 
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.sync),
                          label: Text('SINCRONIZZA ORA'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(0, 40),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _clearCache,
                        icon: Icon(Icons.delete_outline),
                        label: Text('CANCELLA CACHE'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Informazioni app
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informazioni',
                    style: ThemeConstants.subheadingStyle,
                  ),
                  SizedBox(height: 16),
                  _buildSettingItem(
                    'Versione app',
                    _appVersion,
                    Icons.info_outline,
                  ),
                  _buildSettingItem(
                    'Server API',
                    ApiConstants.baseUrl,
                    Icons.cloud_outlined,
                  ),
                  _buildSettingItem(
                    'Sviluppato da',
                    'Cible99',
                    Icons.code,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: ThemeConstants.textSecondaryColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}