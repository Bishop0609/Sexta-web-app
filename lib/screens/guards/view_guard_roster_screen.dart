import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/guard_roster_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/providers/user_provider.dart';
import 'package:sexta_app/services/guard_roster_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/guard_roster_card.dart';

/// Screen for viewing guard roster
class ViewGuardRosterScreen extends ConsumerStatefulWidget {
  const ViewGuardRosterScreen({super.key});

  @override
  ConsumerState<ViewGuardRosterScreen> createState() =>
      _ViewGuardRosterScreenState();
}

class _ViewGuardRosterScreenState extends ConsumerState<ViewGuardRosterScreen> {
  final _guardRosterService = GuardRosterService();
  
  DateTime _selectedWeekStart = DateTime.now();
  GuardRosterWeekly? _weeklyRoster;
  List<GuardRosterDaily> _dailyRosters = [];
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _guardRosterService.getWeekStart(DateTime.now());
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = ref.read(currentUserProvider);
      
      // Get weekly roster
      final weeklyRoster = await _guardRosterService.getWeeklyRoster(
        _selectedWeekStart,
      );

      if (weeklyRoster != null) {
        // Get daily rosters for the week
        final dailyRosters = await _guardRosterService.getDailyRostersForWeek(
          weeklyRoster.id,
        );

        setState(() {
          _weeklyRoster = weeklyRoster;
          _dailyRosters = dailyRosters;
        });
      } else {
        setState(() {
          _weeklyRoster = null;
          _dailyRosters = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar rol: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
    _loadRoster();
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
    _loadRoster();
  }

  void _goToCurrentWeek() {
    setState(() {
      _selectedWeekStart = _guardRosterService.getWeekStart(DateTime.now());
    });
    _loadRoster();
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _guardRosterService.getWeekEnd(_selectedWeekStart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Mi Rol'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToCurrentWeek,
            tooltip: 'Semana actual',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Week selector
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousWeek,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Semana del',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${DateFormat('dd MMM', 'es_ES').format(_selectedWeekStart)} - ${DateFormat('dd MMM yyyy', 'es_ES').format(weekEnd)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextWeek,
                      ),
                    ],
                  ),
                  if (_weeklyRoster != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _weeklyRoster!.isPublished
                            ? AppTheme.efectivaColor.withOpacity(0.1)
                            : AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _weeklyRoster!.isPublished
                                ? Icons.check_circle
                                : Icons.edit,
                            size: 16,
                            color: _weeklyRoster!.isPublished
                                ? AppTheme.efectivaColor
                                : AppTheme.warningColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _weeklyRoster!.isPublished
                                ? 'Publicado'
                                : 'Borrador',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _weeklyRoster!.isPublished
                                  ? AppTheme.efectivaColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Roster list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _weeklyRoster == null
                    ? _buildEmptyState()
                    : _dailyRosters.isEmpty
                        ? _buildNoAssignmentsState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _dailyRosters.length,
                            itemBuilder: (context, index) {
                              final roster = _dailyRosters[index];
                              return GuardRosterCard(
                                roster: roster,
                                currentUserId: _currentUser?.id,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay rol para esta semana',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'El rol a\u00FAn no ha sido generado',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAssignmentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin asignaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay guardias asignadas para esta semana',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
