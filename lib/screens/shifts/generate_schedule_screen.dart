import 'package:flutter/material.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';

// TODO: Implement schedule generation with compliance algorithm and PDF export
class GenerateScheduleScreen extends StatelessWidget {
  const GenerateScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Generar Rol de Guardia'),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Module 7: Generate Schedule - To be implemented'),
      ),
    );
  }
}
