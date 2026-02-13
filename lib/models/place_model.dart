import 'package:flutter/material.dart';

class Place {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeType; // 'current', 'home', 'work', 'favorite'
  final bool isSaved;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeType,
    this.isSaved = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      placeType: json['placeType'],
      isSaved: json['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeType': placeType,
      'isSaved': isSaved,
    };
  }
}