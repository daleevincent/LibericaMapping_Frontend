// lib/services/farm_service.dart

import '../models/farm.dart';
import '../utils/mock_data.dart';

class FarmService {
  // In a real app, replace with actual API calls
  Future<List<Farm>> getAllFarms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.farms;
  }

  Future<Farm?> getFarmById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return MockData.farms.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Farm>> searchFarms(String query) async {
    final q = query.toLowerCase();
    return MockData.farms
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.location.toLowerCase().contains(q))
        .toList();
  }

  Future<bool> addFarm(Farm farm) async {
    await Future.delayed(const Duration(milliseconds: 200));
    MockData.farms.add(farm);
    return true;
  }

  Future<bool> updateFarm(Farm updatedFarm) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = MockData.farms.indexWhere((f) => f.id == updatedFarm.id);
    if (index != -1) {
      MockData.farms[index] = updatedFarm;
      return true;
    }
    return false;
  }

  Map<String, dynamic> getSummaryStats() {
    final farms = MockData.farms;
    return {
      'totalFarms': farms.length,
      'totalLibericaTrees': farms.fold<int>(0, (sum, f) => sum + f.libericaTrees),
      'totalDnaVerifiedTrees':
          farms.fold<int>(0, (sum, f) => sum + f.dnaVerifiedTrees),
      'totalFieldSize':
          farms.fold<double>(0, (sum, f) => sum + f.fieldSize),
    };
  }
}