/// Roles de usuario en el sistema
/// 
/// NUEVOS ROLES (8 total):
/// - admin: Control total del sistema
/// - oficial1: Capitán y Jefe de compañía  
/// - oficial2: Solo gestión de actividades
/// - oficial3: Ayudantes
/// - oficial4: Teniente a cargo
/// - oficial5: Solo administración
/// - oficial6: Tesorero (gestión de cuotas)
/// - bombero: Usuario base
/// 
/// ROLES ANTIGUOS (deprecated, mantener para migración):
/// - officer: Mapea a oficial1 temporalmente
/// - firefighter: Mapea a bombero
enum UserRole {
  admin,
  oficial1,
  oficial2,
  oficial3,
  oficial4,
  oficial5,
  oficial6, // Tesorero
  bombero,
  
  // Deprecated - mantener solo para migración
  @Deprecated('Use oficial1 instead')
  officer,
  @Deprecated('Use bombero instead')
  firefighter,
}

/// Género
enum Gender {
  male,
  female,
}

/// Estado civil
enum MaritalStatus {
  single,
  married,
}

/// Modelo de usuario (bombero)
class UserModel {
  final String id;
  final String rut;
  final String victorNumber;
  final String? registroCompania; // Nuevo campo: Registro de Compañía
  final String fullName;
  final Gender gender;
  final MaritalStatus maritalStatus;
  final String rank;
  final UserRole role;
  final String? email;
  final DateTime? createdAt;
  
  // Campos de Tesorería
  final bool isStudent; // Indica si paga cuota reducida ($2,500)
  final DateTime? paymentStartDate; // Fecha desde la cual debe pagar cuotas
  final DateTime? studentStartDate; // Fecha de inicio período estudiante
  final DateTime? studentEndDate; // Fecha de fin período estudiante (null = actualmente estudiante)

  UserModel({
    required this.id,
    required this.rut,
    required this.victorNumber,
    this.registroCompania,
    required this.fullName,
    required this.gender,
    required this.maritalStatus,
    required this.rank,
    required this.role,
    this.email,
    this.createdAt,
    this.isStudent = false,
    this.paymentStartDate,
    this.studentStartDate,
    this.studentEndDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      rut: json['rut'] as String,
      victorNumber: json['victor_number'] as String,
      registroCompania: json['registro_compania'] as String?,
      fullName: json['full_name'] as String,
      gender: json['gender'] == 'M' ? Gender.male : Gender.female,
      maritalStatus: json['marital_status'] == 'single' 
          ? MaritalStatus.single 
          : MaritalStatus.married,
      rank: json['rank'] as String,
      role: _parseRole(json['role'] as String),
      email: json['email'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isStudent: json['is_student'] as bool? ?? false,
      paymentStartDate: json['payment_start_date'] != null
          ? DateTime.parse(json['payment_start_date'] as String)
          : null,
      studentStartDate: json['student_start_date'] != null
          ? DateTime.parse(json['student_start_date'] as String)
          : null,
      studentEndDate: json['student_end_date'] != null
          ? DateTime.parse(json['student_end_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rut': rut,
      'victor_number': victorNumber,
      'registro_compania': registroCompania,
      'full_name': fullName,
      'gender': gender == Gender.male ? 'M' : 'F',
      'marital_status': maritalStatus.name,
      'rank': rank,
      'role': role.name,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
      'is_student': isStudent,
      'payment_start_date': paymentStartDate?.toIso8601String(),
      'student_start_date': studentStartDate?.toIso8601String(),
      'student_end_date': studentEndDate?.toIso8601String(),
    };
  }

  /// Parse role with backward compatibility for migration
  static UserRole _parseRole(String roleName) {
    // Handle new role names
    try {
      return UserRole.values.firstWhere((e) => e.name == roleName);
    } catch (_) {
      // Fallback to bombero if role not found
      return UserRole.bombero;
    }
  }

  /// Get display name for role
  String getRoleDisplayName() {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.oficial1:
        return 'Capitán y Jefe';
      case UserRole.oficial2:
        return 'Gestión Actividades';
      case UserRole.oficial3:
        return 'Ayudante';
      case UserRole.oficial4:
        return 'Teniente a Cargo';
      case UserRole.oficial5:
        return 'Administración';
      case UserRole.oficial6:
        return 'Tesorero';
      case UserRole.bombero:
        return 'Bombero';
      case UserRole.officer:
        return 'Oficial (Migrar)';
      case UserRole.firefighter:
        return 'Bombero (Migrar)';
    }
  }
}
