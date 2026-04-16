import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final birthdayProvider = FutureProvider<bool>((ref) async {
  final user = AuthService().currentUser;
  if (user == null) return false;
  
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase.rpc(
      'is_user_birthday',
      params: {'p_user_id': user.id},
    );
    return response == true;
  } catch (e) {
    print('Error verificando cumpleaños: $e');
    return false;
  }
});
