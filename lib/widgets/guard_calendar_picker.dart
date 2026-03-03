import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';

/// Calendar picker widget for selecting multiple dates
/// Used for guard availability registration
class GuardCalendarPicker extends StatefulWidget {
  final DateTime? initialMonth;
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Map<String, Map<String, dynamic>>? dateCapacity;
  final String? userGender;

  const GuardCalendarPicker({
    super.key,
    this.initialMonth,
    required this.selectedDates,
    required this.onDatesChanged,
    this.minDate,
    this.maxDate,
    this.dateCapacity,
    this.userGender,
  });

  @override
  State<GuardCalendarPicker> createState() => _GuardCalendarPickerState();
}

class _GuardCalendarPickerState extends State<GuardCalendarPicker> {
  late DateTime _currentMonth;
  late List<DateTime> _selectedDates;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth ?? DateTime.now();
    _selectedDates = List.from(widget.selectedDates);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final index = _selectedDates.indexWhere((d) =>
          d.year == dateOnly.year &&
          d.month == dateOnly.month &&
          d.day == dateOnly.day);

      if (index >= 0) {
        _selectedDates.removeAt(index);
      } else {
        _selectedDates.add(dateOnly);
      }
      
      widget.onDatesChanged(_selectedDates);
    });
  }

  bool _isDateSelected(DateTime date) {
    return _selectedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) {
      return true;
    }
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) {
      return true;
    }
    
    // Check capacity restrictions
    if (widget.dateCapacity != null && widget.userGender != null) {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final capacity = widget.dateCapacity![dateKey];
      
      if (capacity != null) {
        final total = capacity['total'] as int? ?? 0;
        final males = capacity['males'] as int? ?? 0;
        final females = capacity['females'] as int? ?? 0;
        
        // Día completo
        if (total >= 10) return true;
        
        // Sin cupo para género del usuario
        if (widget.userGender == 'M' && males >= 6) return true;
        if (widget.userGender == 'F' && females >= 4) return true;
      }
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy', 'es_ES').format(_currentMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            day,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Calendar grid
            _buildCalendarGrid(),

            const SizedBox(height: 16),

            // Selected dates summary
            if (_selectedDates.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '${_selectedDates.length} fecha(s) seleccionada(s)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.navyBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDayOfMonth.weekday;

    // Calculate total cells needed
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = firstWeekday - 1 + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - (firstWeekday - 2);

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 40, height: 40);
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isSelected = _isDateSelected(date);
              final isDisabled = _isDateDisabled(date);
              final isToday = _isToday(date);
              
              // Get capacity info
              String? capacityLabel;
              Color? capacityColor;
              if (widget.dateCapacity != null && widget.userGender != null) {
                final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final capacity = widget.dateCapacity![dateKey];
                
                if (capacity != null) {
                  final total = capacity['total'] as int? ?? 0;
                  final males = capacity['males'] as int? ?? 0;
                  final females = capacity['females'] as int? ?? 0;
                  
                  if (total >= 10) {
                    capacityColor = Colors.red.shade100;
                    capacityLabel = 'Completo';
                  } else if (widget.userGender == 'M' && males >= 6) {
                    capacityColor = Colors.orange.shade100;
                    capacityLabel = 'Sin cupo';
                  } else if (widget.userGender == 'F' && females >= 4) {
                    capacityColor = Colors.orange.shade100;
                    capacityLabel = 'Sin cupo';
                  } else {
                    capacityColor = Colors.green.shade50;
                    capacityLabel = '$total/10';
                  }
                }
              }

              return InkWell(
                onTap: isDisabled ? null : () => _toggleDate(date),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.navyBlue
                        : capacityColor ?? (isToday
                            ? AppTheme.navyBlue.withOpacity(0.1)
                            : null),
                    borderRadius: BorderRadius.circular(20),
                    border: isToday && !isSelected
                        ? Border.all(color: AppTheme.navyBlue, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isDisabled
                              ? Colors.grey.shade400
                              : isSelected
                                  ? Colors.white
                                  : isToday
                                      ? AppTheme.navyBlue
                                      : Colors.black87,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      if (capacityLabel != null && !isSelected)
                        Text(
                          capacityLabel,
                          style: TextStyle(
                            fontSize: 8,
                            color: isDisabled ? Colors.grey.shade400 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
