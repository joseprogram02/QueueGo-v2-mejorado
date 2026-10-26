import 'package:flutter/material.dart';

import '../../repositories/delivery_repository.dart';
import '../../services/supabase_delivery_service.dart';

class RequestDeliveryScreen extends StatefulWidget {
  final String requesterType;

  const RequestDeliveryScreen({super.key, this.requesterType = 'client'});

  @override
  State<RequestDeliveryScreen> createState() => _RequestDeliveryScreenState();
}

class _RequestDeliveryScreenState extends State<RequestDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // DIP:
  // La pantalla depende de DeliveryRepository
  // y no directamente de Supabase.
  final DeliveryRepository _deliveryRepository = SupabaseDeliveryService();

  bool _isLoading = false;

  bool get _isRestaurant => widget.requesterType == 'restaurant';

  String get _requesterName => _isRestaurant ? 'restaurante' : 'cliente';

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _requestDelivery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _deliveryRepository.createDeliveryRequest(
        requesterType: widget.requesterType,
        originAddress: _originController.text.trim(),
        destinationAddress: _destinationController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Domicilio solicitado correctamente.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo solicitar el domicilio: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar domicilio')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo domicilio',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Solicita un domicilio como $_requesterName. '
                    'Central establecerá el precio y asignará un repartidor.',
                  ),

                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _originController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de recogida',
                      hintText: 'Ej. Cra 5 # 12-34',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa la dirección de recogida.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _destinationController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de entrega',
                      hintText: 'Ej. Calle 18 # 7-21',
                      prefixIcon: Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa la dirección de entrega.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isLoading,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Información del domicilio',
                      hintText: 'Información adicional para el repartidor',
                      prefixIcon: Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El precio será establecido por Central '
                              'después de revisar la solicitud.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _requestDelivery,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.local_shipping_outlined),
                      label: Text(
                        _isLoading ? 'Solicitando...' : 'Solicitar domicilio',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
