import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import 'dashboard/dashboard_tab.dart';
import 'query_builder/query_builder_tab.dart';
import 'nl_query/nl_query_tab.dart';

class StatisticheScreen extends StatelessWidget {
  static const routeName = '/statistiche';

  const StatisticheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: AppDrawer(currentRoute: routeName),
        appBar: AppBar(
          title: const Text('Statistiche'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
              Tab(icon: Icon(Icons.filter_list), text: 'Analisi'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chiedi AI'),
            ],
          ),
        ),
        body: const TabBarView(
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
