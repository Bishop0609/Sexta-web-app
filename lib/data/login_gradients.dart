import 'package:flutter/material.dart';

/// Modelo de un gradiente para el fondo del login
class LoginGradient {
  final String id;
  final String name;
  final List<Color> colors;

  const LoginGradient({
    required this.id,
    required this.name,
    required this.colors,
  });
}

/// Paleta de gradientes para rotación diaria (10 opciones suaves)
const List<LoginGradient> dailyGradients = [
  LoginGradient(
    id: 'amanecer',
    name: 'Amanecer',
    colors: [Color(0xFFFFE5D9), Color(0xFFFFD6E0)],
  ),
  LoginGradient(
    id: 'bahia_coquimbo',
    name: 'Bahía Coquimbo',
    colors: [Color(0xFFD6EBF5), Color(0xFFFFFFFF)],
  ),
  LoginGradient(
    id: 'atardecer',
    name: 'Atardecer',
    colors: [Color(0xFFFFD6E0), Color(0xFFFFE8D6)],
  ),
  LoginGradient(
    id: 'brisa_marina',
    name: 'Brisa Marina',
    colors: [Color(0xFFD4F1EC), Color(0xFFECECEC)],
  ),
  LoginGradient(
    id: 'cielo_elqui',
    name: 'Cielo Elqui',
    colors: [Color(0xFFE6E0F5), Color(0xFFD6EBF5)],
  ),
  LoginGradient(
    id: 'arena_calida',
    name: 'Arena Cálida',
    colors: [Color(0xFFF5EDD9), Color(0xFFFFF8E7)],
  ),
  LoginGradient(
    id: 'madera_pulida',
    name: 'Madera Pulida',
    colors: [Color(0xFFFFF3E0), Color(0xFFE8D9C4)],
  ),
  LoginGradient(
    id: 'niebla_matinal',
    name: 'Niebla Matinal',
    colors: [Color(0xFFE8E8E8), Color(0xFFFFFFFF)],
  ),
  LoginGradient(
    id: 'rosa_institucional',
    name: 'Rosa Institucional',
    colors: [Color(0xFFFFE5E5), Color(0xFFFFFFFF)],
  ),
  LoginGradient(
    id: 'verde_agua',
    name: 'Verde Agua',
    colors: [Color(0xFFDDF3E8), Color(0xFFFFFFFF)],
  ),
];

/// Gradientes especiales para festividades (tienen prioridad sobre la rotación)
const LoginGradient gradientAniversario = LoginGradient(
  id: 'aniversario',
  name: 'Aniversario Sexta',
  colors: [Color(0xFFFFF0C9), Color(0xFFFFF8E1)],
);

const LoginGradient gradientFiestasPatrias = LoginGradient(
  id: 'fiestas_patrias',
  name: 'Fiestas Patrias',
  colors: [Color(0xFFD6E4FF), Color(0xFFFFE5E5)],
);

const LoginGradient gradientDiaBombero = LoginGradient(
  id: 'dia_bombero',
  name: 'Día del Bombero',
  colors: [Color(0xFFFFDADA), Color(0xFFFFFFFF)],
);

const LoginGradient gradientNavidad = LoginGradient(
  id: 'navidad',
  name: 'Navidad y Año Nuevo',
  colors: [Color(0xFFDCE9D5), Color(0xFFFFF0C9)],
);
