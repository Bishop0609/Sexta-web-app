import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';

/// AppBar personalizado con logos de la compañía y GuntherSOFT
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
      title: Text(
        title, 
        style: const TextStyle(
          color: Colors.white,
          shadows: [
            Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
          ],
        ),
      ),
      backgroundColor: AppTheme.institutionalRed,
      iconTheme: const IconThemeData(color: Colors.white), // Icono de menú (izquierda) blanco
      actionsIconTheme: const IconThemeData(color: Colors.white), // Iconos de acción (derecha) blancos
      actions: [
        // Logos a la derecha
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Image.asset(
            'assets/images/logo_sexta_new.jpg',
            height: 48, // Aumentado un poco ya que ahora está solo
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
        // Acciones adicionales si las hay
        if (actions != null) ...actions!,
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
