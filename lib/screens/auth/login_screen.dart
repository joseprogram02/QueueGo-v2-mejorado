import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../repositories/auth_repository.dart';
import '../../services/supabase_auth_service.dart';

import '../client/client_dashboard.dart';
import '../restaurant/restaurant_dashboard.dart';
import '../courier/courier_dashboard.dart';
import '../central/central_dashboard.dart';
import 'register_screen.dart';

/// Pantalla principal de autenticación.
///
/// SRP:
/// Esta pantalla se encarga de la interacción de inicio
/// de sesión y navegación según el rol.
///
/// DIP:
/// La pantalla depende de AuthRepository y no directamente
/// de Supabase.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // DIP:
  // Dependemos de la abstracción AuthRepository.
  final AuthRepository _authRepository = SupabaseAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final role = await _authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (role == null) {
        _showError('No se encontró un rol válido para este usuario.');
        return;
      }

      _openDashboard(role);
    } catch (error) {
      if (!mounted) return;

      _showError(_getErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDashboard(UserRole role) {
    Widget dashboard;

    switch (role) {
      case UserRole.client:
        dashboard = const ClientDashboard();
        break;

      case UserRole.restaurant:
        dashboard = const RestaurantDashboard();
        break;

      case UserRole.courier:
        dashboard = const CourierDashboard();
        break;

      case UserRole.central:
        dashboard = const CentralDashboard();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('invalid_credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (message.contains('Email not confirmed')) {
      return 'Debes confirmar tu correo electrónico.';
    }

    if (message.contains('network')) {
      return 'No hay conexión con el servidor.';
    }

    return 'No se pudo iniciar sesión.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    Text(
                      'QueueGo',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'ejemplo@correo.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu correo.';
                        }

                        if (!value.contains('@')) {
                          return 'Ingresa un correo válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _login();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contraseña.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _isLoading ? null : _openRegister,
                      child: const Text('¿No tienes una cuenta? Registrarse'),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
