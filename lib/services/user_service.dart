import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Servicio para gestión de usuarios
class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todos los usuarios
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('full_name');

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Obtener usuario por ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user by id: $e');
      return null;
    }
  }

  /// Obtener usuarios por rol
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', role.name)
          .order('full_name');

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  /// Crear usuario
  Future<UserModel?> createUser(UserModel user) async {
    try {
      final response = await _supabase
          .from('users')
          .insert(user.toJson())
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  /// Actualizar usuario
  Future<bool> updateUser(UserModel user) async {
    try {
      await _supabase
          .from('users')
          .update(user.toJson())
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Eliminar usuario
  Future<bool> deleteUser(String id) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Buscar usuarios por nombre o RUT
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .or('full_name.ilike.%$query%,rut.ilike.%$query%')
          .order('full_name');

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
