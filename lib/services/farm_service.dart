// lib/services/farm_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farm.dart';
import 'api_config.dart';

class FarmService {
  // ── GET all farms ────────────────────────────────────────────────────────
  Future<List<Farm>> getAllFarms() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.farms))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Filter only real farm documents — must have 'name' and 'coordinates'
        // Prediction records only have 'prediction', 'confidence_ratio', etc.
        final farmDocs = data.where((doc) =>
            doc is Map<String, dynamic> &&
            doc.containsKey('name') &&
            doc.containsKey('coordinates')).toList();

        final farms = <Farm>[];
        for (final doc in farmDocs) {
          try {
            farms.add(Farm.fromJson(doc as Map<String, dynamic>));
          } catch (_) {
            // Skip malformed documents silently
          }
        }
        return farms;
      }
      throw Exception('Failed to load farms: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── GET single farm by numeric id ────────────────────────────────────────
  Future<Farm?> getFarmById(int id) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.farmById(id)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Farm.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 404) return null;
      throw Exception('Failed to load farm: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── POST create new farm ─────────────────────────────────────────────────
  Future<void> addFarm(Farm farm) async {
    try {
      // Remove _id from payload — MongoDB generates it automatically
      final json = farm.toJson();
      json.remove('_id');

      final response = await http
          .post(
            Uri.parse(ApiConfig.farms),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(json),
          )
          .timeout(ApiConfig.timeout);

      // Flask returns {"message": "Farm created"} — just check status
      if (response.statusCode == 200 || response.statusCode == 201) return;

      throw Exception(
          'Failed to create farm: ${response.statusCode} — ${response.body}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── PUT update existing farm ─────────────────────────────────────────────
  Future<Farm> updateFarm(Farm farm) async {
    try {
      final response = await http
          .put(
            Uri.parse(ApiConfig.farmById(farm.id)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(farm.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Farm.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to update farm: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── Summary stats (computed client-side from fetched data) ───────────────
  Map<String, dynamic> computeStats(List<Farm> farms) {
    return {
      'totalFarms':            farms.length,
      'totalLibericaTrees':    farms.fold<int>(0, (s, f) => s + f.totalTrees),
      'totalDnaVerifiedTrees': farms.fold<int>(0, (s, f) => s + f.dnaVerifiedCount),
    };
  }
}