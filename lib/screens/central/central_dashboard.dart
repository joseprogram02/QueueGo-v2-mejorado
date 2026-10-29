
import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/delivery_request.dart';
import '../../services/supabase_central_service.dart';
import '../../widgets/central/delivery_map.dart';
import 'pending_deliveries_screen.dart';

class CentralDashboard extends StatefulWidget {
  const CentralDashboard({super.key});

  @override
  State<CentralDashboard> createState() => _CentralDashboardState();
}

class _CentralDashboardState extends State<CentralDashboard> {
  final SupabaseCentralService _service = SupabaseCentralService();

  Timer? _locationTimer;

  Map<String, int> _stats = {};
  List<DeliveryRequest> _pendingDeliveries = [];
  List<DeliveryRequest> _activeDeliveries = [];
  List<Map<String, dynamic>> _couriers = [];
  List<Map<String, dynamic>> _courierLocations = [];

  bool _loading = true;
  String? _error;
  String _selectedSection = 'Inicio';

  static const Color navy = Color(0xFF142B4A);
  static const Color blue = Color(0xFF2878D0);
  static const Color background = Color(0xFFF4F7FB);
  static const Color muted = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _loadDashboard();

    _locationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshTrackingData(),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getDeliveryStats(),
        _service.getPendingDeliveries(),
        _service.getActiveDeliveries(),
        _service.getCouriers(),
        _service.getCourierLocations(),
      ]);

      if (!mounted) return;

      setState(() {
        _stats = results[0] as Map<String, int>;
        _pendingDeliveries =
            results[1] as List<DeliveryRequest>;
        _activeDeliveries =
            results[2] as List<DeliveryRequest>;
        _couriers =
            results[3] as List<Map<String, dynamic>>;
        _courierLocations =
            results[4] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'No se pudieron cargar los datos. '
            'Comprueba la conexión y los permisos de Supabase.';
        _loading = false;
      });
    }
  }

  Future<void> _refreshTrackingData() async {
    try {
      final results = await Future.wait([
        _service.getCourierLocations(),
        _service.getActiveDeliveries(),
        _service.getDeliveryStats(),
      ]);

      if (!mounted) return;

      setState(() {
        _courierLocations =
            results[0] as List<Map<String, dynamic>>;
        _activeDeliveries =
            results[1] as List<DeliveryRequest>;
        _stats = results[2] as Map<String, int>;
      });
    } catch (e) {
      // Conservamos los datos actuales si falla una consulta.
      // El siguiente ciclo volverá a intentarlo.
    }
  }

  void _openRequests() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const PendingDeliveriesScreen(),
          ),
        )
        .then((_) => _loadDashboard());
  }

  void _selectSection(String section) {
    setState(() => _selectedSection = section);

    switch (section) {
      case 'Inicio':
        break;
      case 'Solicitudes':
        _openRequests();
        break;
      case 'Repartidores':
        _showCouriersDialog();
        break;
      case 'Seguimiento':
        _showTrackingDialog();
        break;
      case 'Reportes':
        _showInfo(
          'Resumen de reportes',
          'Pendientes: ${_stats['pending'] ?? 0}\n'
              'Activos: ${_stats['active'] ?? 0}\n'
              'Completados: ${_stats['completed'] ?? 0}',
        );
        break;
    }
  }

  void _showTrackingDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: blue),
            SizedBox(width: 10),
            Expanded(child: Text('Seguimiento de entregas')),
          ],
        ),
        content: Text(
          'Entregas activas: ${_activeDeliveries.length}\n'
          'Ubicaciones GPS registradas: ${_courierLocations.length}\n\n'
          'El mapa de operaciones del panel muestra las solicitudes '
          'y las ubicaciones recibidas de los repartidores. '
          'Los datos se actualizan cada 15 segundos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _loadDashboard();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCouriersDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Repartidores disponibles'),
        content: SizedBox(
          width: 420,
          child: _couriers.isEmpty
              ? const Text(
                  'No hay repartidores activos disponibles.',
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _couriers.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final courier = _couriers[index];
                    final name =
                        courier['full_name']?.toString() ??
                        'Sin nombre';
                    final email =
                        courier['email']?.toString() ?? '';

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE4F1FF),
                        child: Icon(
                          Icons.delivery_dining,
                          color: blue,
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(email),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1000;

            return Row(
              children: [
                if (desktop)
                  SizedBox(
                    width: 228,
                    child: _buildSidebar(),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(desktop),
                      Expanded(
                        child: _buildContent(
                          desktop: desktop,
                          width: constraints.maxWidth -
                              (desktop ? 228 : 0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 16, 30),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QueueGo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'CENTRAL DE OPERACIONES',
                        style: TextStyle(
                          color: Color(0xFFB8C8DD),
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'MENÚ PRINCIPAL',
              style: TextStyle(
                color: Color(0xFF91A7C2),
                fontSize: 10,
                letterSpacing: 1.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _navItem(Icons.dashboard_rounded, 'Inicio'),
          _navItem(Icons.receipt_long_rounded, 'Solicitudes'),
          _navItem(Icons.groups_rounded, 'Repartidores'),
          _navItem(Icons.location_on_rounded, 'Seguimiento'),
          _navItem(Icons.bar_chart_rounded, 'Reportes'),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF203C5E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF8FB8E8),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Panel administrativo\nGestión de domicilios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label) {
    final selected = _selectedSection == label;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Material(
        color: selected
            ? const Color(0xFF2878D0)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selectSection(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : const Color(0xFFB8C8DD),
                  size: 20,
                ),
                const SizedBox(width: 13),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFFD5DFEC),
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool desktop) {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 30 : 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7ECF3)),
        ),
      ),
      child: Row(
        children: [
          if (!desktop)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
              ),
            ),
          if (!desktop) const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desktop
                      ? 'Panel central'
                      : 'QueueGo · Central',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gestión y control de domicilios',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _loadDashboard,
            tooltip: 'Actualizar datos',
            icon: const Icon(
              Icons.refresh_rounded,
              color: navy,
            ),
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE4F1FF),
            child: Icon(
              Icons.person_outline_rounded,
              color: blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required bool desktop,
    required double width,
  }) {
    final sideBySide = width >= 1250;

    return SingleChildScrollView(
      padding: EdgeInsets.all(desktop ? 26 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Centro de operaciones',
            style: TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Controla las solicitudes y coordina las entregas.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFC64747),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFF9D3535),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadDashboard,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 23),
          _buildStats(width),
          const SizedBox(height: 24),
          if (sideBySide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildMapPanel(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildPendingPanel(),
                      const SizedBox(height: 18),
                      _buildActivePanel(),
                      const SizedBox(height: 18),
                      _buildCourierPanel(),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _buildMapPanel(),
            const SizedBox(height: 20),
            _buildPendingPanel(),
            const SizedBox(height: 20),
            _buildActivePanel(),
            const SizedBox(height: 20),
            _buildCourierPanel(),
          ],
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: Text(
              'QueueGo · Panel de gestión',
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(double width) {
    final compact = width < 550;

    return GridView.count(
      crossAxisCount: compact ? 1 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: compact ? 4.0 : 1.55,
      children: [
        _statCard(
          'Solicitudes pendientes',
          _stats['pending'] ?? 0,
          Icons.pending_actions_rounded,
          const Color(0xFFE6A23C),
        ),
        _statCard(
          'Domicilios activos',
          _stats['active'] ?? 0,
          Icons.local_shipping_rounded,
          blue,
        ),
        _statCard(
          'Entregas completadas',
          _stats['completed'] ?? 0,
          Icons.check_circle_rounded,
          const Color(0xFF21966A),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE7ECF3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loading ? '...' : '$value',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPanel() {
    final allDeliveries = [
      ..._pendingDeliveries,
      ..._activeDeliveries,
    ];

    return Container(
      height: 460,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE7ECF3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapa de operaciones',
                        style: TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Solicitudes, entregas activas y repartidores',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F1FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Valledupar',
                    style: TextStyle(
                      color: blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE7ECF3),
          ),
          Expanded(
            child: DeliveryMap(
              deliveries: allDeliveries,
              courierLocations: _courierLocations,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPanel() {
    final deliveries = _pendingDeliveries.take(4).toList();

    return _panel(
      title: 'Solicitudes pendientes',
      subtitle: 'Pedidos que esperan asignación',
      trailing: TextButton(
        onPressed: _openRequests,
        child: const Text('Ver todas'),
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : deliveries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No hay solicitudes pendientes.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < deliveries.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 20,
                          color: Color(0xFFE7ECF3),
                        ),
                      _deliveryRow(deliveries[i]),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openRequests,
                        icon: const Icon(
                          Icons.assignment_outlined,
                        ),
                        label: const Text(
                          'Gestionar solicitudes',
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildActivePanel() {
    final deliveries = _activeDeliveries.take(4).toList();

    return _panel(
      title: 'Entregas en curso',
      subtitle: 'Domicilios asignados o en camino',
      trailing: Icon(
        Icons.local_shipping_outlined,
        color: blue,
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : deliveries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No hay entregas activas en este momento.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < deliveries.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 20,
                          color: Color(0xFFE7ECF3),
                        ),
                      _deliveryRow(deliveries[i]),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F1FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            deliveries[i].status.label,
                            style: const TextStyle(
                              color: blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _deliveryRow(DeliveryRequest delivery) {
    final shortId = delivery.id.length > 8
        ? delivery.id.substring(0, 8)
        : delivery.id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3DB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Color(0xFFE6A23C),
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solicitud #$shortId',
                style: const TextStyle(
                  color: navy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                delivery.originAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Destino: ${delivery.destinationAddress}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourierPanel() {
    return _panel(
      title: 'Repartidores',
      subtitle: 'Perfiles activos registrados',
      trailing: IconButton(
        tooltip: 'Ver repartidores',
        onPressed: _showCouriersDialog,
        icon: const Icon(
          Icons.open_in_new_rounded,
          size: 18,
          color: blue,
        ),
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F6ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Color(0xFF21966A),
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Text(
                        'Repartidores activos',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${_couriers.length}',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ubicaciones GPS recibidas: '
                  '${_courierLocations.length}. '
                  'Consulta cada 15 segundos.',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showCouriersDialog,
                    child: const Text(
                      'Consultar repartidores',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE7ECF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
