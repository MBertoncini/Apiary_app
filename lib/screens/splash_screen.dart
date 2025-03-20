import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../screens/disclaimer_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }
  
  Future<void> _checkAuthentication() async {
    // Attendi che inizializzi il provider
    await Future.delayed(Duration(milliseconds: 100));
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    // Attendi il completamento della verifica token
    while (authService.isLoading) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    // Mostra splash per almeno 2 secondi
    await Future.delayed(Duration(seconds: 2));
    
    // Verifica se l'utente ha già accettato il disclaimer
    final hasAcceptedDisclaimer = await storageService.hasAcceptedDisclaimer();
    
    if (!hasAcceptedDisclaimer) {
      // Mostra il disclaimer
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DisclaimerScreen(
            isFirstLogin: !authService.isAuthenticated,
          ),
        ),
      );
      return;
    }
    
    // Procedi con il flusso normale
    if (authService.isAuthenticated) {
      // Utente autenticato, carica dati iniziali
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        
        // Ottieni l'ultimo timestamp di sync
        final lastSync = await storageService.getLastSyncTimestamp();
        
        // Sincronizza dati
        final syncData = await apiService.syncData(lastSync: lastSync);
        await storageService.saveSyncData(syncData);
      } catch (e) {
        print('Error during initial sync: $e');
      }
      
      Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
    } else {
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hive,
                size: 80,
                color: ThemeConstants.primaryColor,
              ),
            ),
            SizedBox(height: 32),
            
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 16),
            
            Text(
              'Gestisci i tuoi apiari ovunque',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            SizedBox(height: 48),
            
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}