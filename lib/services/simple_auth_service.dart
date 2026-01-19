import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sexta_app/models/user_model.dart';

/// Servicio de autenticación SIMPLE (sin Supabase Auth)
/// Usa solo la tabla users para login con persistencia de sesión
class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  // Usar cliente de Supabase directamente para evitar dependencia circular
  SupabaseClient get _client => Supabase.instance.client;
  
  // Clave para SharedPreferences
  static const String _userKey = 'sexta_app_current_user';
  
  UserModel? _currentUser;
  
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
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
        print('✅ Sesión restaurada: ${_currentUser?.fullName} (${_currentUser?.role.name})');
      }
    } catch (e) {
      print('⚠️ Error al restaurar sesión: $e');
      await _clearSession();
    }
  }

  /// Guardar sesión en SharedPreferences
  Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      print('✅ Sesión guardada: ${user.fullName} (${user.role.name})');
    } catch (e) {
      print('⚠️ Error al guardar sesión: $e');
    }
  }

  /// Limpiar sesión de SharedPreferences
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('⚠️ Error al limpiar sesión: $e');
    }
  }

  /// Login simple con RUT (sin hash de contraseña por ahora)
  Future<Map<String, dynamic>> login(String rut) async {
    try {
      // Buscar usuario por RUT
      final response = await _client
          .from('users')
          .select()
          .eq('rut', rut.trim())
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'error': 'Usuario no encontrado con RUT: $rut',
        };
      }

      _currentUser = UserModel.fromJson(response);
      
      // Guardar sesión en SharedPreferences
      await _saveSession(_currentUser!);

      return {
        'success': true,
        'user': _currentUser,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error en login: $e',
      };
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
    print('✅ Sesión cerrada');
  }
  
  /// Verificar si hay sesión (para usar en guards)
  bool hasSession() {
    return _currentUser != null;
  }
}
