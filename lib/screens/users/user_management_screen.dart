import 'package:flutter/material.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/screens/users/user_management/user_list_tab.dart';
import 'package:sexta_app/screens/users/user_management/user_status_tab.dart';
import 'package:sexta_app/screens/users/user_management/user_reports_tab.dart';

/// Módulo 9: Gestión de Usuarios
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: BrandedAppBar(
          title: 'Gestión de Usuarios',
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Estados'),
              Tab(icon: Icon(Icons.assessment), text: 'Reportes'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: const TabBarView(
          children: [
            UserListTab(),
            UserStatusTab(),
            UserReportsTab(),
          ],
        ),
      ),
    );
  }
}
