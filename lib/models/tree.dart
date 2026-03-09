// lib/models/tree.dart

enum TreeStatus { dnaVerified, nonDnaVerified }

class CoffeeTree {
  final String treeId;
  final String farmId;
  final double latitude;
  final double longitude;
  final TreeStatus status;

  CoffeeTree({
    required this.treeId,
    required this.farmId,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  bool get isDnaVerified => status == TreeStatus.dnaVerified;

  String get statusLabel =>
      isDnaVerified ? 'DNA Verified' : 'Non-DNA Verified';

  factory CoffeeTree.fromJson(Map<String, dynamic> json) {
    return CoffeeTree(
      treeId: json['treeId'],
      farmId: json['farmId'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      status: json['status'] == 'dnaVerified'
          ? TreeStatus.dnaVerified
          : TreeStatus.nonDnaVerified,
    );
  }

  Map<String, dynamic> toJson() => {
        'treeId': treeId,
        'farmId': farmId,
        'latitude': latitude,
        'longitude': longitude,
        'status': status == TreeStatus.dnaVerified
            ? 'dnaVerified'
            : 'nonDnaVerified',
      };
}
