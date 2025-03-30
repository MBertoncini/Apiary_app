import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/paper_widgets.dart'; // Importa i nuovi widget in stile carta
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthService>(context, listen: false).refreshUserProfile();
    });
  }

  // Metodi esistenti per caricare le informazioni
  Future<void> _loadAppInfo() async {
    // Implementazione esistente invariata
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
    // Implementazione esistente invariata
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
      
      setState(() {
        _cacheSize = apiari.length + arnie.length + controlli.length + regine.length;
      });
    } catch (e) {
      print('Error loading sync info: $e');
    }
  }
  
  Future<void> _syncData() async {
    // Implementazione esistente invariata
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      final lastSync = await storageService.getLastSyncTimestamp();
      final syncData = await apiService.syncData(lastSync: lastSync);
      await storageService.saveSyncData(syncData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sincronizzazione completata'),
          backgroundColor: ThemeConstants.successColor,
        ),
      );
      
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
    // Implementazione esistente invariata
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancella cache', style: ThemeConstants.subheadingStyle),
        content: Text(
          'Sei sicuro di voler cancellare tutti i dati salvati? Dovrai sincronizzare nuovamente per recuperarli.',
          style: ThemeConstants.bodyStyle,
        ),
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
    // Implementazione esistente invariata
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: ThemeConstants.subheadingStyle),
        content: Text(
          'Sei sicuro di voler effettuare il logout?',
          style: ThemeConstants.bodyStyle,
        ),
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
        title: Text('Diario dell\'Apicoltore'),
        elevation: 4,
      ),
      drawer: AppDrawer(currentRoute: AppConstants.settingsRoute),
      body: Container(
        // Aggiungi texture leggera allo sfondo
        decoration: BoxDecoration(
          color: ThemeConstants.backgroundColor,
          image: ThemeConstants.paperBackgroundTexture,
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            DiaryTitle(title: 'Impostazioni'),
            
            // Profilo utente
            PaperCard(
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
                      // Avatar personalizzato in stile diario
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeConstants.primaryColor.withOpacity(0.2),
                          border: Border.all(
                            color: ThemeConstants.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (user?.username.isNotEmpty == true) 
                                ? user!.username[0].toUpperCase() 
                                : 'U',
                            style: GoogleFonts.caveat(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.secondaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? user?.username ?? 'Apicoltore',
                              style: ThemeConstants.handwrittenNotes.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: ThemeConstants.bodyStyle.copyWith(
                                color: ThemeConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  DiaryButton(
                    label: 'Esci',
                    onPressed: _logout,
                    icon: Icons.exit_to_app,
                    color: ThemeConstants.errorColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Sincronizzazione
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sincronizzazione',
                    style: ThemeConstants.subheadingStyle,
                  ),
                  SizedBox(height: 16),
                  _buildDiarySettingItem(
                    'Ultima sincronizzazione',
                    _lastSync,
                    Icons.sync,
                  ),
                  _buildDiarySettingItem(
                    'Dimensione cache',
                    '${_cacheSize > 1024 ? (_cacheSize / 1024).toStringAsFixed(1) + ' MB' : _cacheSize.toString() + ' KB'}',
                    Icons.storage,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DiaryButton(
                          label: 'Sincronizza',
                          onPressed: _isSyncing ? null : _syncData,
                          icon: _isSyncing ? null : Icons.sync,
                          color: ThemeConstants.primaryColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      DiaryButton(
                        label: 'Cancella Cache',
                        onPressed: _clearCache,
                        icon: Icons.delete_outline,
                        color: ThemeConstants.secondaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Informazioni app
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informazioni',
                    style: ThemeConstants.subheadingStyle,
                  ),
                  SizedBox(height: 16),
                  _buildDiarySettingItem(
                    'Versione app',
                    _appVersion,
                    Icons.info_outline,
                  ),
                  _buildDiarySettingItem(
                    'Server API',
                    ApiConstants.baseUrl,
                    Icons.cloud_outlined,
                  ),
                  _buildDiarySettingItem(
                    'Sviluppato da',
                    'Cible99',
                    Icons.code,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiarySettingItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: ThemeConstants.secondaryColor.withOpacity(0.8),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ThemeConstants.bodyStyle.copyWith(
                    fontSize: 14,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: ThemeConstants.handwrittenNotes.copyWith(
                    fontSize: 18,
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