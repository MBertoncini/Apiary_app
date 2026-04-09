import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../services/language_service.dart';
import '../../../../../widgets/skeleton_widgets.dart';

/// Wrapper riutilizzabile per tutti i widget del dashboard.
/// Gestisce uniformemente i tre stati: loading (shimmer), errore (retry), contenuto.
class DashboardCardBase extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;
  final double loadingHeight;

  const DashboardCardBase({
    super.key,
    required this.icon,
    required this.title,
    required this.loading,
    this.error,
    required this.onRetry,
    required this.child,
    this.loadingHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: onRetry,
                ),
              ],
            ),
            const Divider(),
            if (loading)
              SkeletonDashboardContent(height: loadingHeight)
            else if (error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Builder(builder: (context) {
                    final s = Provider.of<LanguageService>(context, listen: false).strings;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          s.dashboardErrCaricamento,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        TextButton(
                          onPressed: onRetry,
                          child: Text(s.btnRetry),
                        ),
                      ],
                    );
                  }),
                ),
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}
