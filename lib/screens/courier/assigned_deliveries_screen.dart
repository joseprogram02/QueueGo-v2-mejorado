import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/delivery_request.dart';
import '../../repositories/courier_repository.dart';
import '../../services/supabase_courier_service.dart';

class AssignedDeliveriesScreen extends StatefulWidget {
  const AssignedDeliveriesScreen({super.key});

  @override
  State<AssignedDeliveriesScreen> createState() =>
      _AssignedDeliveriesScreenState();
}

class _AssignedDeliveriesScreenState extends State<AssignedDeliveriesScreen> {
  final CourierRepository _repository = SupabaseCourierService();

  final ImagePicker _imagePicker = ImagePicker();

  List<DeliveryRequest> _deliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _loading = true;
    });

    try {
      final deliveries = await _repository.getAssignedDeliveries();

      if (!mounted) return;

      setState(() {
        _deliveries = deliveries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar domicilios: $error')),
      );
    }
  }

  Future<void> _takeProof(DeliveryRequest delivery) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subiendo evidencia...')));

      await _repository.completeDelivery(
        deliveryId: delivery.id,
        imagePath: image.path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega completada correctamente.')),
      );

      await _loadDeliveries();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar la entrega: $error')),
      );
    }
  }

  Future<void> _updateStatus(
    DeliveryRequest delivery,
    DeliveryStatus nextStatus,
  ) async {
    try {
      await _repository.updateDeliveryStatus(
        deliveryId: delivery.id,
        status: nextStatus.value,
      );

      await _loadDeliveries();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis domicilios'),
        actions: [
          IconButton(
            onPressed: _loadDeliveries,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deliveries.isEmpty) {
      return const Center(child: Text('No tienes domicilios asignados.'));
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _deliveries.length,
        itemBuilder: (context, index) {
          final delivery = _deliveries[index];

          return _DeliveryCard(
            delivery: delivery,
            onStatusChange: (status) {
              _updateStatus(delivery, status);
            },
            onTakeProof: () {
              _takeProof(delivery);
            },
          );
        },
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryRequest delivery;
  final ValueChanged<DeliveryStatus> onStatusChange;
  final VoidCallback onTakeProof;

  const _DeliveryCard({
    required this.delivery,
    required this.onStatusChange,
    required this.onTakeProof,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Domicilio ${delivery.id.substring(0, 8)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 16),

            Text('Recogida: ${delivery.originAddress}'),

            const SizedBox(height: 8),

            Text('Entrega: ${delivery.destinationAddress}'),

            const SizedBox(height: 12),

            Text(
              'Valor: \$${delivery.price?.toStringAsFixed(0) ?? 'Pendiente'}',
            ),

            const SizedBox(height: 12),

            Chip(label: Text(delivery.status.label)),

            const SizedBox(height: 16),

            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (delivery.status) {
      case DeliveryStatus.assigned:
        return FilledButton.icon(
          onPressed: () {
            onStatusChange(DeliveryStatus.pickedUp);
          },
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Marcar como recogido'),
        );

      case DeliveryStatus.pickedUp:
        return FilledButton.icon(
          onPressed: () {
            onStatusChange(DeliveryStatus.onTheWay);
          },
          icon: const Icon(Icons.navigation_outlined),
          label: const Text('Iniciar entrega'),
        );

      case DeliveryStatus.onTheWay:
        return FilledButton.icon(
          onPressed: onTakeProof,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Tomar evidencia'),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
