
import 'package:flutter/material.dart';

import '../../services/supabase_central_service.dart';
import 'pending_deliveries_screen.dart';

class CentralDashboard extends StatefulWidget {
  const CentralDashboard({super.key});

  @override
  State<CentralDashboard> createState() => _CentralDashboardState();
}

class _CentralDashboardState extends State<CentralDashboard> {
  final SupabaseCentralService _service = SupabaseCentralService();

  Map<String, int>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getDeliveryStats();

      if (!mounted) return;

      setState(() {
        _stats = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar las estadísticas. '
            'Comprueba la conexión y los permisos de Supabase.';
        _loading = false;
      });
    }
  }

  void _openRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PendingDeliveriesScreen(),
      ),
    );
  }

  void _showPendingFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature todavía no está conectado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _stats?['pending'];
    final active = _stats?['active'];
    final completed = _stats?['completed'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'QueueGo · Central',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF142B4A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar estadísticas',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 850;

            return SingleChildScrollView(
              padding: EdgeInsets.all(desktop ? 28 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panel central',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF142B4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Administra las solicitudes y coordina los '
                        'servicios de domicilio.',
                        style: TextStyle(color: Color(0xFF718096)),
                      ),
                      const SizedBox(height: 24),
                      _WelcomeCard(onTap: _openRequests),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Resumen general',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF142B4A),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _loading ? null : _loadStats,
                            tooltip: 'Actualizar',
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3DB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFF805719),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loadStats,
                            child: const Text('Reintentar'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 540
                                ? 2
                                : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            constraints.maxWidth < 540 ? 3.0 : 1.9,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _StatisticCard(
                            icon: Icons.pending_actions_rounded,
                            title: 'Solicitudes pendientes',
                            value: _loading
                                ? '…'
                                : pending?.toString() ?? '—',
                            color: const Color(0xFFE6A23C),
                          ),
                          _StatisticCard(
                            icon: Icons.local_shipping_rounded,
                            title: 'Domicilios activos',
                            value: _loading
                                ? '…'
                                : active?.toString() ?? '—',
                            color: const Color(0xFF3979D0),
                          ),
                          _StatisticCard(
                            icon: Icons.check_circle_rounded,
                            title: 'Entregas completadas',
                            value: _loading
                                ? '…'
                                : completed?.toString() ?? '—',
                            color: const Color(0xFF21966A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Herramientas de gestión',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF142B4A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: desktop ? 2 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: desktop ? 2.5 : 2.4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _DashboardCard(
                            icon: Icons.receipt_long_rounded,
                            title: 'Solicitudes pendientes',
                            description:
                                'Revisa pedidos y asigna precio y repartidor.',
                            color: const Color(0xFF245DA8),
                            onTap: _openRequests,
                          ),
                          _DashboardCard(
                            icon: Icons.groups_rounded,
                            title: 'Repartidores',
                            description:
                                'Consulta los repartidores registrados.',
                            color: const Color(0xFF21966A),
                            onTap: () =>
                                _showPendingFeature('Repartidores'),
                          ),
                          _DashboardCard(
                            icon: Icons.location_on_rounded,
                            title: 'Seguimiento',
                            description:
                                'Consulta el estado de los domicilios.',
                            color: const Color(0xFF875BC2),
                            onTap: () =>
                                _showPendingFeature('Seguimiento'),
                          ),
                          _DashboardCard(
                            icon: Icons.bar_chart_rounded,
                            title: 'Reportes',
                            description:
                                'Consulta las estadísticas de las entregas.',
                            color: const Color(0xFFE6A23C),
                            onTap: () => _showPendingFeature('Reportes'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'QueueGo · Panel de gestión',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 12,
                          ),
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
}

class _WelcomeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _WelcomeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF245DA8), Color(0xFF397ED0)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 18,
        children: [
          const SizedBox(
            width: 430,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CENTRO DE OPERACIONES',
                  style: TextStyle(
                    color: Color(0xFFD1E3FF),
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '¡Bienvenido a QueueGo!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Organiza las solicitudes y coordina los domicilios '
                  'desde un solo lugar.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF142B4A),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Ver solicitudes'),
          ),
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

  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF142B4A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF526176),
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
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFE7ECF3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF142B4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFF718096),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
