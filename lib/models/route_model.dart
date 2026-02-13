import 'package:flutter/material.dart';
import 'place_model.dart';

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

class TransportOption {
  final String type; // 'bus', 'cng', 'rickshaw', 'walk', 'car'
  final String name;
  final String fare;
  final String duration;
  final String? routeNumber;
  final IconData icon;

  TransportOption({
    required this.type,
    required this.name,
    required this.fare,
    required this.duration,
    this.routeNumber,
    required this.icon,
  });
}

class RouteInfo {
  final String id;
  final Place start;
  final Place end;
  final double distance; // in km
  final int duration; // in minutes
  final List<LatLng> points;
  final List<TransportOption> transportOptions;
  final DateTime createdAt;
  final bool isSaved;

  RouteInfo({
    required this.id,
    required this.start,
    required this.end,
    required this.distance,
    required this.duration,
    required this.points,
    required this.transportOptions,
    required this.createdAt,
    this.isSaved = false,
  });

  String get durationText {
    if (duration < 60) return '$duration min';
    final hours = duration ~/ 60;
    final mins = duration % 60;
    return '${hours}h ${mins}m';
  }

  String get distanceText => '${distance.toStringAsFixed(1)} km';
}