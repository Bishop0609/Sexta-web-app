import 'package:flutter/widgets.dart';

/// Utilidad para determinar si el dispositivo es desktop o móvil
class ResponsiveUtils {
  /// Breakpoint para considerar desktop (pixels)
  static const double desktopBreakpoint = 600;

  /// Verifica si el ancho de pantalla es mayor al breakpoint
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > desktopBreakpoint;
  }

  /// Verifica si el ancho de pantalla es menor o  igual al breakpoint  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= desktopBreakpoint;
  }
}
