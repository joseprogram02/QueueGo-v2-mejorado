import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/delivery_request.dart';
import '../repositories/courier_repository.dart';

class SupabaseCourierService implements CourierRepository {
  final SupabaseClient _client;

  SupabaseCourierService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<DeliveryRequest>> getAssignedDeliveries() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    final response = await _client
        .from('delivery_requests')
        .select()
        .eq('courier_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => DeliveryRequest.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
  }) async {
    await _client
        .from('delivery_requests')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deliveryId)
        .eq('courier_id', _client.auth.currentUser!.id);
  }

  @override
  Future<void> completeDelivery({
    required String deliveryId,
    required String imagePath,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    final image = XFile(imagePath);
    final bytes = await image.readAsBytes();

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storagePath = '${user.id}/$fileName';

    await _client.storage
        .from('delivery-proofs')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    final proofUrl = await _client.storage
        .from('delivery-proofs')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 30);

    await _client
        .from('delivery_requests')
        .update({
          'proof_photo_url': proofUrl,
          'status': 'delivered',
          'delivered_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deliveryId)
        .eq('courier_id', user.id);
  }
}
