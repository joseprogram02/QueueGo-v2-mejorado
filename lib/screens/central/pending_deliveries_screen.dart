import 'package:flutter/material.dart';

import '../../models/delivery_request.dart';
import '../../repositories/central_repository.dart';
import '../../services/supabase_central_service.dart';

class PendingDeliveriesScreen extends StatefulWidget {
  const PendingDeliveriesScreen({super.key});

  @override
  State<PendingDeliveriesScreen> createState() =>
      _PendingDeliveriesScreenState();
}

class _PendingDeliveriesScreenState extends State<PendingDeliveriesScreen> {
  final CentralRepository _centralRepository = SupabaseCentralService();

  List<DeliveryRequest> _deliveries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deliveries = await _centralRepository.getPendingDeliveries();

      if (!mounted) {
        return;
      }

      setState(() {
        _deliveries = deliveries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'No se pudieron cargar las solicitudes: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAssignDialog(DeliveryRequest delivery) async {
    final priceController = TextEditingController();

    String? selectedCourierId;

    try {
      final couriers = await _centralRepository.getCouriers();

      if (!mounted) {
        return;
      }

      if (couriers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay repartidores disponibles.')),
        );

        return;
      }

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Asignar domicilio'),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitud ${delivery.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor del domicilio',
                          hintText: 'Ej. 8000',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCourierId,
                        decoration: const InputDecoration(
                          labelText: 'Repartidor',
                          border: OutlineInputBorder(),
                        ),
                        items: couriers.map((courier) {
                          final id = courier['id'] as String;

                          final name =
                              courier['full_name'] as String? ?? 'Sin nombre';

                          final email = courier['email'] as String? ?? '';

                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              email.isEmpty ? name : '$name - $email',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCourierId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancelar'),
                  ),

                  FilledButton(
                    onPressed: selectedCourierId == null
                        ? null
                        : () async {
                            final price = double.tryParse(
                              priceController.text.trim(),
                            );

                            if (price == null || price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ingresa un valor válido.'),
                                ),
                              );

                              return;
                            }

                            final courierId = selectedCourierId!;

                            Navigator.of(dialogContext).pop();

                            await _assignDelivery(
                              delivery.id,
                              price,
                              courierId,
                            );
                          },
                    child: const Text('Asignar domicilio'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      priceController.dispose();
    }
  }

  Future<void> _assignDelivery(
    String deliveryId,
    double price,
    String courierId,
  ) async {
    if (courierId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un repartidor.')),
      );

      return;
    }

    try {
      await _centralRepository.assignDelivery(
        deliveryId: deliveryId,
        price: price,
        courierId: courierId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Domicilio asignado correctamente.')),
      );

      await _loadDeliveries();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo asignar el domicilio: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes pendientes'),
        actions: [
          IconButton(
            onPressed: _loadDeliveries,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _loadDeliveries,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_deliveries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 64),

              SizedBox(height: 16),

              Text(
                'No hay solicitudes pendientes.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _deliveries.length,
        itemBuilder: (context, index) {
          final delivery = _deliveries[index];

          return _DeliveryCard(
            delivery: delivery,
            onAssign: () {
              _showAssignDialog(delivery);
            },
          );
        },
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryRequest delivery;
  final VoidCallback onAssign;

  const _DeliveryCard({required this.delivery, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Solicitud ${delivery.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                Chip(label: Text(delivery.status.label)),
              ],
            ),

            const SizedBox(height: 20),

            _AddressRow(
              icon: Icons.location_on_outlined,
              title: 'Recogida',
              address: delivery.originAddress,
            ),

            const SizedBox(height: 12),

            _AddressRow(
              icon: Icons.flag_outlined,
              title: 'Entrega',
              address: delivery.destinationAddress,
            ),

            if (delivery.description != null &&
                delivery.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),

              Text(
                'Información',
                style: Theme.of(context).textTheme.titleSmall,
              ),

              const SizedBox(height: 4),

              Text(delivery.description!),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('Establecer precio y asignar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.title,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),

              const SizedBox(height: 4),

              Text(address),
            ],
          ),
        ),
      ],
    );
  }
}
