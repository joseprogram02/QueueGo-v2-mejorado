class Restaurant {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isOpen;

  const Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.isOpen,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isOpen: map['is_open'] as bool? ?? true,
    );
  }
}