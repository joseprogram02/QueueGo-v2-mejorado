import '../models/delivery_request.dart';

/// Contrato de las operaciones disponibles para el repartidor.
///
/// DIP:
/// La interfaz de usuario depende de esta abstracción,
/// no directamente de Supabase.
abstract class CourierRepository {
  /// Obtiene los domicilios asignados al repartidor autenticado.
  Future<List<DeliveryRequest>> getAssignedDeliveries();

  /// Actualiza el estado de un domicilio.
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
  });

  /// Sube la evidencia fotográfica y completa el domicilio.
  Future<void> completeDelivery({
    required String deliveryId,
    required String imagePath,
  });
}