// lib/services/tree_service.dart

import '../models/tree.dart';
import '../utils/mock_data.dart';

class TreeService {
  Future<List<CoffeeTree>> getTreesForFarm(String farmId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.getTreesForFarm(farmId);
  }

  Future<List<CoffeeTree>> getDnaVerifiedTrees(String farmId) async {
    final trees = await getTreesForFarm(farmId);
    return trees.where((t) => t.isDnaVerified).toList();
  }

  Future<List<CoffeeTree>> getNonVerifiedTrees(String farmId) async {
    final trees = await getTreesForFarm(farmId);
    return trees.where((t) => !t.isDnaVerified).toList();
  }
}
