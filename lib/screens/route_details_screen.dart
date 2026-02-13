import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../models/route_model.dart';

class RouteDetailsScreen extends StatefulWidget {
  final RouteInfo route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final MapController _mapController = MapController();
  int _selectedTransportIndex = 0;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Wait for the widget to be built before using MapController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMap();
    });
  }

  void _centerMap() {
    if (!mounted) return;
    
    try {
      if (widget.route.points.isNotEmpty) {
        // Calculate center point of the route
        final centerIndex = widget.route.points.length ~/ 2;
        final center = widget.route.points[centerIndex];
        
        // Move map to center
        _mapController.move(
          latlong.LatLng(center.latitude, center.longitude),
          13,
        );
        
        setState(() {
          _isMapReady = true;
        });
        
        print('Map centered at: ${center.latitude}, ${center.longitude}');
      } else {
        // Fallback to Chittagong center if no route points
        _mapController.move(
          const latlong.LatLng(22.3569, 91.7832),
          12,
        );
        setState(() {
          _isMapReady = true;
        });
      }
    } catch (e) {
      print('Error centering map: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Route Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // Save route
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Route saved!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Route summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.route.start.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
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
                          Expanded(
                            child: Text(
                              widget.route.end.name,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.route.distanceText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        widget.route.durationText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Map
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const latlong.LatLng(22.3569, 91.7832), // Chittagong center as fallback
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=ED7184GhWjoFh4jIu1hx',
                      userAgentPackageName: 'com.example.myapp',
                    ),
                    
                    // Route line
                    if (widget.route.points.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: widget.route.points
                                .map((p) => latlong.LatLng(p.latitude, p.longitude))
                                .toList(),
                            color: Colors.blue,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    
                    // Start and End markers
                    MarkerLayer(
                      markers: [
                        // Start marker
                        Marker(
                          point: latlong.LatLng(
                            widget.route.start.latitude,
                            widget.route.start.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.flag, color: Colors.white, size: 20),
                          ),
                        ),
                        
                        // End marker
                        Marker(
                          point: latlong.LatLng(
                            widget.route.end.latitude,
                            widget.route.end.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.place, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Center button overlay
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    onPressed: _centerMap,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.center_focus_strong, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          
          // Transport options
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transport Options',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.route.transportOptions.length,
                      itemBuilder: (context, index) {
                        final option = widget.route.transportOptions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _selectedTransportIndex == index 
                                  ? Colors.blue 
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                _selectedTransportIndex = index;
                              });
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getTransportColor(option.type).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                option.icon,
                                color: _getTransportColor(option.type),
                              ),
                            ),
                            title: Text(
                              option.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: option.routeNumber != null 
                                ? Text('Route: ${option.routeNumber}')
                                : null,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    option.fare,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      option.duration,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Route'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showNavigationOptions(context);
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNavigationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Navigation Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.blue),
                title: const Text('Drive'),
                subtitle: const Text('Follow driving route'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Starting driving navigation...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.orange),
                title: const Text('Public Transport'),
                subtitle: const Text('Use bus, CNG, or rickshaw'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing public transport options...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_walk, color: Colors.green),
                title: const Text('Walk'),
                subtitle: const Text('Pedestrian route'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Starting walking navigation...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getTransportColor(String type) {
    switch (type) {
      case 'bus':
        return Colors.orange;
      case 'cng':
        return Colors.green;
      case 'rickshaw':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}