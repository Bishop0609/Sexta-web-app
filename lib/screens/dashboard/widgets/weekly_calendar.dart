import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/activity_model.dart';

/// Widget de calendario semanal para mostrar actividades
class WeeklyCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> activities;
  final Function(DateTime) onWeekChanged;
  final Function(Map<String, dynamic>) onActivityTap;

  const WeeklyCalendar({
    super.key,
    required this.activities,
    required this.onWeekChanged,
    required this.onActivityTap,
  });

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    // Lunes como primer día de la semana
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    widget.onWeekChanged(_currentWeekStart);
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    widget.onWeekChanged(_currentWeekStart);
  }

  void _goToToday() {
    setState(() {
      _currentWeekStart = _getWeekStart(DateTime.now());
    });
    widget.onWeekChanged(_currentWeekStart);
  }

  List<Map<String, dynamic>> _getActivitiesForDay(DateTime day) {
    final dayStr = day.toIso8601String().split('T')[0];
    return widget.activities
        .where((a) => a['activity_date'] == dayStr)
        .toList();
  }

  String _getMonthYearLabel() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final startMonth = DateFormat('MMMM').format(_currentWeekStart);
    final endMonth = DateFormat('MMMM').format(weekEnd);
    final year = _currentWeekStart.year;

    if (startMonth == endMonth) {
      return '$startMonth $year';
    } else {
      return '$startMonth - $endMonth $year';
    }
  }

  String _getWeekRangeLabel() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final start = DateFormat('d').format(_currentWeekStart);
    final end = DateFormat('d').format(weekEnd);
    return 'Semana del $start al $end';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.calendar_month, color: AppTheme.navyBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMonthYearLabel(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getWeekRangeLabel(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.today),
                  onPressed: _goToToday,
                  tooltip: 'Hoy',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousWeek,
                  tooltip: 'Semana anterior',
                ),
                const Text(
                  'Actividades de la Semana',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextWeek,
                  tooltip: 'Semana siguiente',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Calendario de 7 días con altura dinámica
            LayoutBuilder(
              builder: (context, constraints) {
                // Calcular altura máxima necesaria basada en el día con más actividades
                int maxActivities = 0;
                for (int i = 0; i < 7; i++) {
                  final day = _currentWeekStart.add(Duration(days: i));
                  final dayActivities = _getActivitiesForDay(day);
                  if (dayActivities.length > maxActivities) {
                    maxActivities = dayActivities.length;
                  }
                }
                
                // Altura base (header) + altura por actividad
                final double baseHeight = 50; // Header compacto
                final double activityHeight = 50; // Altura por actividad
                final double minHeight = 120;
                final double calculatedHeight = baseHeight + (maxActivities * activityHeight);
                final double finalHeight = calculatedHeight < minHeight ? minHeight : calculatedHeight;

                return SizedBox(
                  height: finalHeight,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final day = _currentWeekStart.add(Duration(days: index));
                      final activities = _getActivitiesForDay(day);
                      final isToday = DateFormat('yyyy-MM-dd').format(day) ==
                          DateFormat('yyyy-MM-dd').format(DateTime.now());

                      return _DayCard(
                        date: day,
                        activities: activities,
                        isToday: isToday,
                        onTap: (activity) => widget.onActivityTap(activity),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> activities;
  final bool isToday;
  final Function(Map<String, dynamic>) onTap;

  const _DayCard({
    required this.date,
    required this.activities,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const daysOfWeek = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayName = daysOfWeek[date.weekday - 1];
    final dayNumber = date.day;

    return Container(
      width: 140,  // Aumentado de 100 a 140
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? AppTheme.efectivaColor : Colors.grey[300]!,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          if (isToday)
            BoxShadow(
              color: AppTheme.efectivaColor.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compacto del día
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isToday ? AppTheme.efectivaColor : AppTheme.navyBlue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isToday ? AppTheme.efectivaColor : AppTheme.navyBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actividades
          Expanded(
            child: activities.isEmpty
                ? const Center(
                    child: Text(
                      'Sin actividades',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final type = activityTypeFromString(
                        activity['activity_type'] as String,
                      );
                      final title = activity['title'] as String;
                      final startTime = activity['start_time'] as String?;

                      // Color según tipo de actividad
                      Color backgroundColor;
                      Color borderColor;
                      
                      if (type == ActivityType.academiaCompania || 
                          type == ActivityType.academiaCuerpo) {
                        backgroundColor = Colors.blue[50]!;
                        borderColor = Colors.blue[200]!;
                      } else if (type == ActivityType.reunionOrdinaria ||
                                 type == ActivityType.reunionExtraordinaria) {
                        backgroundColor = Colors.purple[50]!;
                        borderColor = Colors.purple[200]!;
                      } else if (type == ActivityType.citacionCompania ||
                                 type == ActivityType.citacionCuerpo) {
                        backgroundColor = Colors.orange[50]!;
                        borderColor = Colors.orange[200]!;
                      } else {
                        backgroundColor = Colors.green[50]!;
                        borderColor = Colors.green[200]!;
                      }

                      return InkWell(
                        onTap: () => onTap(activity),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Título de la actividad
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Hora (si existe)
                              if (startTime != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 10,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      startTime.substring(0, 5),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
