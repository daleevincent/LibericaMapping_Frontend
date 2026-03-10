// lib/models/tree.dart
//
// Expected MongoDB tree document schema:
// {
//   "_id":        { "$oid": "..." },
//   "treeId":     string,        e.g. "farm_001_T001"
//   "farmId":     int,           matches Farm.id (numeric)
//   "coordinates": { "lat": double, "lng": double },
//   "isDnaVerified": bool
// }

enum TreeStatus { dnaVerified, nonDnaVerified }

class CoffeeTree {
  final String mongoId;       // _id.$oid
  final String treeId;        // human-readable ID
  final int farmId;           // numeric — matches Farm.id
  final double latitude;      // coordinates.lat
  final double longitude;     // coordinates.lng
  final TreeStatus status;    // derived from isDnaVerified

  CoffeeTree({
    this.mongoId = '',
    required this.treeId,
    required this.farmId,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  bool get isDnaVerified => status == TreeStatus.dnaVerified;
  String get statusLabel => isDnaVerified ? 'DNA Verified' : 'Non-DNA Verified';

  // ── Deserialise from MongoDB JSON response ───────────────────────────────
  factory CoffeeTree.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>;

    return CoffeeTree(
      mongoId:   (json['_id'] is Map)
                     ? json['_id']['\$oid'] as String
                     : (json['_id'] ?? '') as String,
      treeId:    json['treeId'] as String,
      farmId:    (json['farmId'] as num).toInt(),
      latitude:  (coords['lat'] as num).toDouble(),
      longitude: (coords['lng'] as num).toDouble(),
      status:    (json['isDnaVerified'] as bool)
                     ? TreeStatus.dnaVerified
                     : TreeStatus.nonDnaVerified,
    );
  }

  // ── Serialise back to JSON ───────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    if (mongoId.isNotEmpty) '_id': { '\$oid': mongoId },
    'treeId':        treeId,
    'farmId':        farmId,
    'coordinates': {
      'lat': latitude,
      'lng': longitude,
    },
    'isDnaVerified': isDnaVerified,
  };
}