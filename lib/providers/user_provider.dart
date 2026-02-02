import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Provider para el usuario actual autenticado
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Provider para cargar el usuario actual
final loadCurrentUserProvider = FutureProvider<UserModel?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return null;
  
  try {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    
    final user = UserModel.fromJson(response);
    
    // Actualizar el provider de estado
    ref.read(currentUserProvider.notifier).state = user;
    
    return user;
  } catch (e) {
    print('Error loading current user: $e');
    return null;
  }
});
