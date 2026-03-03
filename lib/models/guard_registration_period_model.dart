import 'package:intl/intl.dart';

class GuardRegistrationPeriod {
  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
  final String openedBy;
  final DateTime openedAt;
  final DateTime? closedAt;
  final DateTime createdAt;

  GuardRegistrationPeriod({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.openedBy,
    required this.openedAt,
    this.closedAt,
    required this.createdAt,
  });

  /// Check if the period is open
  bool get isOpen => status == 'open';

  /// Get formatted label: "dd/MM al dd/MM/yyyy"
  String get periodLabel {
    final startFormat = DateFormat('dd/MM');
    final endFormat = DateFormat('dd/MM/yyyy');
    return '${startFormat.format(periodStart)} al ${endFormat.format(periodEnd)}';
  }

  factory GuardRegistrationPeriod.fromJson(Map<String, dynamic> json) {
    return GuardRegistrationPeriod(
      id: json['id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      status: json['status'] as String,
      openedBy: json['opened_by'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'status': status,
      'opened_by': openedBy,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  GuardRegistrationPeriod copyWith({
    String? id,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? status,
    String? openedBy,
    DateTime? openedAt,
    DateTime? closedAt,
    DateTime? createdAt,
  }) {
    return GuardRegistrationPeriod(
      id: id ?? this.id,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      openedBy: openedBy ?? this.openedBy,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
