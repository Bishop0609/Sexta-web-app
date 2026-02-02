/// Método de pago
enum PaymentMethod {
  cash,      // Efectivo
  transfer,  // Transferencia
  other,     // Otro
}

/// Modelo de pago de tesorería
class TreasuryPayment {
  final String id;
  final String quotaId; // ID de la cuota que se está pagando
  final String userId; // Usuario que realiza el pago
  final int amount; // Monto pagado
  final DateTime paymentDate; // Fecha del pago
  final PaymentMethod paymentMethod;
  final String? receiptNumber; // Número de comprobante
  final String? notes; // Notas adicionales
  final String registeredBy; // Usuario (tesorero) que registró el pago
  final DateTime createdAt;
  final DateTime updatedAt;

  TreasuryPayment({
    required this.id,
    required this.quotaId,
    required this.userId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.receiptNumber,
    this.notes,
    required this.registeredBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TreasuryPayment.fromJson(Map<String, dynamic> json) {
    return TreasuryPayment(
      id: json['id'] as String,
      quotaId: json['quota_id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      paymentMethod: _parsePaymentMethod(json['payment_method'] as String),
      receiptNumber: json['receipt_number'] as String?,
      notes: json['notes'] as String?,
      registeredBy: json['registered_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quota_id': quotaId,
      'user_id': userId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod.name,
      'receipt_number': receiptNumber,
      'notes': notes,
      'registered_by': registeredBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static PaymentMethod _parsePaymentMethod(String methodName) {
    try {
      return PaymentMethod.values.firstWhere((e) => e.name == methodName);
    } catch (_) {
      return PaymentMethod.cash;
    }
  }

  /// Retorna el nombre del método de pago en español
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.other:
        return 'Otro';
    }
  }
}
