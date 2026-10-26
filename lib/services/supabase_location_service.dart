import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/location_repository.dart';

class SupabaseLocationService
    implements LocationRepository {
  final SupabaseClient _client;

  SupabaseLocationService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  @override
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    await _client.from('courier_locations').upsert({
      'courier_id': user.id,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}