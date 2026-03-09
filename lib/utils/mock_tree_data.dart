// lib/utils/mock_tree_data.dart
//
// Real surveyed tree coordinates, organised per farm.
// To add a new farm's trees:
//   1. Create a new list constant below (e.g. farm002Trees)
//   2. Add a case for it in MockData.getTreesForFarm() inside mock_data.dart

import '../models/tree.dart';

// ---------------------------------------------------------------------------
// Helper – lightweight coordinate + status holder
// ---------------------------------------------------------------------------
class TreeCoord {
  final double lat;
  final double lng;
  final TreeStatus status;
  const TreeCoord(this.lat, this.lng, this.status);
}

// ---------------------------------------------------------------------------
// farm_001 – Dela Cruz Liberica Farm, Lipa City
// 9 DNA Verified  |  8 Non-DNA Verified  |  17 total
// ---------------------------------------------------------------------------
const List<TreeCoord> farm001Trees = [
  // --- DNA Verified (blue) ---
  TreeCoord(13.928890288111239, 121.19980274022417, TreeStatus.dnaVerified),
  TreeCoord(13.928774152052075, 121.19982029309209, TreeStatus.dnaVerified),
  TreeCoord(13.92866899150334,  121.19982679236837, TreeStatus.dnaVerified),
  TreeCoord(13.928565773647893, 121.19985312183181, TreeStatus.dnaVerified),
  TreeCoord(13.928442446782878, 121.19992668404637, TreeStatus.dnaVerified),
  TreeCoord(13.928299442867226, 121.19997541424864, TreeStatus.dnaVerified),
  TreeCoord(13.928132656012336, 121.20004001532268, TreeStatus.dnaVerified),
  TreeCoord(13.927917134224638, 121.20007797280189, TreeStatus.dnaVerified),
  TreeCoord(13.927811061529425, 121.20009867278921, TreeStatus.dnaVerified),
  // --- Non-DNA Verified (green) ---
  TreeCoord(13.92896682696068,  121.19994312051354, TreeStatus.nonDnaVerified),
  TreeCoord(13.928827945878613, 121.20005103722076, TreeStatus.nonDnaVerified),
  TreeCoord(13.928680397040733, 121.20011426114368, TreeStatus.nonDnaVerified),
  TreeCoord(13.92838624848402,  121.20019420923225, TreeStatus.nonDnaVerified),
  TreeCoord(13.928215714506543, 121.20025114194843, TreeStatus.nonDnaVerified),
  TreeCoord(13.92811606395141,  121.20028336304787, TreeStatus.nonDnaVerified),
  TreeCoord(13.927966845911946, 121.20032926953398, TreeStatus.nonDnaVerified),
  TreeCoord(13.927892562667727, 121.20035157453457, TreeStatus.nonDnaVerified),
];

// ---------------------------------------------------------------------------
// farm_002 – Santos Heritage Farm, Ibaan  (paste real coords here when ready)
// ---------------------------------------------------------------------------
// const List<TreeCoord> farm002Trees = [
//   TreeCoord(13.8205, 121.1279, TreeStatus.dnaVerified),
//   ...
// ];

// ---------------------------------------------------------------------------
// farm_003 – Reyes Coffee Plantation, Rosario  (paste real coords here)
// ---------------------------------------------------------------------------
// const List<TreeCoord> farm003Trees = [ ... ];