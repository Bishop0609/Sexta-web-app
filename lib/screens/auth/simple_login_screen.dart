import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/simple_auth_service.dart';

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key});

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _authService = SimpleAuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _rutController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.login(_rutController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Login exitoso - redirigir al dashboard
        context.go('/');
      } else {
        setState(() {
          _errorMessage = result['error'] as String;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
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
                      // Logo/Icono
                      const Icon(
                        Icons.local_fire_department,
                        size: 80,
                        color: AppTheme.institutionalRed,
                      ),
                      const SizedBox(height: 16),
                      
                      // Título
                      Text(
                        'SEXTA COMPAÑÍA',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.navyBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistema de Gestión Integral',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // RUT
                      TextFormField(
                        controller: _rutController,
                        decoration: const InputDecoration(
                          labelText: 'RUT',
                          hintText: '12345678-9',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese su RUT';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      
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
                      
                      // Botón login
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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
                                  'INGRESAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Info de usuarios de prueba
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.abonoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppTheme.abonoColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Usuarios de prueba',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.navyBlue,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildUserDemo('Admin', '12345678-9'),
                            const SizedBox(height: 6),
                            _buildUserDemo('Oficial', '23456789-0'),
                            const SizedBox(height: 6),
                            _buildUserDemo('Bombero', '45678901-2'),
                            const SizedBox(height: 8),
                            Text(
                              'Solo ingresa el RUT para acceder',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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

  Widget _buildUserDemo(String role, String rut) {
    return Row(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.navyBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            role,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.navyBlue,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rut,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
