
import 'package:flutter/material.dart';

import '../../models/delivery_request.dart';
import '../../services/supabase_delivery_service.dart';

class ClientDeliveryHistoryScreen extends StatefulWidget {
  const ClientDeliveryHistoryScreen({super.key});

  @override
  State<ClientDeliveryHistoryScreen> createState() =>
      _ClientDeliveryHistoryScreenState();
}

class _ClientDeliveryHistoryScreenState
    extends State<ClientDeliveryHistoryScreen> {
  final SupabaseDeliveryService _deliveryService =
      SupabaseDeliveryService();

  List<DeliveryRequest> _deliveries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final deliveries = await _deliveryService.getMyDeliveries();

      if (!mounted) return;

      setState(() {
        _deliveries = deliveries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudo cargar el historial. '
            'Comprueba tu sesiÃ³n y la conexiÃ³n con Supabase.';
      });

      debugPrint('Error cargando historial: $error');
    }
  }

  String _statusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pendiente';
      case DeliveryStatus.assigned:
        return 'Asignado';
      case DeliveryStatus.pickedUp:
        return 'Recogido';
      case DeliveryStatus.onTheWay:
        return 'En camino';
      case DeliveryStatus.delivered:
        return 'Entregado';
      case DeliveryStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _statusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return const Color(0xFFB7791F);
      case DeliveryStatus.assigned:
        return const Color(0xFF3478D4);
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.onTheWay:
        return const Color(0xFF8057C7);
      case DeliveryStatus.delivered:
        return const Color(0xFF16845A);
      case DeliveryStatus.cancelled:
        return const Color(0xFFC0392B);
    }
  }

  Color _statusBackground(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return const Color(0xFFFFF4DF);
      case DeliveryStatus.assigned:
        return const Color(0xFFEAF2FF);
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.onTheWay:
        return const Color(0xFFF0E9FC);
      case DeliveryStatus.delivered:
        return const Color(0xFFE2F5EB);
      case DeliveryStatus.cancelled:
        return const Color(0xFFFCE8E6);
    }
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} Â· '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mis domicilios',
          style: TextStyle(
            color: Color(0xFF086744),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDeliveries,
            tooltip: 'Actualizar historial',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF086744),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDeliveries,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(
            child: CircularProgressIndicator(
              color: Color(0xFF138A5B),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text('Cargando tus domicilios...'),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_outlined,
            size: 64,
            color: Color(0xFF87958C),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pudimos cargar tus domicilios',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF68766E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
            ),
          ),
        ],
      );
    }

    if (_deliveries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 90),
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Color(0xFF9BAAA0),
          ),
          SizedBox(height: 18),
          Text(
            'TodavÃ­a no tienes domicilios',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF24352D),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cuando realices una solicitud, aparecerÃ¡ aquÃ­ '
            'para que puedas consultar su estado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF68766E),
              height: 1.5,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF086744),
                Color(0xFF138A5B),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 38,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu historial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_deliveries.length} '
                      '${_deliveries.length == 1 ? 'domicilio registrado' : 'domicilios registrados'}',
                      style: const TextStyle(
                        color: Color(0xFFE3F5EB),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final delivery in _deliveries)
          _DeliveryHistoryCard(
            delivery: delivery,
            statusLabel: _statusLabel(delivery.status),
            statusColor: _statusColor(delivery.status),
            statusBackground: _statusBackground(delivery.status),
            formattedDate: _formatDate(delivery.createdAt),
          ),
      ],
    );
  }
}

class _DeliveryHistoryCard extends StatelessWidget {
  final DeliveryRequest delivery;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String formattedDate;

  const _DeliveryHistoryCard({
    required this.delivery,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Domicilio #${delivery.id}',
                style: const TextStyle(
                  color: Color(0xFF24352D),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AddressRow(
            icon: Icons.trip_origin_rounded,
            color: const Color(0xFF16845A),
            label: 'Origen',
            address: delivery.originAddress,
          ),
          const SizedBox(height: 12),
          _AddressRow(
            icon: Icons.location_on_rounded,
            color: const Color(0xFFC0392B),
            label: 'Destino',
            address: delivery.destinationAddress,
          ),
          if ((delivery.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              delivery.description ?? '',
              style: const TextStyle(
                color: Color(0xFF68766E),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 15),
          const Divider(color: Color(0xFFE9EEEA)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF68766E),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Color(0xFF68766E),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF68766E),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: const TextStyle(
                  color: Color(0xFF24352D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


