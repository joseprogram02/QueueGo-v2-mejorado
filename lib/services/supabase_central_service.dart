
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/delivery_request.dart';
import '../repositories/central_repository.dart';

/// Servicio encargado de las operaciones de Central.
class SupabaseCentralService implements CentralRepository {
  final SupabaseClient _client;

  SupabaseCentralService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Obtiene las solicitudes que todavía están pendientes.
  @override
  Future<List<DeliveryRequest>> getPendingDeliveries() async {
    final response = await _client
        .from('delivery_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (item) => DeliveryRequest.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Obtiene las entregas asignadas o que están en proceso.
  @override
  Future<List<DeliveryRequest>> getActiveDeliveries() async {
    final response = await _client
        .from('delivery_requests')
        .select()
        .inFilter('status', ['assigned', 'picked_up', 'on_the_way'])
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (item) => DeliveryRequest.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Obtiene los repartidores activos.
  @override
  Future<List<Map<String, dynamic>>> getCouriers() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, email')
        .eq('role', 'courier')
        .eq('is_active', true)
        .order('full_name');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Obtiene las últimas ubicaciones registradas de los repartidores.
  @override
  Future<List<Map<String, dynamic>>> getCourierLocations() async {
    final response = await _client
        .from('courier_locations')
        .select('courier_id, latitude, longitude, updated_at');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Asigna una entrega a un repartidor.
  @override
  Future<void> assignDelivery({
    required String deliveryId,
    required double price,
    required String courierId,
  }) async {
    await _client
        .from('delivery_requests')
        .update({
          'price': price,
          'courier_id': courierId,
          'status': 'assigned',
          'assigned_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deliveryId);
  }

  /// Calcula las estadísticas de las entregas.
  @override
  Future<Map<String, int>> getDeliveryStats() async {
    final response = await _client
        .from('delivery_requests')
        .select('status');

    final rows = List<Map<String, dynamic>>.from(response);

    var pendientes = 0;
    var activos = 0;
    var completados = 0;

    for (final row in rows) {
      final status = row['status']?.toString();

      if (status == 'pending') {
        pendientes++;
      } else if ([
        'assigned',
        'picked_up',
        'on_the_way',
      ].contains(status)) {
        activos++;
      } else if (status == 'delivered') {
        completados++;
      }
    }

    return {
      'pending': pendientes,
      'active': activos,
      'completed': completados,
    };
  }
}
