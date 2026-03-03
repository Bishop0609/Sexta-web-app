import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/holiday_model.dart';
import 'package:sexta_app/services/holiday_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  final HolidayService _holidayService = HolidayService();
  int _selectedYear = DateTime.now().year;
  List<Holiday> _holidays = [];
  bool _isLoading = true;

  final List<int> _years = [2025, 2026, 2027, 2028];

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    try {
      final holidays = await _holidayService.getHolidaysByYear(_selectedYear);
      setState(() {
        _holidays = holidays..sort((a, b) => a.holidayDate.compareTo(b.holidayDate));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar feriados: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHoliday(Holiday holiday) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Feriado'),
        content: Text('¿Está seguro de eliminar "${holiday.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _holidayService.deleteHoliday(holiday.id!);
        _loadHolidays();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _addHoliday() async {
    final nameController = TextEditingController();
    DateTime? selectedDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Feriado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Feriado'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(_selectedYear, 1, 1),
                    firstDate: DateTime(_selectedYear, 1, 1),
                    lastDate: DateTime(_selectedYear, 12, 31),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(selectedDate == null 
                  ? 'Seleccionar Fecha' 
                  : DateFormat('dd/MM/yyyy').format(selectedDate!)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedDate != null && nameController.text.isNotEmpty) {
      try {
        await _holidayService.addHoliday(
          date: selectedDate!,
          name: nameController.text,          
        );
        _loadHolidays();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Feriados'),
        backgroundColor: AppTheme.institutionalRed,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Año:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _loadHolidays();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _holidays.isEmpty
                    ? const Center(child: Text('No hay feriados registrados para este año'))
                    : ListView.builder(
                        itemCount: _holidays.itemCount,
                        itemBuilder: (context, index) {
                          final holiday = _holidays[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.institutionalRed.withOpacity(0.1),
                                child: Text(
                                  DateFormat('dd').format(holiday.holidayDate),
                                  style: const TextStyle(color: AppTheme.institutionalRed, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(holiday.name),
                              subtitle: Text(
                                DateFormat('EEEE dd/MM', 'es').format(holiday.holidayDate),
                                style: const TextStyle(textBaseline: TextBaseline.alphabetic),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteHoliday(holiday),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHoliday,
        backgroundColor: AppTheme.institutionalRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

extension on List {
  int get itemCount => length;
}
