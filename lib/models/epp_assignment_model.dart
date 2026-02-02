/// Tipos de EPP disponibles
enum EPPType {
  casco('Casco'),
  uniformeEstructural('Uniforme estructural'),
  uniformeMultirrol('Uniforme multirrol'),
  esclavina('Esclavina'),
  guantesEstructurales('Guantes estructurales'),
  guantesRescate('Guantes de Rescate'),
  botas('Botas'),
  linterna('Linterna'),
  primeraCapa('Primera capa'),
  uniformeParada('Uniforme de parada');

  final String displayName;
  const EPPType(this.displayName);
  
  static EPPType fromString(String value) {
    return EPPType.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => EPPType.casco,
    );
  }
}

/// Estado del EPP
enum EPPCondition {
  nuevo('Nuevo'),
  usadoComoNuevo('Usado como nuevo'),
  usadoMedianoEstado('Usado mediano estado'),
  muyUsado('Muy usado');

  final String displayName;
  const EPPCondition(this.displayName);
  
  static EPPCondition fromString(String value) {
    return EPPCondition.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => EPPCondition.nuevo,
    );
  }
}

/// Modelo de asignación de EPP
class EPPAssignmentModel {
  final String id;
  final String userId;
  final EPPType eppType;
  final String internalCode;
  final String? brand;
  final String? model;
  final String? color;
  final EPPCondition condition;
  final DateTime receptionDate;
  final String? observations;
  final bool isReturned;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  EPPAssignmentModel({
    required this.id,
    required this.userId,
    required this.eppType,
    required this.internalCode,
    this.brand,
    this.model,
    this.color,
    required this.condition,
    required this.receptionDate,
    this.observations,
    this.isReturned = false,
    required this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory EPPAssignmentModel.fromJson(Map<String, dynamic> json) {
    return EPPAssignmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eppType: EPPType.fromString(json['epp_type'] as String),
      internalCode: json['internal_code'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      condition: EPPCondition.fromString(json['condition'] as String),
      receptionDate: DateTime.parse(json['reception_date'] as String),
      observations: json['observations'] as String?,
      isReturned: json['is_returned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'epp_type': eppType.displayName,
      'internal_code': internalCode,
      'brand': brand,
      'model': model,
      'color': color,
      'condition': condition.displayName,
      'reception_date': receptionDate.toIso8601String().split('T')[0],
      'observations': observations,
      'is_returned': isReturned,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_at': updatedAt?.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  EPPAssignmentModel copyWith({
    String? id,
    String? userId,
    EPPType? eppType,
    String? internalCode,
    String? brand,
    String? model,
    String? color,
    EPPCondition? condition,
    DateTime? receptionDate,
    String? observations,
    bool? isReturned,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return EPPAssignmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eppType: eppType ?? this.eppType,
      internalCode: internalCode ?? this.internalCode,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      condition: condition ?? this.condition,
      receptionDate: receptionDate ?? this.receptionDate,
      observations: observations ?? this.observations,
      isReturned: isReturned ?? this.isReturned,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

/// Modelo de devolución de EPP
class EPPReturnModel {
  final String id;
  final String assignmentId;
  final DateTime returnDate;
  final String returnReason;
  final String? returnedBy;
  final DateTime createdAt;

  EPPReturnModel({
    required this.id,
    required this.assignmentId,
    required this.returnDate,
    required this.returnReason,
    this.returnedBy,
    required this.createdAt,
  });

  factory EPPReturnModel.fromJson(Map<String, dynamic> json) {
    return EPPReturnModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      returnDate: DateTime.parse(json['return_date'] as String),
      returnReason: json['return_reason'] as String,
      returnedBy: json['returned_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'return_date': returnDate.toIso8601String().split('T')[0],
      'return_reason': returnReason,
      'returned_by': returnedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
