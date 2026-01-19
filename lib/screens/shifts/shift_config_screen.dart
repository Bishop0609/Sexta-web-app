import 'package:flutter/material.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';

// TODO: Implement shift configuration CRUD
class ShiftConfigScreen extends StatelessWidget {
  const ShiftConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Configurar Guardia'),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Module 5: Shift Configuration - To be implemented'),
      ),
    );
  }
}
