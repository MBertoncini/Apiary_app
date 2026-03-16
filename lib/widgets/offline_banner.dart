import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

/// Banner sottile mostrato in cima alle schermate quando il dispositivo è offline.
/// Si aggiorna automaticamente quando la connessione torna.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

    return StreamBuilder<bool>(
      stream: connectivityService.connectionChange,
      initialData: connectivityService.hasConnection,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isOnline
              ? const SizedBox.shrink()
              : Container(
                  key: const ValueKey('offline'),
                  width: double.infinity,
                  color: Colors.orange.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 15),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline – stai visualizzando dati salvati',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
