import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracker Pro',
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
  int _mapStyleIndex = 0; // 0: Streets, 1: Satellite, 2: Outdoor, 3: Hybrid
  
  // Stream subscription for location updates
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // 🔴 REPLACE THIS WITH YOUR ACTUAL MAPTILER API KEY
  static const String mapTilerKey = "ED7184GhWjoFh4jIu1hx";
  
  // Different map styles from Maptiler - FIXED: Separated icon from map data
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
    {
      'name': 'Outdoor',
      'url': 'https://api.maptiler.com/maps/outdoor/{z}/{x}/{y}.png?key=',
      'icon': Icons.terrain,
    },
    {
      'name': 'Hybrid',
      'url': 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=',
      'icon': Icons.layers,
    },
  ];

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
      // Force a fresh location with timeout
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
        17, // Increased zoom for better detail
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
    // Cancel any existing subscription
    _positionStreamSubscription?.cancel();
    
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best, // Changed to best for more frequent updates
      distanceFilter: 5, // Reduced to 5 meters for smoother updates
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      print("Location updated: ${pos.latitude}, ${pos.longitude}"); // For debugging
      
      setState(() {
        _position = pos;
      });
      
      if (_isFollowing) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom, // Keep current zoom level
        );
      }
    });
  }

  // Force location refresh
  Future<void> _refreshLocation() async {
    setState(() {
      _loading = true;
      _status = "Refreshing location...";
    });
    
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _position = pos;
        _loading = false;
      });
      
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        _mapController.camera.zoom,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location refreshed!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📍 Live Location Tracker"),
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
          if (_position != null)
            IconButton(
              icon: Icon(_isFollowing ? Icons.follow_the_signs : Icons.pan_tool),
              onPressed: () {
                setState(() => _isFollowing = !_isFollowing);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isFollowing ? 'Auto-follow ON' : 'Auto-follow OFF'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
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
                    // Map with selected style
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        initialZoom: 17, // Higher zoom for better detail
                        maxZoom: 20,
                        minZoom: 3,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: (mapStyles[_mapStyleIndex]['url'] as String) + mapTilerKey,
                          userAgentPackageName: "com.example.myapp",
                          tileProvider: NetworkTileProvider(), // Ensures fresh tiles
                        ),

                        MarkerLayer(
                          markers: [
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
                                  Icons.navigation, // Changed to navigation icon for better visibility
                                  color: Colors.blue,
                                  size: 40,
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

                    // Live indicator with timestamp
                    Positioned(
                      top: 16,
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

                    // Refresh button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                          onPressed: _refreshLocation,
                        ),
                      ),
                    ),

                    // Map style indicator
                    Positioned(
                      top: 70,
                      right: 16,
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
                            Icon(mapStyles[_mapStyleIndex]['icon'] as IconData, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              mapStyles[_mapStyleIndex]['name'] as String,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom info card with better info
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
                                      _position!.accuracy < 10 ? 'High accuracy' : 'Medium accuracy',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.north,
                                      'Latitude',
                                      _position!.latitude.toStringAsFixed(6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.east,
                                      'Longitude',
                                      _position!.longitude.toStringAsFixed(6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.radar,
                                      'Accuracy',
                                      '${_position!.accuracy.toStringAsFixed(1)} m',
                                      color: _position!.accuracy < 10 ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.speed,
                                      'Speed',
                                      _position!.speed > 0 
                                          ? '${(_position!.speed * 3.6).toStringAsFixed(1)} km/h' 
                                          : '0 km/h',
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              if (_position!.timestamp != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Updated: ${_formatTime(_position!.timestamp!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                    _mapController.move(
                      LatLng(_position!.latitude, _position!.longitude),
                      17,
                    );
                    setState(() => _isFollowing = true);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, {Color color = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}