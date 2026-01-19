/// Roles de usuario en el sistema
enum UserRole {
  admin,
  officer,
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
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.firefighter,
      ),
      email: json['email'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
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
    };
  }
}
