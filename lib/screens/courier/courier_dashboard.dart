import 'dart:async';

import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/location_repository.dart';
import '../../services/location_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_location_service.dart';
import '../auth/login_screen.dart';
import 'assigned_deliveries_screen.dart';

class CourierDashboard extends StatefulWidget {
  const CourierDashboard({
    super.key,
  });

  @override
  State<CourierDashboard> createState() =>
      _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  // DIP:
  // El dashboard depende de abstracciones (Repository),
  // no directamente de Supabase.
  final AuthRepository _authRepository =
      SupabaseAuthService();

  final LocationRepository _locationRepository =
      SupabaseLocationService();

  final LocationService _locationService =
      LocationService();

  StreamSubscription? _locationSubscription;

  bool _gpsActive = false;
  String _locationMessage = 'GPS no iniciado';

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    final permitted =
        await _locationService.requestPermission();

    if (!permitted) {
      if (!mounted) return;

      setState(() {
        _locationMessage =
            'Permiso de ubicación no disponible';
      });

      return;
    }

    final position =
        await _locationService.getCurrentPosition();

    if (position != null) {
      await _saveLocation(
        position.latitude,
        position.longitude,
      );
    }

    _locationSubscription =
        _locationService.positionStream.listen(
      (position) async {
        await _saveLocation(
          position.latitude,
          position.longitude,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _gpsActive = true;
      _locationMessage =
          'Ubicación en tiempo real activa';
    });
  }

  Future<void> _saveLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      await _locationRepository.saveLocation(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _locationMessage =
            'GPS actualizado: '
            '${latitude.toStringAsFixed(5)}, '
            '${longitude.toStringAsFixed(5)}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationMessage =
            'Error actualizando GPS';
      });

      debugPrint(
        'Error de ubicación: $error',
      );
    }
  }

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Repartidor',
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido, Repartidor',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Gestiona los domicilios que te han sido asignados.',
                ),

                const SizedBox(height: 24),

                Card(
                  child: ListTile(
                    leading: Icon(
                      _gpsActive
                          ? Icons.location_on
                          : Icons.location_off,
                    ),
                    title: const Text(
                      'Ubicación del repartidor',
                    ),
                    subtitle: Text(
                      _locationMessage,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_shipping_outlined,
                    ),
                    title: const Text(
                      'Domicilios asignados',
                    ),
                    subtitle: const Text(
                      'Consulta y actualiza tus entregas.',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AssignedDeliveriesScreen(),
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