import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../services/supabase_auth_service.dart';
import '../auth/login_screen.dart';
import '../client/request_delivery_screen.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  final AuthRepository _authRepository = SupabaseAuthService();

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openRequestDelivery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const RequestDeliveryScreen(requesterType: 'restaurant'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Restaurante'),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido, Restaurante',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 8),

                const Text('Gestiona tus solicitudes de domicilio.'),

                const SizedBox(height: 32),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text('Solicitar domicilio'),
                    subtitle: const Text(
                      'Envía una nueva solicitud a Central.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _openRequestDelivery,
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Historial de domicilios'),
                    subtitle: const Text(
                      'Consulta tus solicitudes anteriores.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historial próximamente.'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
