import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/restaurant.dart';
import '../repositories/restaurant_repository.dart';

/// Implementación concreta del repositorio de restaurantes.
///
/// SRP:
/// Esta clase tiene una responsabilidad principal:
/// consultar restaurantes desde Supabase.
class SupabaseRestaurantService implements RestaurantRepository {
  final SupabaseClient _client;

  SupabaseRestaurantService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Restaurant>> getRestaurants() async {
    final response = await _client
        .from('restaurants')
        .select()
        .order('name');

    return (response as List)
        .map(
          (item) => Restaurant.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}