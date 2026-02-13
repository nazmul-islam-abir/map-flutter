import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/place_model.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import 'route_details_screen.dart';

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  
  Place? _startPlace;
  Place? _endPlace;
  
  bool _isLoading = false;
  bool _swapButtonEnabled = false;

  // Popular places in Chittagong
  final List<Place> _popularPlaces = [
    Place(
      id: '1',
      name: 'Chunafactory',
      address: 'Chunafactory, Chittagong',
      latitude: 22.3569,
      longitude: 91.7832,
    ),
    Place(
      id: '2',
      name: 'New Market',
      address: 'New Market, Chittagong',
      latitude: 22.3355,
      longitude: 91.8327,
    ),
    Place(
      id: '3',
      name: 'GEC Circle',
      address: 'GEC, Chittagong',
      latitude: 22.3605,
      longitude: 91.8258,
    ),
    Place(
      id: '4',
      name: 'Agrabad',
      address: 'Agrabad, Chittagong',
      latitude: 22.3242,
      longitude: 91.8044,
    ),
    Place(
      id: '5',
      name: 'Chittagong Airport',
      address: 'Shah Amanat International Airport',
      latitude: 22.2517,
      longitude: 91.8145,
    ),
    Place(
      id: '6',
      name: 'Patenga Beach',
      address: 'Patenga, Chittagong',
      latitude: 22.2338,
      longitude: 91.7949,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _addCurrentLocation();
  }

  Future<void> _addCurrentLocation() async {
    final locationService = LocationService();
    final hasPermission = await locationService.checkAndRequestPermissions();
    
    if (hasPermission) {
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        final currentPlace = Place(
          id: 'current',
          name: 'Current Location',
          address: 'Your current location',
          latitude: position.latitude,
          longitude: position.longitude,
          placeType: 'current',
        );
        
        setState(() {
          _popularPlaces.insert(0, currentPlace);
        });
      }
    }
  }

  Future<List<Place>> _searchPlaces(String pattern) async {
    if (pattern.isEmpty) return [];
    
    // Filter popular places
    return _popularPlaces.where((place) =>
      place.name.toLowerCase().contains(pattern.toLowerCase()) ||
      place.address.toLowerCase().contains(pattern.toLowerCase())
    ).toList();
  }

  void _swapLocations() {
    if (_startController.text.isNotEmpty && _endController.text.isNotEmpty) {
      final tempText = _startController.text;
      final tempPlace = _startPlace;
      
      setState(() {
        _startController.text = _endController.text;
        _endController.text = tempText;
        _startPlace = _endPlace;
        _endPlace = tempPlace;
      });
    }
  }

  Future<void> _findRoute() async {
    if (_startPlace == null) {
      _showError('Please select a starting point');
      return;
    }
    
    if (_endPlace == null) {
      _showError('Please select a destination');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final routeService = RouteService();
      final route = await routeService.getRoute(_startPlace!, _endPlace!);
      
      if (route != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailsScreen(route: route),
          ),
        );
      } else {
        _showError('Could not find a route');
      }
    } catch (e) {
      _showError('Error finding route: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Route',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Start location field
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TypeAheadField<Place>(
                              controller: _startController,
                              builder: (context, controller, focusNode) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter start location',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    if (value.isEmpty) setState(() => _startPlace = null);
                                  },
                                );
                              },
                              suggestionsCallback: (pattern) => _searchPlaces(pattern),
                              itemBuilder: (context, place) {
                                return ListTile(
                                  leading: Icon(
                                    place.placeType == 'current' 
                                        ? Icons.my_location 
                                        : Icons.place,
                                    color: place.placeType == 'current' ? Colors.blue : Colors.grey,
                                  ),
                                  title: Text(place.name),
                                  subtitle: Text(place.address),
                                );
                              },
                              onSelected: (place) {
                                setState(() {
                                  _startController.text = place.name;
                                  _startPlace = place;
                                  _swapButtonEnabled = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 30),
                      
                      // End location field
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.place, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TypeAheadField<Place>(
                              controller: _endController,
                              builder: (context, controller, focusNode) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter destination',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    if (value.isEmpty) setState(() => _endPlace = null);
                                  },
                                );
                              },
                              suggestionsCallback: (pattern) => _searchPlaces(pattern),
                              itemBuilder: (context, place) {
                                return ListTile(
                                  leading: Icon(Icons.place, color: Colors.red),
                                  title: Text(place.name),
                                  subtitle: Text(place.address),
                                );
                              },
                              onSelected: (place) {
                                setState(() {
                                  _endController.text = place.name;
                                  _endPlace = place;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Swap button
                      if (_swapButtonEnabled)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _swapLocations,
                            icon: const Icon(Icons.swap_vert),
                            label: const Text('Swap locations'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Popular destinations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Destinations',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _popularPlaces.length,
                        itemBuilder: (context, index) {
                          final place = _popularPlaces[index];
                          if (place.placeType == 'current') return const SizedBox();
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (_startController.text.isEmpty) {
                                  _startController.text = place.name;
                                  _startPlace = place;
                                } else if (_endController.text.isEmpty) {
                                  _endController.text = place.name;
                                  _endPlace = place;
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.place, color: Colors.blue.shade300),
                                  const SizedBox(height: 4),
                                  Text(
                                    place.name,
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
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
              
              // Find route button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _findRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Find Route',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}