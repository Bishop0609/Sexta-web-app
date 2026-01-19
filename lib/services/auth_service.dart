import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    try {
      // 1. Get user by RUT
      final user = await _supabase.getUserByRut(rut);
      if (user == null) {
        return LoginResult.failure('RUT no encontrado');
      }

      // 2. Get auth credentials
      final credentials = await _supabase.getAuthCredentials(user.id);
      if (credentials == null) {
        return LoginResult.failure('Usuario sin credenciales configuradas');
      }

      // 3. Check if account is locked
      if (credentials['locked_until'] != null) {
        final lockedUntil = DateTime.parse(credentials['locked_until'] as String);
        if (DateTime.now().isBefore(lockedUntil)) {
          final minutes = lockedUntil.difference(DateTime.now()).inMinutes;
          return LoginResult.failure('Cuenta bloqueada. Intenta en $minutes minutos');
        }
      }

      // 4. Verify password
      final passwordHash = credentials['password_hash'] as String;
      if (!verifyPassword(password, passwordHash)) {
        // Increment failed attempts
        await _supabase.incrementFailedAttempts(user.id);
        final failedAttempts = (credentials['failed_attempts'] as int? ?? 0) + 1;
        
        if (failedAttempts >= 5) {
          await _supabase.lockAccount(user.id, minutes: 15);
          return LoginResult.failure('Demasiados intentos fallidos. Cuenta bloqueada por 15 minutos');
        }
        
        return LoginResult.failure('Contraseña incorrecta (${5 - failedAttempts} intentos restantes)');
      }

      // 5. Reset failed attempts and update last login
      await _supabase.resetFailedAttempts(user.id);
      await _supabase.updateLastLogin(user.id);

      // 6. Set current user
      _currentUser = user;
      
      // 6.5. Save session to SharedPreferences
      await _saveSession(user);

      // 7. Check if needs password change
      final requiresPasswordChange = credentials['requires_password_change'] as bool? ?? false;

      return LoginResult.success(
        user: user,
        requiresPasswordChange: requiresPasswordChange,
      );
    } catch (e) {
      return LoginResult.failure('Error de autenticación: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
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
      // 1. Verify current password
      final credentials = await _supabase.getAuthCredentials(userId);
      if (credentials == null) {
        return ChangePasswordResult.failure('Credenciales no encontradas');
      }

      final currentHash = credentials['password_hash'] as String;
      if (!verifyPassword(currentPassword, currentHash)) {
        return ChangePasswordResult.failure('Contraseña actual incorrecta');
      }

      // 2. Validate new password
      final validation = validatePassword(newPassword);
      if (!validation.isValid) {
        return ChangePasswordResult.failure(validation.message);
      }

      // 3. Hash new password
      final newHash = hashPassword(newPassword);

      // 4. Update password in database
      await _supabase.updatePassword(userId, newHash);

      return ChangePasswordResult.success();
    } catch (e) {
      return ChangePasswordResult.failure('Error cambiando contraseña: $e');
    }
  }


  /// Reset user password (admin only)
  /// Returns the generated temporary password to show to admin
  Future<ResetPasswordResult> resetUserPassword(String userId) async {
    try {
      // 1. Use fixed temporary password for easier communication
      const tempPassword = 'Sexta2026*';
      
      // 2. Hash the password
      final passwordHash = hashPassword(tempPassword);
      
      // 3. Update password in database with requires_password_change = true
      await _supabase.updatePasswordWithReset(userId, passwordHash);
      
      return ResetPasswordResult.success(temporaryPassword: tempPassword);
    } catch (e) {
      return ResetPasswordResult.failure('Error reseteando contraseña: $e');
    }
  }

  /// Generate secure temporary password
  String generateTempPassword() {
    const length = 12;
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#\$%&*';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Hash password using SHA-256 with salt
  String hashPassword(String password) {
    // Generate salt
    final salt = _generateSalt();
    
    // Combine password and salt
    final combined = password + salt;
    
    // Hash using SHA-256
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    
    // Store as: salt:hash
    return '$salt:${hash.toString()}';
  }

  /// Verify password against hash
  bool verifyPassword(String password, String storedHash) {
    try {
      // Split salt and hash
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      // Hash the provided password with the same salt
      final combined = password + salt;
      final bytes = utf8.encode(combined);
      final newHash = sha256.convert(bytes).toString();
      
      // Compare hashes
      return newHash == hash;
    } catch (e) {
      return false;
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

  /// Generate random salt
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
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
