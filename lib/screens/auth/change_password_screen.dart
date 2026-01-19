import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/auth_service.dart';

/// Screen for changing password on first login
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay sesión activa';
        });
      }
      return;
    }

    final result = await _authService.changePassword(
      userId: currentUser.id,
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Mostrar mensaje de éxito y redirigir al dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña cambiada exitosamente'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
        context.go('/');
      } else {
        setState(() {
          _errorMessage = result.error;
        });
      }
    }
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese una nueva contraseña';
    }

    final validation = _authService.validatePassword(value);
    if (!validation.isValid) {
      return validation.message;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme su nueva contraseña';
    }

    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icono
                      const Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(height: 16),

                      // Título
                      Text(
                        'Cambiar Contraseña',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.navyBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Por seguridad, debes cambiar tu contraseña temporal',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Contraseña actual
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña Temporal *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese su contraseña temporal';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Nueva contraseña
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña *',
                          prefixIcon: const Icon(Icons.vpn_key),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateNewPassword,
                        onChanged: (_) {
                          // Revalidar confirmación si ya tiene valor
                          if (_confirmPasswordController.text.isNotEmpty) {
                            _formKey.currentState!.validate();
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirmar contraseña
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña *',
                          prefixIcon: const Icon(Icons.check_circle_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleChangePassword(),
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 24),

                      // Requisitos de contraseña
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.abonoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.abonoColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppTheme.abonoColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Requisitos de contraseña',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.navyBlue,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildRequirement('Mínimo 8 caracteres'),
                            _buildRequirement('Al menos una mayúscula'),
                            _buildRequirement('Al menos un número'),
                            _buildRequirement('Al menos un carácter especial (!@#\$%&*)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.criticalColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.criticalColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.criticalColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.criticalColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Botón cambiar contraseña
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleChangePassword,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'CAMBIAR CONTRASEÑA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppTheme.abonoColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
