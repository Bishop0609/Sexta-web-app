import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores institucionales
  static const Color institutionalRed = Color(0xFFE60821); // Rojo Sexta Compañía
  static const Color navyBlue = Color(0xFF1A237E);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color white = Colors.white;
  
  // Colores de estadísticas
  static const Color efectivaColor = Color(0xFF2E7D32); // Verde para Efectiva
  static const Color abonoColor = Color(0xFF1976D2); // Azul para Abono
  static const Color warningColor = Color(0xFFF57C00); // Naranja
  static const Color criticalColor = Color(0xFFC62828); // Rojo crítico

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: institutionalRed,
        primary: institutionalRed,
        secondary: navyBlue,
        surface: white,
        error: criticalColor,
      ),
      
      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: navyBlue,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: navyBlue,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: navyBlue,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: institutionalRed,
        foregroundColor: white,
        elevation: 2,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      
      // Card
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: institutionalRed,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: institutionalRed,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: const BorderSide(color: institutionalRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: institutionalRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.inter(fontSize: 14),
      ),
      
      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: white,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      
      // DataTable (tablas densas)
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(navyBlue.withOpacity(0.1)),
        dataRowMinHeight: 36,
        dataRowMaxHeight: 48,
        headingTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: navyBlue,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
        ),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: lightBackground,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
