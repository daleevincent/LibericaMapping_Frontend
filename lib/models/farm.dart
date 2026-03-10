// lib/models/farm.dart
//
// Mapped directly to the MongoDB farm document schema:
// {
//   "_id":           { "$oid": "..." },
//   "id":            int,
//   "owner_id":      int,
//   "name":          string,
//   "cityId":        int,
//   "cityName":      string,
//   "barangayName":  string,
//   "coordinates":   { "lat": double, "lng": double },
//   "totalTrees":    int,
//   "dnaVerifiedCount": int,
//   "hasDnaVerified": bool,
//   "boundary":      [[lat, lng], ...]
// }

import 'package:latlong2/latlong.dart';

class Farm {
  final String mongoId;       // _id.$oid
  final int id;               // numeric farm id
  final int ownerId;          // owner_id
  final String name;
  final int cityId;
  final String cityName;
  final String barangayName;
  final double latitude;      // coordinates.lat
  final double longitude;     // coordinates.lng
  final int totalTrees;       // totalTrees
  final int dnaVerifiedCount; // dnaVerifiedCount
  final bool hasDnaVerified;  // hasDnaVerified
  final List<LatLng> boundary; // boundary [[lat,lng],...]

  Farm({
    required this.mongoId,
    required this.id,
    required this.ownerId,
    required this.name,
    required this.cityId,
    required this.cityName,
    required this.barangayName,
    required this.latitude,
    required this.longitude,
    required this.totalTrees,
    required this.dnaVerifiedCount,
    required this.hasDnaVerified,
    required this.boundary,
  });

  // ── Convenience getters ──────────────────────────────────────────────────

  /// Full location label used across the UI
  String get location => '$barangayName, $cityName';

  /// Alias kept for backward compatibility with widgets
  int get libericaTrees => totalTrees;
  int get dnaVerifiedTrees => dnaVerifiedCount;

  double get dnaVerificationRate =>
      totalTrees > 0 ? (dnaVerifiedCount / totalTrees) * 100 : 0;

  // ── Deserialise from MongoDB JSON response ───────────────────────────────
  factory Farm.fromJson(Map<String, dynamic> json) {
    // ── _id — handle both { "$oid": "..." } and plain string ────────────────
    final rawId = json['_id'];
    final mongoId = rawId is Map
        ? (rawId['\$oid'] ?? rawId['oid'] ?? '') as String
        : (rawId ?? '') as String;

    // ── coordinates ──────────────────────────────────────────────────────────
    final coords = (json['coordinates'] as Map<String, dynamic>?) ?? {};
    final lat = (coords['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (coords['lng'] as num?)?.toDouble() ?? 0.0;

    // ── boundary — safely parse [[lat,lng],...], default to empty list ───────
    final rawBoundary = json['boundary'];
    final boundaryPoints = <LatLng>[];
    if (rawBoundary is List) {
      for (final point in rawBoundary) {
        if (point is List && point.length >= 2) {
          boundaryPoints.add(LatLng(
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          ));
        }
      }
    }

    return Farm(
      mongoId:          mongoId,
      id:               (json['id'] as num?)?.toInt() ?? mongoId.hashCode.abs(),
      ownerId:          (json['owner_id'] as num?)?.toInt() ?? 0,
      name:             (json['name'] as String?) ?? 'Unnamed Farm',
      cityId:           (json['cityId'] as num?)?.toInt() ?? 0,
      cityName:         (json['cityName'] as String?) ?? '',
      barangayName:     (json['barangayName'] as String?) ?? '',
      latitude:         lat,
      longitude:        lng,
      totalTrees:       (json['totalTrees'] as num?)?.toInt() ?? 0,
      dnaVerifiedCount: (json['dnaVerifiedCount'] as num?)?.toInt() ?? 0,
      hasDnaVerified:   (json['hasDnaVerified'] as bool?) ?? false,
      boundary:         boundaryPoints,
    );
  }

  // ── Serialise back to JSON (for POST / PUT requests) ────────────────────
  Map<String, dynamic> toJson() => {
    '_id':              { '\$oid': mongoId },
    'id':               id,
    'owner_id':         ownerId,
    'name':             name,
    'cityId':           cityId,
    'cityName':         cityName,
    'barangayName':     barangayName,
    'coordinates': {
      'lat': latitude,
      'lng': longitude,
    },
    'totalTrees':       totalTrees,
    'dnaVerifiedCount': dnaVerifiedCount,
    'hasDnaVerified':   hasDnaVerified,
    'boundary': boundary
        .map((p) => [p.latitude, p.longitude])
        .toList(),
  };

  Farm copyWith({
    String? mongoId,
    int? id,
    int? ownerId,
    String? name,
    int? cityId,
    String? cityName,
    String? barangayName,
    double? latitude,
    double? longitude,
    int? totalTrees,
    int? dnaVerifiedCount,
    bool? hasDnaVerified,
    List<LatLng>? boundary,
  }) {
    return Farm(
      mongoId:          mongoId          ?? this.mongoId,
      id:               id               ?? this.id,
      ownerId:          ownerId          ?? this.ownerId,
      name:             name             ?? this.name,
      cityId:           cityId           ?? this.cityId,
      cityName:         cityName         ?? this.cityName,
      barangayName:     barangayName     ?? this.barangayName,
      latitude:         latitude         ?? this.latitude,
      longitude:        longitude        ?? this.longitude,
      totalTrees:       totalTrees       ?? this.totalTrees,
      dnaVerifiedCount: dnaVerifiedCount ?? this.dnaVerifiedCount,
      hasDnaVerified:   hasDnaVerified   ?? this.hasDnaVerified,
      boundary:         boundary         ?? this.boundary,
    );
  }
}