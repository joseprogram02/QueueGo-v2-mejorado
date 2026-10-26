import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/delivery_request.dart';
import '../repositories/delivery_repository.dart';

/// Servicio encargado de gestionar los domicilios.
///
/// SRP:
/// Su responsabilidad es comunicarse con Supabase
/// para gestionar los domicilios.
///
/// DIP:
/// Implementa DeliveryRepository, por lo que la interfaz
/// no depende directamente de Supabase.
class SupabaseDeliveryService implements DeliveryRepository {
  final SupabaseClient _client;

  SupabaseDeliveryService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  @override
  Future<DeliveryRequest> createDeliveryRequest({
    required String requesterType,
    required String originAddress,
    required String destinationAddress,
    required String description,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'No hay un usuario autenticado.',
      );
    }

    final response = await _client
        .from('delivery_requests')
        .insert({
          'requester_id': user.id,
          'requester_type': requesterType,
          'origin_address': originAddress,
          'destination_address': destinationAddress,
          'description': description,
        })
        .select()
        .single();

    return DeliveryRequest.fromMap(
      response,
    );
  }

  @override
  Future<List<DeliveryRequest>> getMyDeliveries() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'No hay un usuario autenticado.',
      );
    }

    final response = await _client
        .from('delivery_requests')
        .select()
        .eq('requester_id', user.id)
        .order(
          'created_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (item) => DeliveryRequest.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}