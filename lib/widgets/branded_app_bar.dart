import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';

/// AppBar personalizado con logo del SGI
class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const BrandedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Text(
            title, 
            style: const TextStyle(
              color: Colors.white,
              shadows: [
                Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
              ],
            ),
          ),
          const Spacer(),
          // Logo SGI pegado al borde derecho
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: Image.asset(
              'assets/images/logo_sgi.png',
              height: 45, // Altura fija para controlar el tamaño
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.institutionalRed,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      bottom: bottom,
      titleSpacing: NavigationToolbar.kMiddleSpacing,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
