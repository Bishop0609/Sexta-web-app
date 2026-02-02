import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// Widget reutilizable para filtros de reportes
class ReportFilters extends StatelessWidget {
  final String? selectedUserId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<UserModel> users;
  final Function(String?) onUserChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final bool showUserFilter;
  final bool showDateFilter;

  const ReportFilters({
    Key? key,
    this.selectedUserId,
    this.startDate,
    this.endDate,
    required this.users,
    required this.onUserChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.showUserFilter = true,
    this.showDateFilter = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (showUserFilter)
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String>(
                      value: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los usuarios'),
                        ),
                        ...users.map((user) => DropdownMenuItem<String>(
                              value: user.id,
                              child: Text(user.fullName),
                            )),
                      ],
                      onChanged: onUserChanged,
                    ),
                  ),
                if (showDateFilter) ...[
                  SizedBox(
                    width: 200,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          onStartDateChanged(date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Desde',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          startDate != null
                              ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                              : 'Sin filtro',
                          style: TextStyle(
                            color: startDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          onEndDateChanged(date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hasta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          endDate != null
                              ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                              : 'Sin filtro',
                          style: TextStyle(
                            color: endDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (selectedUserId != null || startDate != null || endDate != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  onUserChanged(null);
                  onStartDateChanged(null);
                  onEndDateChanged(null);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
