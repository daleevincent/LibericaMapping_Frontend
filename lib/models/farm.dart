// lib/models/farm.dart

import 'package:latlong2/latlong.dart';

class Farm {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final double fieldSize; // in hectares
  final int libericaTrees;
  final int dnaVerifiedTrees;
  final List<LatLng> polygonCoordinates;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.fieldSize,
    required this.libericaTrees,
    required this.dnaVerifiedTrees,
    required this.polygonCoordinates,
  });

  double get dnaVerificationRate =>
      libericaTrees > 0 ? (dnaVerifiedTrees / libericaTrees) * 100 : 0;

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      fieldSize: json['fieldSize'].toDouble(),
      libericaTrees: json['libericaTrees'],
      dnaVerifiedTrees: json['dnaVerifiedTrees'],
      polygonCoordinates: (json['polygonCoordinates'] as List)
          .map((p) => LatLng(p['lat'].toDouble(), p['lng'].toDouble()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'fieldSize': fieldSize,
        'libericaTrees': libericaTrees,
        'dnaVerifiedTrees': dnaVerifiedTrees,
        'polygonCoordinates': polygonCoordinates
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

  Farm copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    double? fieldSize,
    int? libericaTrees,
    int? dnaVerifiedTrees,
    List<LatLng>? polygonCoordinates,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fieldSize: fieldSize ?? this.fieldSize,
      libericaTrees: libericaTrees ?? this.libericaTrees,
      dnaVerifiedTrees: dnaVerifiedTrees ?? this.dnaVerifiedTrees,
      polygonCoordinates: polygonCoordinates ?? this.polygonCoordinates,
    );
  }
}
