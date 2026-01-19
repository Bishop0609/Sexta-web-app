import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Script de prueba para verificar hash de contraseña
/// Ejecutar: dart run test_password_hash.dart
void main() {
  print('=== TEST DE HASH DE CONTRASEÑA ===\n');
  
  final password = 'Bombero2024!';
  final expectedSalt = 'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=';
  
  // Generar hash con el salt esperado
  final combined = password + expectedSalt;
  final bytes = utf8.encode(combined);
  final hash = sha256.convert(bytes);
  
  print('Contraseña: $password');
  print('Salt: $expectedSalt');
  print('Hash generado: ${hash.toString()}');
  print('\nHash completo (formato BD): $expectedSalt:${hash.toString()}');
  
  print('\n=== COMPARACIÓN ===');
  print('Hash esperado en BD:');
  print('dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:7e8f3c9b2a1d0e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9');
  
  print('\n¿COINCIDEN? ${hash.toString() == '7e8f3c9b2a1d0e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9' ? 'SÍ ✓' : 'NO ✗'}');
  
  print('\n=== GENERAR NUEVO HASH COMPLETO ===');
  final newSalt = _generateSalt();
  final newCombined = password + newSalt;
  final newBytes = utf8.encode(newCombined);
  final newHash = sha256.convert(newBytes);
  final completeHash = '$newSalt:${newHash.toString()}';
  
  print('Nuevo hash para $password:');
  print(completeHash);
  print('\nSQL para actualizar:');
  print("UPDATE auth_credentials SET password_hash = '$completeHash' WHERE user_id = (SELECT id FROM users WHERE rut = '12345678-9');");
}

String _generateSalt() {
  return 'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc='; // Usar mismo salt para testing
}
