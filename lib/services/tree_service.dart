// lib/services/tree_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tree.dart';
import 'api_config.dart';

class TreeService {
  // ── GET all trees for a farm (by numeric farmId) ─────────────────────────
  Future<List<CoffeeTree>> getTreesForFarm(int farmId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.treesByFarm(farmId)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CoffeeTree.fromJson(json)).toList();
      }
      throw Exception('Failed to load trees: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── Filtered helpers ─────────────────────────────────────────────────────
  Future<List<CoffeeTree>> getDnaVerifiedTrees(int farmId) async {
    final trees = await getTreesForFarm(farmId);
    return trees.where((t) => t.isDnaVerified).toList();
  }

  Future<List<CoffeeTree>> getNonVerifiedTrees(int farmId) async {
    final trees = await getTreesForFarm(farmId);
    return trees.where((t) => !t.isDnaVerified).toList();
  }

  // ── POST add a new tree ──────────────────────────────────────────────────
  Future<CoffeeTree> addTree(CoffeeTree tree) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.trees),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(tree.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return CoffeeTree.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to add tree: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── DELETE a tree by its MongoDB _id ────────────────────────────────────
  Future<void> deleteTree(String mongoId) async {
    try {
      final response = await http
          .delete(Uri.parse('${ApiConfig.trees}/$mongoId'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete tree: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}