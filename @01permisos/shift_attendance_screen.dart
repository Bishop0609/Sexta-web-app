import 'package:flutter/material.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';

// TODO: Implement shift check-in, replacements, and extra firefighters
class ShiftAttendanceScreen extends StatelessWidget {
  const ShiftAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Asistencia Guardia'),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Module 8: Shift Attendance - To be implemented'),
      ),
    );
  }
}
