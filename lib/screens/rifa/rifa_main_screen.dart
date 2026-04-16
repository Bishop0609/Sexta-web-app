import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';

import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'rifa_config_screen.dart';

import 'rifa_dashboard_tab.dart';
import 'rifa_talonarios_tab.dart';
import 'rifa_bombero_tab.dart';
import 'rifa_reportes_tab.dart';

class RifaMainScreen extends StatefulWidget {
  const RifaMainScreen({super.key});

  @override
  State<RifaMainScreen> createState() => _RifaMainScreenState();
}

class _RifaMainScreenState extends State<RifaMainScreen> {
  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService().currentUser?.role == UserRole.admin;
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rifa 2026', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.institutionalRed,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RifaConfigScreen()),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Talonarios'),
              Tab(icon: Icon(Icons.people), text: 'Por Bombero'),
              Tab(icon: Icon(Icons.assessment), text: 'Reportes'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: const TabBarView(
          children: [
            RifaDashboardTab(),
            RifaTalonariosTab(),
            RifaBomberoTab(),
            RifaReportesTab(),
          ],
        ),
      ),
    );
  }
}
