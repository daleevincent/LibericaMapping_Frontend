// lib/utils/mock_data.dart

import 'package:latlong2/latlong.dart';
import '../models/farm.dart';
import '../models/tree.dart';
import 'mock_tree_data.dart';

class MockData {
  static List<Farm> farms = [
    Farm(
      id: 'farm_001',
          name: "Katy's Farm",
          location: 'Lipa City, Batangas',
          latitude: 13.929004529835746,    
          longitude: 121.19948425244083,
          fieldSize: 2.5,
          libericaTrees: 634,
          dnaVerifiedTrees: 3,
          polygonCoordinates: [
            LatLng(13.929181493890452, 121.2003661307884),
            LatLng(13.928968589224295, 121.19962697141182),            
            LatLng(13.927735221578898, 121.20002947094893),
            LatLng(13.927985820670253, 121.20079306505929),
          ],
    ),
    Farm(
      id: 'farm_002',
      name: 'Santos Heritage Farm',
      location: 'Ibaan, Batangas',
      latitude: 13.8203,
      longitude: 121.1277,
      fieldSize: 3.8,
      libericaTrees: 210,
      dnaVerifiedTrees: 155,
      polygonCoordinates: [
        LatLng(13.8208, 121.1270),
        LatLng(13.8208, 121.1285),
        LatLng(13.8198, 121.1285),
        LatLng(13.8198, 121.1270),
      ],
    ),
    Farm(
      id: 'farm_003',
      name: 'Reyes Coffee Plantation',
      location: 'Rosario, Batangas',
      latitude: 13.8469,
      longitude: 121.2031,
      fieldSize: 1.9,
      libericaTrees: 95,
      dnaVerifiedTrees: 62,
      polygonCoordinates: [
        LatLng(13.8474, 121.2025),
        LatLng(13.8474, 121.2038),
        LatLng(13.8464, 121.2038),
        LatLng(13.8464, 121.2025),
      ],
    ),
    Farm(
      id: 'farm_004',
      name: 'Batangas Highland Farm',
      location: 'Taysan, Batangas',
      latitude: 13.7562,
      longitude: 121.1098,
      fieldSize: 5.2,
      libericaTrees: 340,
      dnaVerifiedTrees: 289,
      polygonCoordinates: [
        LatLng(13.7570, 121.1088),
        LatLng(13.7570, 121.1108),
        LatLng(13.7554, 121.1108),
        LatLng(13.7554, 121.1088),
      ],
    ),
    Farm(
      id: 'farm_005',
      name: 'Garcia Liberica Estate',
      location: 'San Jose, Batangas',
      latitude: 13.8733,
      longitude: 121.0872,
      fieldSize: 4.1,
      libericaTrees: 185,
      dnaVerifiedTrees: 110,
      polygonCoordinates: [
        LatLng(13.8740, 121.0863),
        LatLng(13.8740, 121.0882),
        LatLng(13.8726, 121.0882),
        LatLng(13.8726, 121.0863),
      ],
    ),
    Farm(
      id: 'farm_006',
      name: 'Mendoza Agri Farm',
      location: 'Padre Garcia, Batangas',
      latitude: 13.8921,
      longitude: 121.2244,
      fieldSize: 2.8,
      libericaTrees: 142,
      dnaVerifiedTrees: 98,
      polygonCoordinates: [
        LatLng(13.8928, 121.2236),
        LatLng(13.8928, 121.2252),
        LatLng(13.8914, 121.2252),
        LatLng(13.8914, 121.2236),
      ],
    ),
  ];

  static List<CoffeeTree> getTreesForFarm(String farmId) {
    // ── Farms with real surveyed coordinates ──────────────────────────────
    // Add more cases here as you collect field data for each farm.
    final List<TreeCoord>? realCoords = switch (farmId) {
      'farm_001' => farm001Trees,
      // 'farm_002' => farm002Trees,   // uncomment when data is ready
      // 'farm_003' => farm003Trees,
      _ => null,
    };

    if (realCoords != null) {
      return realCoords.asMap().entries.map((entry) {
        final i = entry.key;
        final t = entry.value;
        return CoffeeTree(
          treeId: '${farmId}_T${(i + 1).toString().padLeft(3, '0')}',
          farmId: farmId,
          latitude: t.lat,
          longitude: t.lng,
          status: t.status,
        );
      }).toList();
    }

    // ── Fallback: random positions for farms without real data yet ─────────
    final farm = farms.firstWhere((f) => f.id == farmId);
    final List<CoffeeTree> trees = [];
    final _Random rng = _Random(farmId.hashCode);
    const double spread = 0.004;

    for (int i = 0; i < farm.libericaTrees; i++) {
      trees.add(CoffeeTree(
        treeId: '${farmId}_T${(i + 1).toString().padLeft(3, '0')}',
        farmId: farmId,
        latitude: farm.latitude + (rng.nextDouble() - 0.5) * spread,
        longitude: farm.longitude + (rng.nextDouble() - 0.5) * spread,
        status: i < farm.dnaVerifiedTrees
            ? TreeStatus.dnaVerified
            : TreeStatus.nonDnaVerified,
      ));
    }
    return trees;
  }
}

// LCG random number generator – only used for farms without real coordinates
class _Random {
  int _seed;
  _Random(this._seed);

  double nextDouble() {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed & 0xFFFFFF) / 0xFFFFFF;
  }
}