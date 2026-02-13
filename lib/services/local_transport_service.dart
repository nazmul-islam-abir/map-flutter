import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../models/route_model.dart';
import 'dart:math' as math;

class LocalTransportService {
  // Database of known places and routes in Chittagong
  final Map<String, Map<String, List<TransportOption>>> _routeDatabase = {
    'chunafactory': {
      'newmarket': [
        TransportOption(
          type: 'cng',
          name: 'CNG (3 No. Tempo)',
          fare: '30-40 tk',
          duration: '20-25 mins',
          routeNumber: '3',
          icon: Icons.electric_rickshaw,
        ),
        TransportOption(
          type: 'bus',
          name: 'Mini Bus',
          fare: '15 tk',
          duration: '30-35 mins',
          routeNumber: 'Mini',
          icon: Icons.directions_bus,
        ),
        TransportOption(
          type: 'rickshaw',
          name: 'Rickshaw',
          fare: '50-60 tk',
          duration: '25-30 mins',
          icon: Icons.pedal_bike,
        ),
      ],
    },
    'newmarket': {
      'chunafactory': [
        TransportOption(
          type: 'cng',
          name: 'CNG (3 No. Tempo)',
          fare: '30-40 tk',
          duration: '20-25 mins',
          routeNumber: '3',
          icon: Icons.electric_rickshaw,
        ),
      ],
    },
  };

  // General transport options for unknown routes
  final List<TransportOption> _generalOptions = [
    TransportOption(
      type: 'cng',
      name: 'CNG (Tempo)',
      fare: '30-50 tk',
      duration: '15-30 mins',
      icon: Icons.electric_rickshaw,
    ),
    TransportOption(
      type: 'bus',
      name: 'Local Bus',
      fare: '10-20 tk',
      duration: '20-40 mins',
      icon: Icons.directions_bus,
    ),
    TransportOption(
      type: 'rickshaw',
      name: 'Rickshaw',
      fare: '40-80 tk',
      duration: '15-35 mins',
      icon: Icons.pedal_bike,
    ),
  ];

  List<TransportOption> getTransportOptions(Place start, Place end) {
    // Try to find in database
    final startKey = _normalizePlaceName(start.name);
    final endKey = _normalizePlaceName(end.name);
    
    if (_routeDatabase.containsKey(startKey) && 
        _routeDatabase[startKey]!.containsKey(endKey)) {
      return _routeDatabase[startKey]![endKey]!;
    }
    
    // Return general options with estimated fares
    final distance = _estimateDistance(start, end);
    return _generalOptions.map((option) {
      final fare = _estimateFare(option.type, distance);
      return TransportOption(
        type: option.type,
        name: option.name,
        fare: fare,
        duration: '${(distance * 3).toInt()}-${(distance * 5).toInt()} mins',
        icon: option.icon,
      );
    }).toList();
  }

  String _normalizePlaceName(String name) {
    return name.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
  }

  double _estimateDistance(Place start, Place end) {
    const double R = 6371;
    final dLat = _degToRad(end.latitude - start.latitude);
    final dLon = _degToRad(end.longitude - start.longitude);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(_degToRad(start.latitude)) * 
              math.cos(_degToRad(end.latitude)) * 
              math.sin(dLon / 2) * math.sin(dLon / 2);
              
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  String _estimateFare(String type, double distance) {
    switch (type) {
      case 'cng':
        return '${(distance * 8).toInt()}-${(distance * 12).toInt()} tk';
      case 'bus':
        return '${(distance * 3).toInt()}-${(distance * 5).toInt()} tk';
      case 'rickshaw':
        return '${(distance * 12).toInt()}-${(distance * 18).toInt()} tk';
      default:
        return '30-50 tk';
    }
  }
}