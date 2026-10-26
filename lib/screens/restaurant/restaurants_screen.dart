import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/supabase_restaurant_service.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final RestaurantRepository _repository =
      SupabaseRestaurantService();

  late Future<List<Restaurant>> _restaurantsFuture;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() {
    _restaurantsFuture = _repository.getRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los restaurantes.\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final restaurants = snapshot.data ?? [];

          if (restaurants.isEmpty) {
            return const Center(
              child: Text('No hay restaurantes disponibles.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadRestaurants);
              await _restaurantsFuture;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 600
                            ? 2
                            : 1;

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    return _RestaurantCard(
                      restaurant: restaurants[index],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantCard({
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Próximo paso:
          // abrir productos del restaurante.
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.restaurant,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                restaurant.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                restaurant.description ??
                    'Restaurante QueueGo',
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    restaurant.isOpen
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    restaurant.isOpen
                        ? 'Abierto'
                        : 'Cerrado',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}