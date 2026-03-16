// lib/utils/mock_tree_data.dart
//
// Temporary mock tree data matching the real farm documents in MongoDB.
// Replace with real API calls once backend /trees endpoint is confirmed.

import 'dart:math' as math;
import '../models/tree.dart';

class MockTreeData {
  // ── Farm 1: Green Valley Farm (Batangas City, Alangilan) ──────────────────
  static const List<Map<String, dynamic>> _farm1Trees = [
    {'treeId': 'GVF_T001', 'farmId': 1, 'lat': 13.75600, 'lng': 121.05800, 'dna': false},
    {'treeId': 'GVF_T002', 'farmId': 1, 'lat': 13.75610, 'lng': 121.05815, 'dna': false},
    {'treeId': 'GVF_T003', 'farmId': 1, 'lat': 13.75620, 'lng': 121.05830, 'dna': false},
    {'treeId': 'GVF_T004', 'farmId': 1, 'lat': 13.75630, 'lng': 121.05845, 'dna': false},
    {'treeId': 'GVF_T005', 'farmId': 1, 'lat': 13.75640, 'lng': 121.05860, 'dna': false},
    {'treeId': 'GVF_T006', 'farmId': 1, 'lat': 13.75590, 'lng': 121.05820, 'dna': false},
    {'treeId': 'GVF_T007', 'farmId': 1, 'lat': 13.75580, 'lng': 121.05835, 'dna': false},
    {'treeId': 'GVF_T008', 'farmId': 1, 'lat': 13.75570, 'lng': 121.05850, 'dna': false},
    {'treeId': 'GVF_T009', 'farmId': 1, 'lat': 13.75560, 'lng': 121.05865, 'dna': false},
    {'treeId': 'GVF_T010', 'farmId': 1, 'lat': 13.75550, 'lng': 121.05880, 'dna': false},
  ];

  // ── Farm 2: Katy's Farm (Lipa City, Tangob) ───────────────────────────────
static const List<Map<String, dynamic>> _farm2Trees = [
  {'treeId': 'KF_T001', 'farmId': 2, 'lat': 13.928890288111239, 'lng': 121.19980274022417, 'dna': true},
  {'treeId': 'KF_T002', 'farmId': 2, 'lat': 13.928774152052075, 'lng': 121.19982029309209, 'dna': true},
  {'treeId': 'KF_T003', 'farmId': 2, 'lat': 13.92866899150334, 'lng': 121.19982679236837, 'dna': true},
  {'treeId': 'KF_T004', 'farmId': 2, 'lat': 13.928565773647893, 'lng': 121.19985312183181, 'dna': false},
  {'treeId': 'KF_T005', 'farmId': 2, 'lat': 13.928442446782878, 'lng': 121.19992668404637, 'dna': false},
  {'treeId': 'KF_T006', 'farmId': 2, 'lat': 13.928299442867226, 'lng': 121.19997541424864, 'dna': false},
  {'treeId': 'KF_T007', 'farmId': 2, 'lat': 13.928132656012336, 'lng': 121.20004001532268, 'dna': false},
  {'treeId': 'KF_T008', 'farmId': 2, 'lat': 13.927917134224638, 'lng': 121.20007797280189, 'dna': false},
  {'treeId': 'KF_T009', 'farmId': 2, 'lat': 13.927811061529425, 'lng': 121.20009867278921, 'dna': false},
  {'treeId': 'KF_T010', 'farmId': 2, 'lat': 13.92896682696068, 'lng': 121.19994312051354, 'dna': false},
  {'treeId': 'KF_T011', 'farmId': 2, 'lat': 13.928827945878613, 'lng': 121.20005103722076, 'dna': false},
  {'treeId': 'KF_T012', 'farmId': 2, 'lat': 13.928680397040733, 'lng': 121.20011426114368, 'dna': false},
  {'treeId': 'KF_T013', 'farmId': 2, 'lat': 13.92838624848402, 'lng': 121.20019420923225, 'dna': false},
  {'treeId': 'KF_T014', 'farmId': 2, 'lat': 13.928215714506543, 'lng': 121.20025114194843, 'dna': false},
  {'treeId': 'KF_T015', 'farmId': 2, 'lat': 13.92811606395141, 'lng': 121.20028336304787, 'dna': false},
  {'treeId': 'KF_T016', 'farmId': 2, 'lat': 13.927966845911946, 'lng': 121.20032926953398, 'dna': false},
  {'treeId': 'KF_T017', 'farmId': 2, 'lat': 13.927892562667727, 'lng': 121.20035157453457, 'dna': false},
];

