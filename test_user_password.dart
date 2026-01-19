import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Test para verificar qué contraseña usó el usuario
void main() {
  print('=== VERIFICAR CONTRASEÑA DEL USUARIO ===\n');
  
  // Hash almacenado en BD para usuario 12345678-9
  final storedHash = 'TIVOWop8gl-6d7qlhlm6tRadFnx7MCSTVWhjXmmE6vo=:16d16482ace516e134924f689471710b5b72bcb31dd4a1f6952f345d25a14487';
  
  // Separar salt y hash
  final parts = storedHash.split(':');
  final salt = parts[0];
  final hash = parts[1];
  
  print('Salt: $salt');
  print('Hash: $hash');
  print('\n=== PROBAR CONTRASEÑAS COMUNES ===\n');
  
  final testPasswords = [
    'Bombero2024!',
    'bombero2024!',
    'Bombero2024',
    'Sexta2024!',
    'Admin123!',
    '12345678',
  ];
  
  for (final password in testPasswords) {
    final combined = password + salt;
    final bytes = utf8.encode(combined);
    final testHash = sha256.convert(bytes).toString();
    
    if (testHash == hash) {
      print('✓ CONTRASEÑA ENCONTRADA: $password');
      return;
    } else {
      print('✗ No es: $password');
    }
  }
  
  print('\n=== NO SE ENCONTRÓ LA CONTRASEÑA ===');
  print('La contraseña que usó el usuario NO está en la lista de prueba.');
  print('\nPara resetear, ejecuta en Supabase:');
  print("UPDATE auth_credentials SET password_hash = 'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566' WHERE user_id = (SELECT id FROM users WHERE rut = '12345678-9');");
}
