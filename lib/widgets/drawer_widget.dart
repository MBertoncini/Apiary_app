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
          DrawerHeader(
            decoration: BoxDecoration(color: ThemeConstants.primaryColor),
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
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
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    (user?.firstName?.isNotEmpty == true)
                        ? user!.firstName!
                        : (user?.username ?? 'Utente'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Impostazioni',
                  icon: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.settings, color: Colors.white, size: 20),
                  ),
                  onPressed: () => _navigateTo(context, AppConstants.settingsRoute),
                ),
              ],
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

          // Fioriture
          ListTile(
            leading: Icon(Icons.eco),
            title: Text('Fioriture'),
            selected: currentRoute == AppConstants.fioritureListRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.fioritureListRoute),
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

          // Vendite
          ListTile(
            leading: Icon(Icons.store),
            title: Text('Vendite'),
            selected: currentRoute == AppConstants.venditeRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.venditeRoute),
          ),

          // Statistiche & AI Analytics
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Row(
              children: [
                const Text('Statistiche & AI'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BETA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            selected: currentRoute == AppConstants.statisticheRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.statisticheRoute),
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

          // Inserimento vocale
          ListTile(
            leading: Icon(Icons.mic),
            title: Text('Inserimento vocale'),
            selected: currentRoute == AppConstants.voiceCommandRoute,
            selectedColor: ThemeConstants.primaryColor,
            onTap: () => _navigateTo(context, AppConstants.voiceCommandRoute),
          ),

          // Offrici un caffè
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF5A623).withOpacity(0.18),
                  const Color(0xFFF5A623).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Text('☕', style: TextStyle(fontSize: 20)),
              title: const Text(
                'Offrici un caffè',
                style: TextStyle(
                  color: Color(0xFFD4880A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: currentRoute == AppConstants.donazioneRoute,
              onTap: () => _navigateTo(context, AppConstants.donazioneRoute),
            ),
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