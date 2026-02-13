import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math; // Add this with other imports

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chittagong Route Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();
  Position? _position;
  String _status = "Checking location...";
  bool _loading = true;
  bool _isFollowing = true;
  int _mapStyleIndex = 0;
  
  // Route related variables
  List<LatLng> _routePoints = [];
  bool _isRouteMode = false;
  bool _isLoadingRoute = false;
  String _routeInfo = "";
  String _transportInfo = "";
  
  // Source and destination for demo (Chittagong coordinates - approximate)
  final LatLng _chunaFactory = const LatLng(22.3569, 91.7832); // Chunafactory area
  final LatLng _newMarket = const LatLng(22.3355, 91.8327); // New Market area
  
  // Stream subscription for location updates
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // 🔴 REPLACE WITH YOUR MAPTILER API KEY
  static const String mapTilerKey = "ED7184GhWjoFh4jIu1hx";
  
  // OpenRouteService API key (free, sign up at openrouteservice.org)
  static const String orsApiKey = "5b3ce3597851110001cf6248f0d1b5c2c0e34e24a7b3e2f9c9d8b7a6c"; // Demo key - replace with yours
  
  // Different map styles
  final List<Map<String, dynamic>> mapStyles = [
    {
      'name': 'Streets',
      'url': 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=',
      'icon': Icons.map,
    },
    {
      'name': 'Satellite',
      'url': 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=',
      'icon': Icons.satellite,
    },
  ];

  // Chittagong local transport database
  final Map<String, List<Map<String, dynamic>>> localRoutes = {
    'chunafactory_newmarket': [
      {'vehicle': 'CNG (3 No. Tempo)', 'fare': '30-40 tk', 'time': '20-25 mins', 'icon': Icons.electric_rickshaw},
      {'vehicle': 'Mini Bus', 'fare': '15 tk', 'time': '30-35 mins', 'icon': Icons.directions_bus},
      {'vehicle': 'Rickshaw', 'fare': '50-60 tk', 'time': '25-30 mins', 'icon': Icons.pedal_bike},
    ],
  };

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionAndGetLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() {
        _status = "Please turn ON GPS";
        _loading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _status = "Location permission permanently denied";
        _loading = false;
      });
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _position = pos;
        _loading = false;
        _status = "Location found";
      });

      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        14,
      );

      _listenToLocationUpdates();
    } catch (e) {
      setState(() {
        _status = "Error: $e";
        _loading = false;
      });
    }
  }

  void _listenToLocationUpdates() {
    _positionStreamSubscription?.cancel();
    
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      setState(() {
        _position = pos;
      });
      
      if (_isFollowing && !_isRouteMode) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom,
        );
      }
    });
  }

  // Get route from OpenRouteService
  Future<void> _getRoute(LatLng start, LatLng end) async {
    setState(() {
      _isLoadingRoute = true;
      _routeInfo = "Finding route...";
    });

    try {
      // OpenRouteService API endpoint
      final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImNlMjJiNDJlM2RmZjQ1NGRiNjM0YzI3MzA1MzIyMWM5IiwiaCI6Im11cm11cjY0In0=",
        },
        body: json.encode({
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse route coordinates
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        List<LatLng> points = [];
        
        for (var coord in coordinates) {
          points.add(LatLng(coord[1], coord[0])); // GeoJSON is [lng, lat]
        }
        
        // Get route summary
        final summary = data['features'][0]['properties']['summary'];
        final distance = (summary['distance'] / 1000).toStringAsFixed(1); // km
        final duration = (summary['duration'] / 60).toInt(); // minutes
        
        setState(() {
          _routePoints = points;
          _isRouteMode = true;
          _isLoadingRoute = false;
          _routeInfo = "📍 Chunafactory → New Market\n📏 $distance km | 🕒 $duration mins";
          _transportInfo = _getLocalTransportInfo();
        });
        
        // Zoom to show route
        _zoomToRouteBounds(start, end);
        
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
        _routeInfo = "Using local route info";
      });
      
      // Fallback: Show straight line
      setState(() {
        _routePoints = [start, end];
        _isRouteMode = true;
        _transportInfo = _getLocalTransportInfo();
      });
      
      _zoomToRouteBounds(start, end);
    }
  }

  // Zoom to show the entire route
  void _zoomToRouteBounds(LatLng start, LatLng end) {
    // Calculate center point
    final centerLat = (start.latitude + end.latitude) / 2;
    final centerLng = (start.longitude + end.longitude) / 2;
    
    // Calculate distance to determine zoom level
    final distance = _calculateDistance(start, end);
    
    // Set zoom based on distance
    double zoom = 12; // Default
    if (distance < 2) zoom = 14;
    else if (distance < 5) zoom = 13;
    else if (distance < 10) zoom = 12;
    else zoom = 11;
    
    _mapController.move(
      LatLng(centerLat, centerLng),
      zoom,
    );
  }

  // Calculate distance between two points (km)
  // Calculate distance between two points (km) - FIXED
    double _calculateDistance(LatLng start, LatLng end) {
      const double R = 6371; // Earth's radius in km
      final dLat = _degToRad(end.latitude - start.latitude);
      final dLon = _degToRad(end.longitude - start.longitude);
      
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                math.cos(_degToRad(start.latitude)) * 
                math.cos(_degToRad(end.latitude)) * 
                math.sin(dLon / 2) * math.sin(dLon / 2);
                
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return R * c;
    }

  double _degToRad(double deg) => deg * (3.14159 / 180);

  // Get local transport information
  String _getLocalTransportInfo() {
    final routes = localRoutes['chunafactory_newmarket'];
    if (routes == null) return "Local transport info not available";
    
    String info = "";
    for (var route in routes) {
      info += "• ${route['vehicle']}: ${route['fare']} (${route['time']})\n";
    }
    return info;
  }

  // Clear route
  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _isRouteMode = false;
      _routeInfo = "";
      _transportInfo = "";
    });
    
    if (_position != null) {
      _mapController.move(
        LatLng(_position!.latitude, _position!.longitude),
        14,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📍 Chittagong Route Finder"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Map style selector
          if (_position != null)
            PopupMenuButton<int>(
              icon: const Icon(Icons.layers),
              onSelected: (index) {
                setState(() {
                  _mapStyleIndex = index;
                });
              },
              itemBuilder: (context) => [
                for (int i = 0; i < mapStyles.length; i++)
                  PopupMenuItem(
                    value: i,
                    child: Row(
                      children: [
                        Icon(mapStyles[i]['icon'] as IconData, size: 20),
                        const SizedBox(width: 8),
                        Text(mapStyles[i]['name'] as String),
                        if (i == _mapStyleIndex)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 16, color: Colors.blue),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          // Route button
          if (_position != null)
            IconButton(
              icon: Icon(_isRouteMode ? Icons.close : Icons.route),
              onPressed: _isRouteMode 
                  ? _clearRoute 
                  : () => _getRoute(_chunaFactory, _newMarket),
              tooltip: _isRouteMode ? 'Clear route' : 'Show Chunafactory → New Market',
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_status),
                ],
              ),
            )
          : _position == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(_status, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _checkPermissionAndGetLocation,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        initialZoom: 14,
                        maxZoom: 20,
                        minZoom: 3,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: (mapStyles[_mapStyleIndex]['url'] as String) + mapTilerKey,
                          userAgentPackageName: "com.example.myapp",
                        ),

                        // Route line
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.blue,
                                strokeWidth: 6,
                              ),
                            ],
                          ),

                        // Markers
                        MarkerLayer(
                          markers: [
                            // Current location
                            Marker(
                              width: 60,
                              height: 60,
                              point: LatLng(
                                _position!.latitude,
                                _position!.longitude,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ),
                            
                            // Chunafactory marker
                            if (_isRouteMode)
                              Marker(
                                width: 50,
                                height: 50,
                                point: _chunaFactory,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.factory, color: Colors.white, size: 20),
                                      Text('Start', style: TextStyle(color: Colors.white, fontSize: 8)),
                                    ],
                                  ),
                                ),
                              ),
                            
                            // New Market marker
                            if (_isRouteMode)
                              Marker(
                                width: 50,
                                height: 50,
                                point: _newMarket,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.store, color: Colors.white, size: 20),
                                      Text('End', style: TextStyle(color: Colors.white, fontSize: 8)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Accuracy circle
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(
                                _position!.latitude,
                                _position!.longitude,
                              ),
                              radius: _position!.accuracy,
                              color: Colors.blue.withOpacity(0.1),
                              borderColor: Colors.blue.withOpacity(0.3),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Loading indicator
                    if (_isLoadingRoute)
                      const Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Finding best route...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Route info card
                    if (_isRouteMode && !_isLoadingRoute)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade50, Colors.white],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.route, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Route Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: _clearRoute,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Text(
                                  _routeInfo,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '🚖 Local Transport:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(_transportInfo),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info, color: Colors.green, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '👉 Can go using 3 No. Tempo (CNG)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Live indicator
                    Positioned(
                      bottom: 100,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live • ${_formatTime(DateTime.now())}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom info card
                    if (!_isRouteMode)
                      Positioned(
                        bottom: 20,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.blue.shade50],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Your Location',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _position!.accuracy < 10 ? Colors.green : Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _position!.accuracy < 10 ? 'High' : 'Medium',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lat: ${_position!.latitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Lng: ${_position!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _position == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoomIn',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    (_mapController.camera.zoom + 1).clamp(3, 20),
                  ),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoomOut',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    (_mapController.camera.zoom - 1).clamp(3, 20),
                  ),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center',
                  onPressed: () {
                    if (_isRouteMode && _routePoints.isNotEmpty) {
                      // Center on route
                      final start = _routePoints.first;
                      final end = _routePoints.last;
                      _zoomToRouteBounds(start, end);
                    } else {
                      // Center on current location
                      _mapController.move(
                        LatLng(_position!.latitude, _position!.longitude),
                        14,
                      );
                    }
                  },
                  child: Icon(_isRouteMode ? Icons.center_focus_strong : Icons.my_location),
                ),
              ],
            ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}