import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../widgets/drawer_widget.dart';
import 'dashboard/dashboard_tab.dart';
import 'query_builder/query_builder_tab.dart';
import 'nl_query/nl_query_tab.dart';

class StatisticheScreen extends StatelessWidget {
  static const routeName = '/statistiche';

  const StatisticheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: AppDrawer(currentRoute: routeName),
        appBar: AppBar(
          title: Text(s.statisticheTitle),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.dashboard_outlined), text: s.statisticheTabDashboard),
              Tab(icon: const Icon(Icons.filter_list), text: s.statisticheTabAnalisi),
              Tab(icon: const Icon(Icons.chat_bubble_outline), text: s.statisticheTabChiediAI),
            ],
          ),
        ),
        body: const TabBarView(
          // Disabilita lo swipe orizzontale per evitare che il PageView
          // del TabBarView rubi i gesti verticali alla ListView della dashboard.
          physics: NeverScrollableScrollPhysics(),
          children: [
            DashboardTab(),
            QueryBuilderTab(),
            NLQueryTab(),
          ],
        ),
      ),
    );
  }
}
