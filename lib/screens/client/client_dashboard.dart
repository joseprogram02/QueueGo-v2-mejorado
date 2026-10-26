import 'package:flutter/material.dart';
import 'request_delivery_screen.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QueueGo - Cliente'),
        actions: [
          IconButton(
            onPressed: () {
              // Próximamente:
              // mostrar las notificaciones del cliente.
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, Cliente',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            const Text('Gestiona tus domicilios desde QueueGo.'),

            const SizedBox(height: 24),

            // Estadísticas principales
            LayoutBuilder(
              builder: (context, constraints) {
                final int columns;

                if (constraints.maxWidth >= 900) {
                  columns = 3;
                } else if (constraints.maxWidth >= 600) {
                  columns = 2;
                } else {
                  columns = 1;
                }

                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  children: const [
                    _StatisticCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Domicilios solicitados',
                      value: '0',
                    ),
                    _StatisticCard(
                      icon: Icons.access_time,
                      title: 'Domicilios activos',
                      value: '0',
                    ),
                    _StatisticCard(
                      icon: Icons.check_circle_outline,
                      title: 'Domicilios entregados',
                      value: '0',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final int columns;

                  if (constraints.maxWidth >= 1000) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }

                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _DashboardCard(
                        icon: Icons.add_location_alt_outlined,
                        title: 'Solicitar domicilio',
                        description: 'Solicita un nuevo servicio de domicilio.',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RequestDeliveryScreen(),
                            ),
                          );
                        },
                      ),

                      _DashboardCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Mis domicilios',
                        description:
                            'Consulta el historial de tus solicitudes.',
                        onTap: () {
                          // Próximo bloque:
                          // historial de domicilios.
                        },
                      ),

                      _DashboardCard(
                        icon: Icons.map_outlined,
                        title: 'Seguimiento',
                        description:
                            'Observa en el mapa dónde se encuentra '
                            'tu repartidor.',
                        onTap: () {
                          // Próximo bloque:
                          // mapa + GPS + Realtime.
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(title, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42),

              const SizedBox(height: 12),

              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
