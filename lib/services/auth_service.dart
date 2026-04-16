import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/supabase_service.dart';

/// Complete authentication service with password hashing
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = SupabaseService();
  UserModel? _currentUser;
  
  // Clave para SharedPreferences
  static const String _userKey = 'sexta_app_auth_user';

  UserModel? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;
  bool get isAuthenticated => _currentUser != null;

  /// Inicializar servicio y restaurar sesión si existe
  Future<void> initialize() async {
    await _restoreSession();
  }

  /// Restaurar sesión desde SharedPreferences
  Future<void> _restoreSession() async {
    try {
      print('[AuthService] Attempting to restore session...');
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      
      if (userData != null) {
        final json = jsonDecode(userData);
        _currentUser = UserModel.fromJson(json);
        print('[AuthService] Session restored successfully: ${_currentUser?.fullName} (${_currentUser?.role.name})');
      } else {
        print('[AuthService] No saved session found');
      }
    } catch (e) {
      print('[AuthService] Error restoring session: $e');
      _currentUser = null;
    }
  }

  /// Guardar sesión en SharedPreferences
  Future<void> _saveSession(UserModel user) async {
    try {
      print('[AuthService] Saving session for: ${user.fullName}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      print('[AuthService] Session saved successfully');
    } catch (e) {
      print('[AuthService] Error saving session: $e');
    }
  }

  /// Limpiar sesión
  Future<void> _clearSession() async {
    try {
      print('[AuthService] Clearing session...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      print('[AuthService] Session cleared');
    } catch (e) {
      print('[AuthService] Error clearing session: $e');
    }
  }

  /// Login with RUT and password
  Future<LoginResult> login(String rut, String password) async {
    // 1. Get user by RUT
    final user = await _supabase.getUserByRut(rut);
    if (user == null) {
      return LoginResult.failure('RUT no encontrado');
    }

    // 2. Verificar que tenga email
    if (user.email == null || user.email!.isEmpty) {
      return LoginResult.failure('Usuario sin email configurado');
    }

    // 2.5 Verificar que el usuario esté activo
    if (!user.isActive) {
      String statusMsg;
      switch (user.status) {
        case UserStatus.suspendido:
          statusMsg = 'Su cuenta se encuentra suspendida';
        case UserStatus.renunciado:
          statusMsg = 'Su cuenta fue desactivada por renuncia';
        case UserStatus.expulsado:
          statusMsg = 'Su cuenta fue desactivada por expulsión';
        case UserStatus.separado:
          statusMsg = 'Su cuenta fue desactivada por separación';
        case UserStatus.fallecido:
          statusMsg = 'Esta cuenta se encuentra deshabilitada';
        default:
          statusMsg = 'Su cuenta no está activa';
      }
      return LoginResult.failure(statusMsg);
    }

    // 3. SignIn con Supabase Auth
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
    } on AuthException {
      return LoginResult.failure('Credenciales incorrectas');
    } catch (e) {
      return LoginResult.failure('Error de autenticación: $e');
    }

    // 4. Set current user y guardar sesión
    _currentUser = user;
    await _saveSession(user);

    // 5. Consultar requires_password_change desde tabla users
    final userData = await Supabase.instance.client
        .from('users')
        .select('requires_password_change')
        .eq('id', user.id)
        .single();
    final requiresPasswordChange = userData['requires_password_change'] as bool? ?? false;

    return LoginResult.success(
      user: user,
      requiresPasswordChange: requiresPasswordChange,
    );
  }

  /// Logout
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      print('[AuthService] Error signing out from Supabase: $e');
    }
    _currentUser = null;
    await _clearSession();
    print('✅ Sesión cerrada');
  }

  /// Change password (for first-time login or password reset)
  Future<ChangePasswordResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // 1. Verificar sesión activa
      final currentUser = _currentUser;
      if (currentUser == null || currentUser.email == null) {
        return ChangePasswordResult.failure('No hay sesión activa');
      }

      // 2. Verificar contraseña actual via signIn
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: currentUser.email!,
          password: currentPassword,
        );
      } on AuthException {
        return ChangePasswordResult.failure('Contraseña actual incorrecta');
      }

      // 3. Validar nueva contraseña
      final validation = validatePassword(newPassword);
      if (!validation.isValid) {
        return ChangePasswordResult.failure(validation.message);
      }

      // 4. Actualizar contraseña en Supabase Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 5. Marcar requires_password_change = false en tabla users
      await Supabase.instance.client
          .from('users')
          .update({'requires_password_change': false})
          .eq('id', currentUser.id);

      return ChangePasswordResult.success();
    } catch (e) {
      return ChangePasswordResult.failure('Error cambiando contraseña: $e');
    }
  }


  /// Reset user password (admin only) via Edge Function
  Future<ResetPasswordResult> resetUserPassword(String userId) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'reset-user-password',
        body: {'user_id': userId},
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Error desconocido';
        return ResetPasswordResult.failure('Error reseteando contraseña: $error');
      }

      return ResetPasswordResult.success(temporaryPassword: 'Sexta2026*');
    } catch (e) {
      return ResetPasswordResult.failure('Error reseteando contraseña: $e');
    }
  }

  /// Validate password requirements
  PasswordValidation validatePassword(String password) {
    if (password.length < 8) {
      return PasswordValidation(false, 'La contraseña debe tener al menos 8 caracteres');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return PasswordValidation(false, 'Debe contener al menos una letra mayúscula');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return PasswordValidation(false, 'Debe contener al menos un número');
    }
    
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return PasswordValidation(false, 'Debe contener al menos un caracter especial');
    }
    
    return PasswordValidation(true, 'Contraseña válida');
  }
}

/// Login result
class LoginResult {
  final bool success;
  final String? error;
  final UserModel? user;
  final bool requiresPasswordChange;

  LoginResult._({
    required this.success,
    this.error,
    this.user,
    this.requiresPasswordChange = false,
  });

  factory LoginResult.success({
    required UserModel user,
    bool requiresPasswordChange = false,
  }) {
    return LoginResult._(
      success: true,
      user: user,
      requiresPasswordChange: requiresPasswordChange,
    );
  }

  factory LoginResult.failure(String error) {
    return LoginResult._(
      success: false,
      error: error,
    );
  }
}

/// Change password result
class ChangePasswordResult {
  final bool success;
  final String? error;

  ChangePasswordResult._({
    required this.success,
    this.error,
  });

  factory ChangePasswordResult.success() {
    return ChangePasswordResult._(success: true);
  }

  factory ChangePasswordResult.failure(String error) {
    return ChangePasswordResult._(
      success: false,
      error: error,
    );
  }
}

/// Password validation result
class PasswordValidation {
  final bool isValid;
  final String message;

  PasswordValidation(this.isValid, this.message);
}

/// Reset password result
class ResetPasswordResult {
  final bool success;
  final String? error;
  final String? temporaryPassword;

  ResetPasswordResult._({
    required this.success,
    this.error,
    this.temporaryPassword,
  });

  factory ResetPasswordResult.success({required String temporaryPassword}) {
    return ResetPasswordResult._(
      success: true,
      temporaryPassword: temporaryPassword,
    );
  }

  factory ResetPasswordResult.failure(String error) {
    return ResetPasswordResult._(
      success: false,
      error: error,
    );
  }
}
