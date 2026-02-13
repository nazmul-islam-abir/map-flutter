import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/place_model.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  Stream<Position>? _positionStream;

  Future<bool> checkAndRequestPermissions() async {
    // Check if location services are enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      return _currentPosition;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  void startLocationUpdates(Function(Position) onUpdate) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    );

    _positionStream?.listen((Position position) {
      _currentPosition = position;
      onUpdate(position);
    });
  }

  void stopLocationUpdates() {
    _positionStream = null;
  }

  Place? getCurrentPlace() {
    if (_currentPosition == null) return null;
    
    return Place(
      id: 'current',
      name: 'Current Location',
      address: 'Your current location',
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      placeType: 'current',
    );
  }
}