  // ── Farm 3: Sunrise Orchard (Rosario, Alupay) ────────────────────────────
  static const List<Map<String, dynamic>> _farm3Trees = [
    {'treeId': 'SO_T001', 'farmId': 3, 'lat': 13.848115, 'lng': 121.203014, 'dna': true},
    {'treeId': 'SO_T002', 'farmId': 3, 'lat': 13.848200, 'lng': 121.203100, 'dna': true},
    {'treeId': 'SO_T003', 'farmId': 3, 'lat': 13.848300, 'lng': 121.203200, 'dna': true},
    {'treeId': 'SO_T004', 'farmId': 3, 'lat': 13.848400, 'lng': 121.203300, 'dna': true},
    {'treeId': 'SO_T005', 'farmId': 3, 'lat': 13.848500, 'lng': 121.203400, 'dna': true},
    {'treeId': 'SO_T006', 'farmId': 3, 'lat': 13.847950, 'lng': 121.202950, 'dna': false},
    {'treeId': 'SO_T007', 'farmId': 3, 'lat': 13.847850, 'lng': 121.202850, 'dna': false},
    {'treeId': 'SO_T008', 'farmId': 3, 'lat': 13.847750, 'lng': 121.202750, 'dna': false},
    {'treeId': 'SO_T009', 'farmId': 3, 'lat': 13.847650, 'lng': 121.202650, 'dna': false},
    {'treeId': 'SO_T010', 'farmId': 3, 'lat': 13.847550, 'lng': 121.202550, 'dna': false},
  ];

  // ── All trees ─────────────────────────────────────────────────────────────
  static List<CoffeeTree> get allTrees => [
    ..._farm1Trees,
    ..._farm2Trees,
    ..._farm3Trees,
  ].map((t) => CoffeeTree(
    mongoId:   '',
    treeId:    t['treeId'] as String,
    farmId:    t['farmId'] as int,
    latitude:  t['lat'] as double,
    longitude: t['lng'] as double,
    status:    (t['dna'] as bool)
                   ? TreeStatus.dnaVerified
                   : TreeStatus.nonDnaVerified,
  )).toList();

  // ── Get trees by farm ID ──────────────────────────────────────────────────
  static List<CoffeeTree> getTreesForFarm(int farmId) =>
      allTrees.where((t) => t.farmId == farmId).toList();

  // ── Find tree by exact GPS coordinate ────────────────────────────────────
  static TreeLocationResult? findByCoordinates(double lat, double lng) {
    for (final tree in allTrees) {
      if (tree.latitude == lat && tree.longitude == lng) {
        return TreeLocationResult(tree: tree);
      }
    }
    return null;
  }

  // ── Find nearest tree within a radius (meters) ────────────────────────────
  // Returns null if no tree is within the threshold.
  static TreeLocationResult? findNearest(double lat, double lng,
      {double thresholdMeters = 50}) {
    TreeLocationResult? closest;
    double closestDist = double.infinity;

    for (final tree in allTrees) {
      final dist = _haversineMeters(lat, lng, tree.latitude, tree.longitude);
      if (dist < closestDist) {
        closestDist = dist;
        closest = TreeLocationResult(tree: tree, distanceMeters: dist);
      }
    }
    if (closestDist <= thresholdMeters) return closest;
    return null;
  }

  // ── Haversine distance in meters ──────────────────────────────────────────
  static double _haversineMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.asin(math.sqrt(a));
  }

  // ── Farm metadata mirrors MongoDB ─────────────────────────────────────────
  static const Map<int, String> farmNames = {
    1: 'Green Valley Farm',
    2: "Katy's Farm",
    3: 'Sunrise Orchard',
  };

  static const Map<int, String> farmLocations = {
    1: 'Alangilan, Batangas City',
    2: 'Tangob, Lipa City',
    3: 'Alupay, Rosario',
  };
}

// ── Lookup result ─────────────────────────────────────────────────────────
class TreeLocationResult {
  final CoffeeTree tree;
  final double distanceMeters;
  const TreeLocationResult({required this.tree, this.distanceMeters = 0});

  String get farmName =>
      MockTreeData.farmNames[tree.farmId] ?? 'Unknown Farm';
  String get farmLocation =>
      MockTreeData.farmLocations[tree.farmId] ?? 'Unknown Location';
}