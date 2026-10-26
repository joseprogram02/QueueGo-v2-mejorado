enum DeliveryStatus {
  pending,
  assigned,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get value {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.assigned:
        return 'assigned';
      case DeliveryStatus.pickedUp:
        return 'picked_up';
      case DeliveryStatus.onTheWay:
        return 'on_the_way';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pendiente';
      case DeliveryStatus.assigned:
        return 'Asignado';
      case DeliveryStatus.pickedUp:
        return 'Recogido';
      case DeliveryStatus.onTheWay:
        return 'En camino';
      case DeliveryStatus.delivered:
        return 'Entregado';
      case DeliveryStatus.cancelled:
        return 'Cancelado';
    }
  }
}

class DeliveryRequest {
  final String id;
  final String requesterId;
  final String requesterType;

  final String originAddress;
  final double? originLatitude;
  final double? originLongitude;

  final String destinationAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;

  final String? description;
  final double? price;

  final DeliveryStatus status;
  final String? courierId;
  final String? proofPhotoUrl;

  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime updatedAt;

  const DeliveryRequest({
    required this.id,
    required this.requesterId,
    required this.requesterType,
    required this.originAddress,
    this.originLatitude,
    this.originLongitude,
    required this.destinationAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.description,
    required this.price,
    required this.status,
    this.courierId,
    this.proofPhotoUrl,
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.updatedAt,
  });

  factory DeliveryRequest.fromMap(
    Map<String, dynamic> map,
  ) {
    return DeliveryRequest(
      id: map['id'] as String,
      requesterId: map['requester_id'] as String,
      requesterType: map['requester_type'] as String,
      originAddress: map['origin_address'] as String,
      originLatitude:
          (map['origin_latitude'] as num?)?.toDouble(),
      originLongitude:
          (map['origin_longitude'] as num?)?.toDouble(),
      destinationAddress:
          map['destination_address'] as String,
      destinationLatitude:
          (map['destination_latitude'] as num?)?.toDouble(),
      destinationLongitude:
          (map['destination_longitude'] as num?)?.toDouble(),
      description: map['description'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      status: _statusFromString(
        map['status'] as String,
      ),
      courierId: map['courier_id'] as String?,
      proofPhotoUrl: map['proof_photo_url'] as String?,
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
      assignedAt: _dateFromString(
        map['assigned_at'],
      ),
      pickedUpAt: _dateFromString(
        map['picked_up_at'],
      ),
      deliveredAt: _dateFromString(
        map['delivered_at'],
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }

  static DeliveryStatus _statusFromString(
    String value,
  ) {
    switch (value) {
      case 'assigned':
        return DeliveryStatus.assigned;
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'on_the_way':
        return DeliveryStatus.onTheWay;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pending;
    }
  }

  static DateTime? _dateFromString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value as String);
  }
}