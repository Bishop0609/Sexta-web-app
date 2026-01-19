import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Script para generar el hash correcto de "Bombero2024!"
/// Este hash se usará en el SQL para crear las contraseñas
void main() {
  const password = 'Bombero2024!';
  const salt = 'BomberoSalt2024SecureRandom32Chars';  // Salt fijo para password genérica
  
  // Combinar password y salt (igual que en AuthService)
  final combined = password + salt;
  
  // Hash usando SHA-256
  final bytes = utf8.encode(combined);
  final hash = sha256.convert(bytes);
  
  // Resultado en formato salt:hash
  final passwordHash = '$salt:${hash.toString()}';
  
  print('Password: $password');
  print('Salt: $salt');
  print('Hash SHA-256: ${hash.toString()}');
  print('');
  print('Password Hash completo (para SQL):');
  print(passwordHash);
  print('');
  print('Longitud salt: ${salt.length}');
  print('Longitud hash: ${hash.toString().length}');
}
