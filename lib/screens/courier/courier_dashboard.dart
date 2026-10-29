
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
  const CourierDashboard({super.key});

  @override
  State<CourierDashboard> createState() =>
      _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  final AuthRepository _authRepository = SupabaseAuthService();
  final LocationRepository _locationRepository =
      SupabaseLocationService();
  final LocationService _locationService = LocationService();

  StreamSubscription? _locationSubscription;

  bool _gpsActive = false;
  bool _startingGps = false;
  bool _loggingOut = false;

  String _locationMessage = 'GPS no iniciado';

  static const Color _green = Color(0xFF138A5B);
  static const Color _darkGreen = Color(0xFF086744);
  static const Color _background = Color(0xFFF5F8F6);

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    if (_startingGps) return;

    if (mounted) {
      setState(() {
        _startingGps = true;
        _locationMessage = 'Solicitando permiso de ubicación...';
      });
    }

    try {
      final permitted = await _locationService.requestPermission();

      if (!mounted) return;

      if (!permitted) {
        setState(() {
          _gpsActive = false;
          _locationMessage = 'Permiso de ubicación no disponible';
        });
        return;
      }

      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        await _saveLocation(
          position.latitude,
          position.longitude,
        );
      }

      if (!mounted) return;

      await _locationSubscription?.cancel();

      _locationSubscription = _locationService.positionStream.listen(
        (position) async {
          await _saveLocation(
            position.latitude,
            position.longitude,
          );
        },
        onError: (Object error) {
          if (!mounted) return;

          setState(() {
            _locationMessage = 'No se pudo obtener la ubicación GPS';
          });

          debugPrint('Error en el flujo GPS: $error');
        },
      );

      setState(() {
        _gpsActive = true;
        if (position == null) {
          _locationMessage =
              'GPS activo. Esperando la primera ubicación...';
        } else {
          _locationMessage = 'Ubicación GPS activa';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _gpsActive = false;
        _locationMessage = 'No se pudo iniciar el GPS';
      });

      debugPrint('Error iniciando GPS: $error');
    } finally {
      if (mounted) {
        setState(() {
          _startingGps = false;
        });
      }
    }
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
        _gpsActive = true;
        _locationMessage =
            'Última ubicación: '
            '${latitude.toStringAsFixed(5)}, '
            '${longitude.toStringAsFixed(5)}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationMessage = 'Error al guardar la ubicación';
      });

      debugPrint('Error de ubicación: $error');
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await _locationSubscription?.cancel();
      await _authRepository.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión. Intenta nuevamente.'),
        ),
      );

      debugPrint('Error cerrando sesión: $error');
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QueueGo',
                  style: TextStyle(
                    color: _darkGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Panel del domiciliario',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            tooltip: 'Cerrar sesión',
            icon: _loggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.logout_rounded,
                    color: _darkGreen,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;
            final horizontalPadding = isWide ? 32.0 : 18.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcome(isWide),

                      const SizedBox(height: 28),

                      const Text(
                        'Estado de tu jornada',
                        style: TextStyle(
                          color: Color(0xFF24352D),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _buildGpsCard(),

                      const SizedBox(height: 24),

                      const Text(
                        'Gestión de entregas',
                        style: TextStyle(
                          color: Color(0xFF24352D),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _buildDeliveriesCard(),

                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE6EEE8),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: _green,
                              size: 25,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recuerda',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF24352D),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Mantén habilitada la ubicación para '
                                    'que el sistema pueda guardar tu '
                                    'posición y facilitar el seguimiento '
                                    'de tus entregas.',
                                    style: TextStyle(
                                      color: Color(0xFF68766E),
                                      height: 1.5,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcome(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 30 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkGreen, _green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PANEL DEL DOMICILIARIO',
                  style: TextStyle(
                    color: Color(0xFFD4F3E1),
                    fontSize: 11,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '¡Hola, Repartidor!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 30 : 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Consulta tus entregas y mantén actualizada '
                  'tu ubicación durante el servicio.',
                  style: TextStyle(
                    color: Color(0xFFE3F5EB),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _gpsActive
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _gpsActive ? 'GPS conectado' : 'GPS sin conectar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 24),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 78,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    final statusColor = _gpsActive
        ? const Color(0xFF16845A)
        : const Color(0xFFCB861C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _gpsActive
                      ? const Color(0xFFE2F5EB)
                      : const Color(0xFFFFF4DF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _gpsActive
                      ? Icons.location_on_rounded
                      : Icons.location_searching_rounded,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación del repartidor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF24352D),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Estado de la conexión GPS',
                      style: TextStyle(
                        color: Color(0xFF68766E),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _gpsActive
                      ? const Color(0xFFE2F5EB)
                      : const Color(0xFFFFF4DF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _gpsActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _locationMessage,
                    style: const TextStyle(
                      color: Color(0xFF53645A),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startingGps ? null : _startLocationTracking,
              icon: _startingGps
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                _startingGps ? 'Conectando...' : 'Reintentar GPS',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFFD5E5DA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AssignedDeliveriesScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EEE8)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F5EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: _green,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Domicilios asignados',
                          style: TextStyle(
                            color: Color(0xFF24352D),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Consulta y actualiza el estado de tus entregas.',
                          style: TextStyle(
                            color: Color(0xFF68766E),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: _green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AssignedDeliveriesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('Ver mis entregas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
