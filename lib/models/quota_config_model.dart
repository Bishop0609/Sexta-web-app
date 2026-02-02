/// Modelo de configuración de cuotas por año
class QuotaConfig {
  final String id;
  final int year;
  final int standardQuota;  // Cuota para bomberos normales
  final int reducedQuota;   // Cuota para aspirantes/postulantes/estudiantes
  final int? postulantStudentQuota; // Cuota especial para postulantes estudiantes (solo 2025)
  final DateTime createdAt;
  final DateTime updatedAt;

  QuotaConfig({
    required this.id,
    required this.year,
    required this.standardQuota,
    required this.reducedQuota,
    this.postulantStudentQuota,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuotaConfig.fromJson(Map<String, dynamic> json) {
    return QuotaConfig(
      id: json['id'] as String,
      year: json['year'] as int,
      standardQuota: json['standard_quota'] as int,
      reducedQuota: json['reduced_quota'] as int,
      postulantStudentQuota: json['postulant_student_quota'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'standard_quota': standardQuota,
      'reduced_quota': reducedQuota,
      'postulant_student_quota': postulantStudentQuota,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Retorna el monto de cuota para un tipo de usuario
  /// 
  /// Reglas:
  /// 1. 2025: Postulante + Estudiante Activo = postulantStudentQuota ($1000)
  /// 2. Aspirante/Postulante/Estudiante Activo = reducedQuota ($2000)
  /// 3. Resto = standardQuota ($4000)
  int getQuotaForUserType({
    required String rank,
    required bool isStudent,
    DateTime? studentStartDate,
    DateTime? studentEndDate,
    required int month, // Mes para el cual se calcula la cuota
  }) {
    // Determinar si es estudiante en el mes especificado
    bool isActiveStudent = _isActiveStudentInMonth(
      isStudent: isStudent,
      studentStartDate: studentStartDate,
      studentEndDate: studentEndDate,
      month: month,
      year: year,
    );

    // Regla especial 2025: Postulante + Estudiante Activo = cuota especial
    if (year == 2025 && 
        rank == 'Postulante' && 
        isActiveStudent && 
        postulantStudentQuota != null) {
      return postulantStudentQuota!;
    }

    // Aspirantes, Postulantes y Estudiantes pagan cuota reducida
    if (rank == 'Aspirante' || rank == 'Postulante' || isActiveStudent) {
      return reducedQuota;
    }
    
    // Resto paga cuota estándar
    return standardQuota;
  }

  /// Determina si el usuario es estudiante activo en un mes específico
  bool _isActiveStudentInMonth({
    required bool isStudent,
    DateTime? studentStartDate,
    DateTime? studentEndDate,
    required int month,
    required int year,
  }) {
    // Si no tiene marca de estudiante, no es estudiante
    if (!isStudent) return false;

    // Si no hay fecha de inicio, usa el flag isStudent directamente
    if (studentStartDate == null) return isStudent;

    // Fecha del mes a evaluar
    final monthDate = DateTime(year, month, 1);

    // Debe haber iniciado antes o durante el mes
    if (monthDate.isBefore(DateTime(studentStartDate.year, studentStartDate.month, 1))) {
      return false;
    }

    // Si no hay fecha de fin, es estudiante actualmente
    if (studentEndDate == null) return true;

    // Debe terminar después o durante el mes
    return !monthDate.isAfter(DateTime(studentEndDate.year, studentEndDate.month, 1));
  }

  /// Retorna una descripción legible de la configuración
  String get description {
    return 'Año $year: \$$standardQuota / \$$reducedQuota';
  }

  /// Crea una copia con campos actualizados
  QuotaConfig copyWith({
    String? id,
    int? year,
    int? standardQuota,
    int? reducedQuota,
    int? postulantStudentQuota,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuotaConfig(
      id: id ?? this.id,
      year: year ?? this.year,
      standardQuota: standardQuota ?? this.standardQuota,
      reducedQuota: reducedQuota ?? this.reducedQuota,
      postulantStudentQuota: postulantStudentQuota ?? this.postulantStudentQuota,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
