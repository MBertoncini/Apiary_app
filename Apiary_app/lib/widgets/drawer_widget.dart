import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  
  AppDrawer({required this.currentRoute});
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header con info utente
          UserAccountsDrawerHeader(
            accountName: Text(user?.fullName ?? 'Utente'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.username.isNotEmpty == true) 
                    ? user!.username[0].toUpperCase() 
                    : 'A',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ThemeConstants.primaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: ThemeConstants.primaryColor,
            ),
          ),
          
          // Dashboard
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            selected: currentRoute == AppConstants.dashboardRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != AppConstants.dashboardRoute) {
                Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
              }
            },
          ),
          
          // Apiari
          ListTile(
            leading: Icon(Icons.hive),
            title: Text('Apiari'),
            selected: currentRoute == AppConstants.apiarioListRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != AppConstants.apiarioListRoute) {
                Navigator.of(context).pushReplacementNamed(AppConstants.apiarioListRoute);
              }
            },
          ),
          
          // Arnie
          ListTile(
            leading: Icon(Icons.grid_view),
            title: Text('Arnie'),
            selected: currentRoute == AppConstants.arniaListRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != AppConstants.arniaListRoute) {
                Navigator.of(context).pushReplacementNamed(AppConstants.arniaListRoute);
              }
            },
          ),
          
          // Regine
          ListTile(
            leading: Icon(Icons.local_florist),
            title: Text('Regine'),
            selected: false,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              // TODO: navigazione alla lista regine
            },
          ),
          
          // Trattamenti
          ListTile(
            leading: Icon(Icons.medication),
            title: Text('Trattamenti sanitari'),
            selected: false,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              // TODO: navigazione alla lista trattamenti
            },
          ),
          
          // Melari
          ListTile(
            leading: Icon(Icons.view_module),
            title: Text('Melari e produzioni'),
            selected: false,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              // TODO: navigazione alla lista melari
            },
          ),
          
          // Divisore
          Divider(),
          
          // Gruppi
          ListTile(
            leading: Icon(Icons.group),
            title: Text('Gruppi'),
            selected: false,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              // TODO: navigazione alla lista gruppi
            },
          ),
          
          // Impostazioni
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Impostazioni'),
            selected: currentRoute == AppConstants.settingsRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != AppConstants.settingsRoute) {
                Navigator.of(context).pushNamed(AppConstants.settingsRoute);
              }
            },
          ),
          
          // Logout
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await authService.logout();
              Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
            },
          ),
        ],
      ),
    );
  }
}