
import 'package:flutter/material.dart';

import 'request_delivery_screen.dart';
import 'client_tracking_screen.dart';
import 'client_delivery_history_screen.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  static const Color _green = Color(0xFF138A5B);
  static const Color _darkGreen = Color(0xFF086744);
  static const Color _background = Color(0xFFF5F8F6);

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
                Icons.delivery_dining,
                color: Colors.white,
                size: 25,
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
                  'Panel del cliente',
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Las notificaciones estarán disponibles próximamente.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: _darkGreen,
            ),
            tooltip: 'Notificaciones',
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
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcome(context, isWide),
                      const SizedBox(height: 26),

                      const Text(
                        'Resumen de actividad',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF24352D),
                        ),
                      ),
                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final width = gridConstraints.maxWidth;
                          final columns = width >= 850
                              ? 3
                              : width >= 520
                                  ? 2
                                  : 1;

                          return GridView.count(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            childAspectRatio: columns == 1
                                ? 3.1
                                : columns == 2
                                    ? 1.8
                                    : 1.55,
                            children: const [
                              _StatisticCard(
                                icon: Icons.receipt_long_rounded,
                                title: 'Solicitados',
                                value: '0',
                                color: Color(0xFF3478D4),
                                background: Color(0xFFEAF2FF),
                              ),
                              _StatisticCard(
                                icon: Icons.local_shipping_rounded,
                                title: 'En proceso',
                                value: '0',
                                color: Color(0xFFCB861C),
                                background: Color(0xFFFFF4DF),
                              ),
                              _StatisticCard(
                                icon: Icons.check_circle_rounded,
                                title: 'Entregados',
                                value: '0',
                                color: Color(0xFF16845A),
                                background: Color(0xFFE2F5EB),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        '¿Qué necesitas hacer?',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF24352D),
                        ),
                      ),
                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final columns =
                              gridConstraints.maxWidth >= 850 ? 3 : 1;

                          return GridView.count(
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            childAspectRatio:
                                columns == 1 ? 3.0 : 0.92,
                            children: [
                              _DashboardCard(
                                icon: Icons.add_location_alt_rounded,
                                title: 'Solicitar domicilio',
                                description:
                                    'Registra un nuevo servicio y '
                                    'comparte los detalles de tu envío.',
                                color: _green,
                                background:
                                    const Color(0xFFE3F5EB),
                                label: 'Crear solicitud',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RequestDeliveryScreen(),
                                    ),
                                  );
                                },
                              ),
                              _DashboardCard(
                                icon: Icons.receipt_long_rounded,
                                title: 'Mis domicilios',
                                description:
                                    'Consulta tus solicitudes y revisa '
                                    'el estado de tus envíos.',
                                color: const Color(0xFF3478D4),
                                background:
                                    const Color(0xFFEAF2FF),
                                label: 'Ver domicilios',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ClientDeliveryHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              _DashboardCard(
                                icon: Icons.location_searching_rounded,
                                title: 'Seguimiento',
                                description:
                                    'Consulta el mapa y la última '
                                    'ubicación disponible de tu repartidor.',
                                color: const Color(0xFF8057C7),
                                background:
                                    const Color(0xFFF0E9FC),
                                label: 'Ver mapa',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ClientTrackingScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 22),

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
                              Icons.info_outline_rounded,
                              color: _green,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tu experiencia en QueueGo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF24352D),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Desde aquí puedes solicitar '
                                    'domicilios y consultar el historial '
                                    'o el seguimiento de tus envíos.',
                                    style: TextStyle(
                                      color: Color(0xFF68766E),
                                      height: 1.45,
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

  Widget _buildWelcome(BuildContext context, bool isWide) {
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
                  'BIENVENIDO A QUEUEGO',
                  style: TextStyle(
                    color: Color(0xFFD4F3E1),
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '¡Hola, Cliente!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 30 : 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Gestiona tus domicilios de forma sencilla '
                  'y sigue tus envíos desde un solo lugar.',
                  style: TextStyle(
                    color: Color(0xFFE3F5EB),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _darkGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RequestDeliveryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Solicitar domicilio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 24),
            Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 82,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color background;

  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF68766E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;
  final String label;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE6EEE8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 29),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24352D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF68766E),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
