/// Roles de usuario en el sistema
/// 
/// ROLES (8 total) - según matriz aprobada:
/// - admin: Control total del sistema
/// - oficial1: Capitán y Tte 1 (todo excepto mantenimiento)
/// - oficial2: Solo gestión de actividades
/// - oficial3: Ayudantes (gestión amplia)
/// - oficial4: Teniente a cargo de EPP + Actividades
/// - oficial5: Solo administración de EPP
/// - oficial6: Tesorero + Actividades
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

/// Estado del bombero en la compañía
enum UserStatus {
  activo,
  suspendido,
  renunciado,
  expulsado,
  separado,
  fallecido,
}

/// Modelo de usuario (bombero)
class UserModel {
  final String id;
  final String rut;
  final String victorNumber;
  final String? registroCompania; // Registro de Compañía
  final String fullName;
  final Gender gender;
  final MaritalStatus maritalStatus;
  final String rank;
  final UserRole role;
  final String? email;
  final UserStatus status;
  final DateTime? createdAt;
  
  final DateTime? birthDate;
  final DateTime? enrollmentDate;

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
    this.status = UserStatus.activo,
    this.createdAt,
    this.birthDate,
    this.enrollmentDate,
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
      status: parseStatus(json['status'] as String? ?? 'activo'),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      enrollmentDate: json['enrollment_date'] != null
          ? DateTime.parse(json['enrollment_date'] as String)
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
      'status': status.name,
      'created_at': createdAt?.toIso8601String(),
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'enrollment_date': enrollmentDate?.toIso8601String().split('T')[0],
      'is_student': isStudent,
      'payment_start_date': paymentStartDate?.toIso8601String(),
      'student_start_date': studentStartDate?.toIso8601String(),
      'student_end_date': studentEndDate?.toIso8601String(),
    };
  }

  /// Parse role with backward compatibility for migration
  static UserRole _parseRole(String roleName) {
    try {
      return UserRole.values.firstWhere((e) => e.name == roleName);
    } catch (_) {
      return UserRole.bombero;
    }
  }

  static UserStatus parseStatus(String statusName) {
    try {
      return UserStatus.values.firstWhere((e) => e.name == statusName);
    } catch (_) {
      return UserStatus.activo;
    }
  }

  /// Get display name for role
  String getRoleDisplayName() {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.oficial1:
        return 'Capitán y Tte 1';
      case UserRole.oficial2:
        return 'Solo gestión de actividades';
      case UserRole.oficial3:
        return 'Ayudantes';
      case UserRole.oficial4:
        return 'Teniente a cargo de EPP';
      case UserRole.oficial5:
        return 'Solo administración de EPP';
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

  String getStatusDisplayName() {
    switch (status) {
      case UserStatus.activo:
        return 'Activo';
      case UserStatus.suspendido:
        return 'Suspendido';
      case UserStatus.renunciado:
        return 'Renunciado';
      case UserStatus.expulsado:
        return 'Expulsado';
      case UserStatus.separado:
        return 'Separado';
      case UserStatus.fallecido:
        return 'Fallecido';
    }
  }

  bool get isActive => status == UserStatus.activo;

  String get initials {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get firstName {
    if (fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  String get lastName {
    if (fullName.isEmpty) return '';
    final parts = fullName.split(' ');
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ');
  }
}
