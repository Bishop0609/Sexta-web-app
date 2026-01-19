import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _rutController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.login(
      _rutController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Update Riverpod provider with logged-in user
        ref.read(currentUserProvider.notifier).state = result.user;
        
        if (result.requiresPasswordChange) {
          // Redirigir a cambio de contraseña obligatorio
          context.go('/change-password');
        } else {
          // Login exitoso - redirigir al dashboard
          context.go('/');
        }
      } else {
        setState(() {
          _errorMessage = result.error;
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
                      Icon(
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
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9kK-]')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text.replaceAll('-', '');
                            if (text.length <= 1) {
                              return newValue;
                            }
                            
                            // Format as XXXXXXXX-X
                            final formatted = '${text.substring(0, text.length - 1)}-${text[text.length - 1]}';
                            
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese su RUT';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: 'Ingrese su contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese su contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Olvidé mi contraseña
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Recuperar Contraseña'),
                                content: const Text(
                                  'Para recuperar tu contraseña, contacta al administrador del sistema.\n\n'
                                  'Email: admin@sextacompania.cl\n'
                                  'Teléfono: +56 9 XXXX XXXX',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('CERRAR'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: AppTheme.institutionalRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
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
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.criticalColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
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
                       
                       // Copyright
                       Text(
                         'Desarrollado por GuntherSOFT, 2026',
                         textAlign: TextAlign.center,
                         style: TextStyle(
                           fontSize: 11,
                           color: Colors.grey[600],
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
 }
