import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/drawer_widget.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _apiari = [];
  List<dynamic> _trattamenti = [];
  List<dynamic> _fioriture = [];
  DateTime _lastSyncTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Carica dati locali
      _apiari = await storageService.getStoredData('apiari');
      setState(() {});
      
      // Sincronizza con il server
      final lastSync = await storageService.getLastSyncTimestamp();
      final syncData = await apiService.syncData(lastSync: lastSync);
      await storageService.saveSyncData(syncData);
      
      // Aggiorna apiari con dati dal server
      if (syncData.containsKey('apiari')) {
        _apiari = syncData['apiari'];
      }
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento dei dati')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }