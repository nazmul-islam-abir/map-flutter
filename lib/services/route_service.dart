import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../models/route_model.dart';
import 'local_transport_service.dart';

class RouteService {
  static const String orsApiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImNlMjJiNDJlM2RmZjQ1NGRiNjM0YzI3MzA1MzIyMWM5IiwiaCI6Im11cm11cjY0In0="; // Replace with your key

  final LocalTransportService _localTransport = LocalTransportService();

  Future<RouteInfo?> getRoute(Place start, Place end) async {
    try {
      // Try to get real route from API
      final route = await _getRouteFromAPI(start, end);
      if (route != null) return route;
    } catch (e) {
      print('API failed: $e');
    }

    // Fallback to straight line with local transport info
    return _getFallbackRoute(start, end);
  }

  Future<RouteInfo?> _getRouteFromAPI(Place start, Place end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': orsApiKey},
      body: json.encode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ],
      }),
    );

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);

    // Parse route coordinates
    final coordinates = data['features'][0]['geometry']['coordinates'] as List;
    List<LatLng> points = [];

    for (var coord in coordinates) {
      points.add(LatLng(coord[1], coord[0]));
    }

    // Get route summary
    final summary = data['features'][0]['properties']['summary'];
    final distance = summary['distance'] / 1000;
    final duration = (summary['duration'] / 60).toInt();

    // Get transport options for this route
    final transportOptions = _localTransport.getTransportOptions(start, end);

    return RouteInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      start: start,
      end: end,
      distance: distance,
      duration: duration,
      points: points,
      transportOptions: transportOptions,
      createdAt: DateTime.now(),
    );
  }

  RouteInfo _getFallbackRoute(Place start, Place end) {
    // Calculate straight line distance
    final distance = _calculateDistance(start, end);
    final duration = (distance * 12)
        .toInt(); // Rough estimate: 12 minutes per km in city

    // Get transport options
    final transportOptions = _localTransport.getTransportOptions(start, end);

    return RouteInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      start: start,
      end: end,
      distance: distance,
      duration: duration,
      points: [
        LatLng(start.latitude, start.longitude),
        LatLng(end.latitude, end.longitude),
      ],
      transportOptions: transportOptions,
      createdAt: DateTime.now(),
    );
  }

  double _calculateDistance(Place start, Place end) {
    const double R = 6371;
    final dLat = _degToRad(end.latitude - start.latitude);
    final dLon = _degToRad(end.longitude - start.longitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(start.latitude)) *
            math.cos(_degToRad(end.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);
}
