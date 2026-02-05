import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  AppDrawer({required this.currentRoute});

  /// Naviga a una schermata dal drawer.
  /// - Se la destinazione è il dashboard, torna al dashboard rimuovendo tutto lo stack.
  /// - Se si è già sulla schermata corrente, chiude semplicemente il drawer.
  /// - Altrimenti, naviga alla schermata mantenendo il dashboard come radice dello stack.
  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context); // Chiude il drawer
    if (currentRoute == route) return; // Già sulla schermata

    if (route == AppConstants.dashboardRoute) {
      // Torna al dashboard rimuovendo tutto lo stack sopra
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.dashboardRoute,
        (r) => false,
      );
    } else {
      // Naviga alla schermata mantenendo il dashboard come base
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (r) => r.settings.name == AppConstants.dashboardRoute,
      );
    }
  }

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
            onTap: () => _navigateTo(context, AppConstants.dashboardRoute),
          ),

          // Apiari
          ListTile(
            leading: Icon(Icons.hive),
            title: Text('Apiari'),
            selected: currentRoute == AppConstants.apiarioListRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.apiarioListRoute),
          ),

          // Arnie
          ListTile(
            leading: Icon(Icons.grid_view),
            title: Text('Arnie'),
            selected: currentRoute == AppConstants.arniaListRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.arniaListRoute),
          ),

          // Mappa
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Mappa Apiari'),
            selected: currentRoute == AppConstants.mappaRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.mappaRoute),
          ),

          // Regine
          ListTile(
            leading: Icon(Icons.local_florist),
            title: Text('Regine'),
            selected: currentRoute == AppConstants.reginaListRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.reginaListRoute),
          ),

          // Trattamenti
          ListTile(
            leading: Icon(Icons.medication),
            title: Text('Trattamenti sanitari'),
            selected: currentRoute == AppConstants.trattamentiRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.trattamentiRoute),
          ),

          // Melari
          ListTile(
            leading: Icon(Icons.view_module),
            title: Text('Melari e produzioni'),
            selected: currentRoute == AppConstants.melariRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.melariRoute),
          ),

          // Attrezzature
          ListTile(
            leading: Icon(Icons.build),
            title: Text('Attrezzature'),
            selected: currentRoute == AppConstants.attrezzatureRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.attrezzatureRoute),
          ),

          // Divisore
          Divider(),

          // Gruppi
          ListTile(
            leading: Icon(Icons.group),
            title: Text('Gruppi'),
            selected: currentRoute == AppConstants.gruppiListRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.gruppiListRoute),
          ),

          // Pagamenti
          ListTile(
            leading: Icon(Icons.payments_outlined),
            title: Text('Pagamenti'),
            selected: currentRoute == AppConstants.pagamentiRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.pagamentiRoute),
          ),

          // Impostazioni
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Impostazioni'),
            selected: currentRoute == AppConstants.settingsRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.settingsRoute),
          ),

          // Voice command con Wit.ai
          Stack(
            children: [
              ListTile(
                leading: Icon(
                  Icons.mic,
                  color: currentRoute == AppConstants.voiceCommandRoute
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  'Inserimento vocale con Wit.ai',
                  style: TextStyle(
                    color: currentRoute == AppConstants.voiceCommandRoute
                        ? Theme.of(context).primaryColor
                        : null,
                    fontWeight: currentRoute == AppConstants.voiceCommandRoute
                        ? FontWeight.bold
                        : null,
                  ),
                ),
                onTap: () => _navigateTo(context, AppConstants.voiceCommandRoute),
              ),
              Positioned(
                right: 16,
                top: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Logout
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await authService.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppConstants.loginRoute,
                (r) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}