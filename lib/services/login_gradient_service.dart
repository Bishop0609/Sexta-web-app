import '../data/login_gradients.dart';

/// Servicio que selecciona el gradiente del login según la fecha actual.
///
/// Prioridad:
/// 1. Festividades (aniversario, fiestas patrias, día del bombero, navidad)
/// 2. Rotación diaria basada en el día del año
class LoginGradientService {
  /// Fecha de fundación de la Sexta Compañía de Bomberos de Coquimbo
  static final DateTime foundationDate = DateTime(1967, 11, 9);

  /// Retorna el gradiente que corresponde al día actual
  static LoginGradient getCurrentGradient() {
    final now = DateTime.now().toLocal();

    // 1. Aniversario Sexta (9 de noviembre) — máxima prioridad
    if (now.month == 11 && now.day == 9) {
      return gradientAniversario;
    }

    // 2. Fiestas Patrias (18-19 de septiembre)
    if (now.month == 9 && (now.day == 18 || now.day == 19)) {
      return gradientFiestasPatrias;
    }

    // 3. Día del Bombero de Chile (30 de junio)
    if (now.month == 6 && now.day == 30) {
      return gradientDiaBombero;
    }

    // 4. Navidad y Año Nuevo (24 dic — 6 ene)
    if ((now.month == 12 && now.day >= 24) ||
        (now.month == 1 && now.day <= 6)) {
      return gradientNavidad;
    }

    // 5. Rotación diaria basada en día del año
    final dayOfYear = _dayOfYear(now);
    final index = dayOfYear % dailyGradients.length;
    return dailyGradients[index];
  }

  /// Retorna el texto del contador de días desde la fundación
  /// Formato: "Al servicio hace 21.336 días"
  static String getDaysOfServiceText() {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(foundationDate).inDays;
    final formatted = _formatWithDots(days);
    return 'Al servicio hace $formatted días';
  }

  // ─── Helpers privados ────────────────────────────────────────────

  /// Calcula el día del año (1-366)
  static int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  /// Formatea un número entero con puntos como separador de miles
  /// Ejemplo: 21336 → "21.336"
  static String _formatWithDots(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
