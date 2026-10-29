import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/delivery_request.dart';

class DeliveryMap extends StatefulWidget {
  final List<DeliveryRequest> deliveries;
  final List<Map<String, dynamic>> courierLocations;

  const DeliveryMap({
    super.key,
    this.deliveries = const [],
    this.courierLocations = const [],
  });

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(10.4631, -73.2532);

  LatLng get _center {
    for (final location in widget.courierLocations) {
      final latitude = _toDouble(location['latitude']);
      final longitude = _toDouble(location['longitude']);

      if (_isValidCoordinate(latitude, longitude)) {
        return LatLng(latitude!, longitude!);
      }
    }

    for (final delivery in widget.deliveries) {
      if (delivery.originLatitude != null && delivery.originLongitude != null) {
        return LatLng(delivery.originLatitude!, delivery.originLongitude!);
      }

      if (delivery.destinationLatitude != null &&
          delivery.destinationLongitude != null) {
        return LatLng(
          delivery.destinationLatitude!,
          delivery.destinationLongitude!,
        );
      }
    }

    return _defaultCenter;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  bool _isValidCoordinate(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Orígenes de las solicitudes: rojo.
    for (final delivery in widget.deliveries) {
      if (_isValidCoordinate(
        delivery.originLatitude,
        delivery.originLongitude,
      )) {
        markers.add(
          Marker(
            point: LatLng(delivery.originLatitude!, delivery.originLongitude!),
            width: 42,
            height: 48,
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFE65353),
              size: 40,
            ),
          ),
        );
      }

      // Destinos de las solicitudes: azul.
      if (_isValidCoordinate(
        delivery.destinationLatitude,
        delivery.destinationLongitude,
      )) {
        markers.add(
          Marker(
            point: LatLng(
              delivery.destinationLatitude!,
              delivery.destinationLongitude!,
            ),
            width: 42,
            height: 48,
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF2582E8),
              size: 40,
            ),
          ),
        );
      }
    }

    // Ubicaciones registradas de los repartidores: verde.
    for (final location in widget.courierLocations) {
      final latitude = _toDouble(location['latitude']);
      final longitude = _toDouble(location['longitude']);

      if (!_isValidCoordinate(latitude, longitude)) continue;

      markers.add(
        Marker(
          point: LatLng(latitude!, longitude!),
          width: 48,
          height: 52,
          child: const Icon(
            Icons.delivery_dining,
            color: Color(0xFF21966A),
            size: 38,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final markerCount =
        widget.deliveries.length +
        widget.courierLocations.where((location) {
          return _isValidCoordinate(
            _toDouble(location['latitude']),
            _toDouble(location['longitude']),
          );
        }).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.queuego.app',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: Color(0xFF2878D0)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      markerCount == 0
                          ? 'Mapa de operaciones · Valledupar'
                          : '$markerCount ubicaciones en el mapa',
                      style: const TextStyle(
                        color: Color(0xFF24364B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Centrar mapa',
                    onPressed: () {
                      _mapController.move(_center, 13);
                    },
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x18000000), blurRadius: 10),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapLegend(color: Color(0xFFE65353), label: 'Origen'),
                  SizedBox(height: 8),
                  _MapLegend(color: Color(0xFF2582E8), label: 'Destino'),
                  SizedBox(height: 8),
                  _MapLegend(color: Color(0xFF21966A), label: 'Repartidor'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 19),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 12),
        ),
      ],
    );
  }
}
