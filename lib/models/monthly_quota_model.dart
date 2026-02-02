/// Estado de una cuota mensual
enum QuotaStatus {
  pending,  // Pendiente de pago
  paid,     // Pagada completamente
  partial,  // Pago parcial
}

/// Modelo de cuota mensual
class MonthlyQuota {
  final String id;
  final String userId;
  final int month; // 1-12
  final int year;
  final int expectedAmount; // Monto esperado ($5000 o $2500)
  final int paidAmount; // Monto pagado
  final QuotaStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyQuota({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.expectedAmount,
    required this.paidAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MonthlyQuota.fromJson(Map<String, dynamic> json) {
    return MonthlyQuota(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      expectedAmount: json['expected_amount'] as int,
      paidAmount: json['paid_amount'] as int? ?? 0,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'year': year,
      'expected_amount': expectedAmount,
      'paid_amount': paidAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static QuotaStatus _parseStatus(String statusName) {
    try {
      return QuotaStatus.values.firstWhere((e) => e.name == statusName);
    } catch (_) {
      return QuotaStatus.pending;
    }
  }

  /// Retorna true si la cuota está completamente pagada
  bool get isPaid => status == QuotaStatus.paid;

  /// Retorna el monto adeudado
  int get amountOwed => expectedAmount - paidAmount;

  /// Retorna el nombre del mes en español
  String get monthName {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  /// Retorna el período en formato "Mes YYYY"
  String get periodDisplay => '$monthName $year';
}
