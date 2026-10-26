import '../models/delivery_request.dart';

/// Abstracción para gestionar los domicilios.
///
/// DIP (Dependency Inversion Principle):
/// Las pantallas dependen de esta abstracción y no
/// directamente de Supabase.
abstract class DeliveryRepository {
  Future<DeliveryRequest> createDeliveryRequest({
    required String requesterType,
    required String originAddress,
    required String destinationAddress,
    required String description,
  });

  Future<List<DeliveryRequest>> getMyDeliveries();
}