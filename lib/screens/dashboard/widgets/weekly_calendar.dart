import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/activity_model.dart';

/// Widget de calendario semanal responsive para mostrar actividades
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

/// Modos de visualización del calendario según tamaño de pantalla
enum CalendarMode { desktop, tablet, mobile }

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es_ES', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  static DateTime _getWeekStart(DateTime date) {
    // Lunes como primer día de la semana
    return date.subtract(Duration(days: date.weekday - 1));
  }

  CalendarMode _getCalendarMode(double width) {
    if (width > 1200) return CalendarMode.desktop;
    if (width >= 768) return CalendarMode.tablet;
    return CalendarMode.mobile;
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
    if (!_localeInitialized) return '';
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final startMonth = DateFormat('MMMM', 'es_ES').format(_currentWeekStart);
    final endMonth = DateFormat('MMMM', 'es_ES').format(weekEnd);
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
    if (!_localeInitialized) {
      return const Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final mode = _getCalendarMode(screenWidth);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),

            // Navegación
            _buildNavigation(),
            const SizedBox(height: 12),

            // Calendario (responsive)
            mode == CalendarMode.mobile
                ? _buildMobileVerticalView()
                : _buildHorizontalView(mode, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildNavigation() {
    return Row(
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
    );
  }

  /// Vista horizontal para Desktop y Tablet
  Widget _buildHorizontalView(CalendarMode mode, double screenWidth) {
    // Calcular altura máxima necesaria
    int maxActivities = 0;
    for (int i = 0; i < 7; i++) {
      final day = _currentWeekStart.add(Duration(days: i));
      final dayActivities = _getActivitiesForDay(day);
      if (dayActivities.length > maxActivities) {
        maxActivities = dayActivities.length;
      }
    }

    // Altura dinámica según cantidad de actividades
    final double baseHeight = 60;  // Header del día
    final double activityHeight = 65;  // Altura por cada actividad (aumentado de 50 a 65)
    final double minHeight = 140;  // Altura mínima
    final double padding = 10;  // Margen de seguridad adicional
    final double calculatedHeight = baseHeight + (maxActivities * activityHeight) + padding;
    final double finalHeight = calculatedHeight < minHeight ? minHeight : calculatedHeight;

    // Calcular ancho por día según modo usando LayoutBuilder
    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxWidth es el ancho REAL disponible dentro del Card
        final containerWidth = constraints.maxWidth;
        
        double dayWidth;
        if (mode == CalendarMode.desktop) {
          dayWidth = 140; // Ancho fijo para desktop
        } else {
          // Tablet: calcular para que quepan exactamente 7 días
          // containerWidth ya tiene el padding del Card descontado
          // Solo descontar márgenes entre días: 8px * 7 = 56px
          final availableWidth = containerWidth - 56;
          dayWidth = availableWidth / 7.0;
          
          // No permitir más ancho que desktop
          if (dayWidth > 140) dayWidth = 140;
        }

        return SizedBox(
          height: finalHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: mode == CalendarMode.tablet 
                ? const NeverScrollableScrollPhysics()  // Deshabilitar scroll en tablet
                : null,  // Scroll normal en desktop
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
                width: dayWidth,
                onTap: (activity) => widget.onActivityTap(activity),
              );
            },
          ),
        );
      },
    );
  }

  /// Vista vertical para Móvil
  Widget _buildMobileVerticalView() {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    return Column(
      children: List.generate(7, (index) {
        final day = _currentWeekStart.add(Duration(days: index));
        final activities = _getActivitiesForDay(day);
        final dayStr = DateFormat('yyyy-MM-dd').format(day);
        final isToday = dayStr == todayStr;

        return _MobileDayTile(
          date: day,
          activities: activities,
          isToday: isToday,
          initiallyExpanded: isToday,
          onActivityTap: widget.onActivityTap,
        );
      }),
    );
  }
}

/// Card de día para vista horizontal (Desktop/Tablet)
class _DayCard extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> activities;
  final bool isToday;
  final double width;
  final Function(Map<String, dynamic>) onTap;

  const _DayCard({
    required this.date,
    required this.activities,
    required this.isToday,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const daysOfWeek = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayName = daysOfWeek[date.weekday - 1];
    final dayNumber = date.day;

    return Container(
      width: width,
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
              color: AppTheme.efectivaColor.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del día
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
                      return _ActivityChip(
                        activity: activities[index],
                        onTap: onTap,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tile expandible para vista móvil
class _MobileDayTile extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> activities;
  final bool isToday;
  final bool initiallyExpanded;
  final Function(Map<String, dynamic>) onActivityTap;

  const _MobileDayTile({
    required this.date,
    required this.activities,
    required this.isToday,
    required this.initiallyExpanded,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    const daysOfWeek = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final dayName = daysOfWeek[date.weekday - 1];
    final dayNumber = date.day;
    final monthName = DateFormat('MMMM', 'es_ES').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isToday ? 2 : 1,
      color: isToday ? AppTheme.efectivaColor.withValues(alpha: 0.05) : null,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isToday ? AppTheme.efectivaColor : AppTheme.navyBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isToday ? AppTheme.efectivaColor : AppTheme.navyBlue,
                    ),
                  ),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Badge con cantidad de actividades
            if (activities.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.efectivaColor : AppTheme.navyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activities.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        children: [
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Sin actividades programadas',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: activities.map((activity) {
                  return _ActivityChip(
                    activity: activity,
                    onTap: onActivityTap,
                    fullWidth: true,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip de actividad reutilizable
class _ActivityChip extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Function(Map<String, dynamic>) onTap;
  final bool fullWidth;

  const _ActivityChip({
    required this.activity,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = activityTypeFromString(activity['activity_type'] as String);
    final title = activity['title'] as String;
    final startTime = activity['start_time'] as String?;

    // Color según tipo de actividad
    Color backgroundColor;
    Color borderColor;

    if (type == ActivityType.academiaCompania || type == ActivityType.academiaCuerpo) {
      backgroundColor = Colors.blue[50]!;
      borderColor = Colors.blue[200]!;
    } else if (type == ActivityType.reunionOrdinaria || type == ActivityType.reunionExtraordinaria) {
      backgroundColor = Colors.purple[50]!;
      borderColor = Colors.purple[200]!;
    } else if (type == ActivityType.citacionCompania || type == ActivityType.citacionCuerpo) {
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
        width: fullWidth ? double.infinity : null,
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
            // Título (sin emoji para ahorrar espacio)
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: fullWidth ? 3 : 2,
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
  }
}
