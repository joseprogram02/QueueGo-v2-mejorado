
import '../models/delivery_request.dart';

/// Abstracción para las operaciones de Central.
///
/// La interfaz de usuario depende de esta abstracción
/// y no directamente de Supabase.
abstract class CentralRepository {
  Future<List<DeliveryRequest>> getPendingDeliveries();

  Future<List<DeliveryRequest>> getActiveDeliveries();

  Future<List<Map<String, dynamic>>> getCouriers();
  Future<List<Map<String, dynamic>>> getCourierLocations();

  Future<void> assignDelivery({
    required String deliveryId,
    required double price,
    required String courierId,
  });

  Future<Map<String, int>> getDeliveryStats();
}
