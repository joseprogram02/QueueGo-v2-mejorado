import '../models/restaurant.dart';

/// DIP:
/// La pantalla dependerá de esta abstracción y no directamente
/// de Supabase. Así podemos cambiar la fuente de datos
/// sin modificar la interfaz.
abstract class RestaurantRepository {
  Future<List<Restaurant>> getRestaurants();
}
