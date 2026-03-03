import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/guard_roster_model.dart';
import 'package:sexta_app/models/user_model.dart';

/// Card widget for displaying daily guard roster
class GuardRosterCard extends StatelessWidget {
  final GuardRosterDaily roster;
  final String? currentUserId;
  final VoidCallback? onTap;

  const GuardRosterCard({
    super.key,
    required this.roster,
    this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUserAssigned = currentUserId != null &&
        roster.allAssignedIds.contains(currentUserId);
    final genderDist = roster.getGenderDistribution();
    final isGenderValid = roster.isGenderDistributionValid();

    return Card(
      elevation: isUserAssigned ? 4 : 1,
      color: isUserAssigned
          ? AppTheme.navyBlue.withOpacity(0.05)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date and status
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isUserAssigned ? AppTheme.navyBlue : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, dd MMMM', 'es_ES')
                          .format(roster.guardDate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUserAssigned ? AppTheme.navyBlue : null,
                          ),
                    ),
                  ),
                  if (isUserAssigned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.navyBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'TU GUARDIA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Personnel count and gender distribution
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${roster.totalAssigned}/10',
                    color: roster.isComplete
                        ? AppTheme.efectivaColor
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.male,
                    label: '${genderDist['males']}M',
                    color: isGenderValid ? Colors.blue : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.female,
                    label: '${genderDist['females']}F',
                    color: isGenderValid ? Colors.pink : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Personnel list
              if (roster.maquinista != null)
                _buildPersonnelRow(
                  icon: Icons.local_shipping,
                  role: 'Maquinista',
                  user: roster.maquinista!,
                  isCurrentUser: currentUserId == roster.maquinistaId,
                ),
              if (roster.obac != null)
                _buildPersonnelRow(
                  icon: Icons.shield,
                  role: 'OBAC',
                  user: roster.obac!,
                  isCurrentUser: currentUserId == roster.obacId,
                ),
              if (roster.bomberos.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Bomberos (${roster.bomberos.length}):',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 4),
                ...roster.bomberos.map((bombero) {
                  final isCurrentUser = currentUserId == bombero.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: isCurrentUser
                              ? AppTheme.navyBlue
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${bombero.victorNumber} - ${bombero.fullName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isCurrentUser
                                  ? AppTheme.navyBlue
                                  : Colors.black87,
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Empty state
              if (roster.totalAssigned == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Sin asignaciones',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonnelRow({
    required IconData icon,
    required String role,
    required UserModel user,
    required bool isCurrentUser,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isCurrentUser ? AppTheme.navyBlue : Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            '$role:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${user.victorNumber} - ${user.fullName}',
              style: TextStyle(
                fontSize: 13,
                color: isCurrentUser ? AppTheme.navyBlue : Colors.black87,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
