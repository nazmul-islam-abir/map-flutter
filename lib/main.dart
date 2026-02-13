import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  
  // 🔴 REPLACE THIS WITH YOUR ACTUAL MAPTILER API KEY
  static const String mapTilerKey = "ED7184GhWjoFh4jIu1hx";

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
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
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = pos;
        _loading = false;
        _status = "Location found";
      });

      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        16,
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
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      setState(() => _position = pos);
      
      if (_isFollowing) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          16,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📍 Live Location Tracker"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
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
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 
                              "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerKey",
                          userAgentPackageName: "com.example.myapp",
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
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 40,
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

                    // Live indicator
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
                            const Text('Live', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),

                    // Bottom info card
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
                              const Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Your Location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                                      color: Colors.orange,
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
                    _mapController.camera.zoom + 1,
                  ),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoomOut',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center',
                  onPressed: () {
                    _mapController.move(
                      LatLng(_position!.latitude, _position!.longitude),
                      16,
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
}