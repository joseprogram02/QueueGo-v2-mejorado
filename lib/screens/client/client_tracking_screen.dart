
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientTrackingScreen extends StatefulWidget {
  const ClientTrackingScreen({super.key});

  @override
  State<ClientTrackingScreen> createState() =>
      _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final MapController _mapController = MapController();

  Timer? _refreshTimer;

  List<Map<String, dynamic>> _deliveries = [];
  Map<String, dynamic>? _selectedDelivery;
  Map<String, dynamic>? _courierLocation;

  bool _loading = true;
  bool _mapReady = false;
  String? _error;
  DateTime? _lastUpdate;

  static const LatLng _defaultCenter = LatLng(10.4631, -73.2532);

  @override
  void initState() {
    super.initState();
    _loadDeliveries();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshTracking(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  bool _validCoordinates(double? lat, double? lng) {
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  LatLng? _coordinates(
    dynamic latitude,
    dynamic longitude,
  ) {
    final lat = _toDouble(latitude);
    final lng = _toDouble(longitude);

    if (!_validCoordinates(lat, lng)) return null;
    return LatLng(lat!, lng!);
  }

  LatLng get _mapCenter {
    final location = _courierLocation;

    if (location != null) {
      final point = _coordinates(
        location['latitude'],
        location['longitude'],
      );

      if (point != null) return point;
    }

    final delivery = _selectedDelivery;

    if (delivery != null) {
      final origin = _coordinates(
        delivery['origin_latitude'],
        delivery['origin_longitude'],
      );

      if (origin != null) return origin;

      final destination = _coordinates(
        delivery['destination_latitude'],
        delivery['destination_longitude'],
      );

      if (destination != null) return destination;
    }

    return _defaultCenter;
  }

  Future<void> _loadDeliveries() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Inicia sesiÃ³n para consultar tus domicilios.';
      });

      return;
    }

    try {
      final response = await _client
          .from('delivery_requests')
          .select()
          .eq('requester_id', user.id)
          .inFilter('status', [
            'assigned',
            'picked_up',
            'on_the_way',
          ])
          .order('created_at', ascending: false);

      final deliveries = (response as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;

      final oldId = _selectedDelivery?['id']?.toString();
      Map<String, dynamic>? selected;

      for (final delivery in deliveries) {
        if (delivery['id']?.toString() == oldId) {
          selected = delivery;
          break;
        }
      }

      selected ??= deliveries.isNotEmpty ? deliveries.first : null;

      setState(() {
        _deliveries = deliveries;
        _selectedDelivery = selected;
        _loading = false;
        _error = null;
      });

      await _refreshLocation();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar tus domicilios. '
            'Comprueba la conexiÃ³n y los permisos de Supabase.';
      });
    }
  }

  Future<void> _refreshTracking() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('delivery_requests')
          .select()
          .eq('requester_id', user.id)
          .inFilter('status', [
            'assigned',
            'picked_up',
            'on_the_way',
          ])
          .order('created_at', ascending: false);

      final deliveries = (response as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;

      final oldId = _selectedDelivery?['id']?.toString();
      Map<String, dynamic>? selected;

      for (final delivery in deliveries) {
        if (delivery['id']?.toString() == oldId) {
          selected = delivery;
          break;
        }
      }

      selected ??= deliveries.isNotEmpty ? deliveries.first : null;

      setState(() {
        _deliveries = deliveries;
        _selectedDelivery = selected;
        _error = null;
      });

      await _refreshLocation();
    } catch (_) {
      // Conserva los datos visibles si una actualizaciÃ³n falla.
    }
  }

  Future<void> _refreshLocation() async {
    final delivery = _selectedDelivery;
    final courierId = delivery?['courier_id']?.toString();

    if (courierId == null || courierId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _courierLocation = null;
        _lastUpdate = DateTime.now();
      });

      return;
    }

    try {
      final response = await _client
          .from('courier_locations')
          .select('courier_id, latitude, longitude, updated_at')
          .eq('courier_id', courierId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _courierLocation = response == null
            ? null
            : Map<String, dynamic>.from(response);
        _lastUpdate = DateTime.now();
      });

      if (_mapReady) {
        _mapController.move(_mapCenter, 15);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _courierLocation = null;
      });
    }
  }

  void _selectDelivery(Map<String, dynamic> delivery) {
    setState(() {
      _selectedDelivery = delivery;
      _courierLocation = null;
    });

    _refreshLocation();
  }

  List<LatLng> _buildRoutePoints() {
    final points = <LatLng>[];
    final delivery = _selectedDelivery;

    if (delivery == null) return points;

    final origin = _coordinates(
      delivery['origin_latitude'],
      delivery['origin_longitude'],
    );

    final destination = _coordinates(
      delivery['destination_latitude'],
      delivery['destination_longitude'],
    );

    final location = _courierLocation;
    final courier = location == null
        ? null
        : _coordinates(
            location['latitude'],
            location['longitude'],
          );

    if (origin != null) points.add(origin);

    if (courier != null &&
        (points.isEmpty ||
            points.last.latitude != courier.latitude ||
            points.last.longitude != courier.longitude)) {
      points.add(courier);
    }

    if (destination != null &&
        (points.isEmpty ||
            points.last.latitude != destination.latitude ||
            points.last.longitude != destination.longitude)) {
      points.add(destination);
    }

    return points;
  }

  List<Polyline> _buildPolylines() {
    final points = _buildRoutePoints();

    if (points.length < 2) return [];

    return [
      Polyline(
        points: points,
        strokeWidth: 4,
        color: const Color(0xFF2878D0),
      ),
    ];
  }
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    final delivery = _selectedDelivery;

    if (delivery != null) {
      final origin = _coordinates(
        delivery['origin_latitude'],
        delivery['origin_longitude'],
      );

      if (origin != null) {
        markers.add(
          Marker(
            point: origin,
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

      final destination = _coordinates(
        delivery['destination_latitude'],
        delivery['destination_longitude'],
      );

      if (destination != null) {
        markers.add(
          Marker(
            point: destination,
            width: 42,
            height: 48,
            child: const Icon(
              Icons.flag_rounded,
              color: Color(0xFF2582E8),
              size: 36,
            ),
          ),
        );
      }
    }

    final location = _courierLocation;

    if (location != null) {
      final point = _coordinates(
        location['latitude'],
        location['longitude'],
      );

      if (point != null) {
        markers.add(
          Marker(
            point: point,
            width: 50,
            height: 54,
            child: const Icon(
              Icons.delivery_dining,
              color: Color(0xFF21966A),
              size: 42,
            ),
          ),
        );
      }
    }

    return markers;
  }

  String _statusLabel(dynamic value) {
    switch (value?.toString()) {
      case 'assigned':
        return 'Domicilio asignado';
      case 'picked_up':
        return 'Pedido recogido';
      case 'on_the_way':
        return 'En camino';
      default:
        return 'Estado no disponible';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Sin informaciÃ³n';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Sin informaciÃ³n';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _selectedDelivery;
    final location = _courierLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de mi domicilio'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _refreshTracking,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _deliveries.isEmpty
              ? _buildMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'No se pudieron cargar los domicilios',
                  message: _error!,
                  action: FilledButton.icon(
                    onPressed: _loadDeliveries,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                )
              : _deliveries.isEmpty
                  ? _buildMessage(
                      icon: Icons.local_shipping_outlined,
                      title: 'No tienes domicilios activos',
                      message: 'Cuando Central asigne un domiciliario, '
                          'podrÃ¡s seguir su ubicaciÃ³n aquÃ­.',
                      action: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_deliveries.length > 1)
                          SizedBox(
                            height: 112,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              scrollDirection: Axis.horizontal,
                              itemCount: _deliveries.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final item = _deliveries[index];
                                final selected =
                                    item['id'] == delivery?['id'];
                                final id = item['id'].toString();
                                final shortId = id.length > 8
                                    ? id.substring(0, 8)
                                    : id;

                                return SizedBox(
                                  width: 220,
                                  child: Card(
                                    color: selected
                                        ? const Color(0xFFE4F1FF)
                                        : null,
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      onTap: () => _selectDelivery(item),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Domicilio #$shortId',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _statusLabel(item['status']),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        Expanded(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _mapCenter,
                              initialZoom: 13,
                              minZoom: 4,
                              maxZoom: 18,
                              onMapReady: () {
                                _mapReady = true;
                                _mapController.move(_mapCenter, 13);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.queuego.app',
                              ),
                              PolylineLayer(polylines: _buildPolylines()),
                              MarkerLayer(markers: _buildMarkers()),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Color(0xFFE7ECF3)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_shipping,
                                    color: Color(0xFF2878D0),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _statusLabel(delivery?['status']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Origen: ${delivery?['origin_address'] ?? 'No registrado'}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Destino: ${delivery?['destination_address'] ?? 'No registrado'}',
                              ),
                              const SizedBox(height: 10),
                              if (location == null)
                                const Text(
                                  'AÃºn no hay una ubicaciÃ³n GPS disponible '
                                  'para este domiciliario.',
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                  ),
                                )
                              else
                                Text(
                                  'Ãšltima ubicaciÃ³n GPS: '
                                  '${_formatDate(location['updated_at'])}',
                                ),
                              if (_lastUpdate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Consulta actualizada: '
                                  '${_formatDate(_lastUpdate!.toIso8601String())}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    required Widget action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            action,
          ],
        ),
      ),
    );
  }
}

