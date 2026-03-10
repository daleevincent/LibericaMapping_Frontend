// lib/services/api_config.dart
//
// Central place for all API configuration.
// Change baseUrl to point to your backend server.

class ApiConfig {
  static const String baseUrl = 'https://geomappingbackend-154949125613.asia-southeast1.run.app';

  // ── Farm endpoints ───────────────────────────────────────────────────────
  static const String farms        = '$baseUrl/farms/';
  static String farmById(int id)   => '$baseUrl/farms/$id';

  // ── Tree endpoints ───────────────────────────────────────────────────────
  static const String trees                    = '$baseUrl/trees/';
  static String treesByFarm(int farmId)        => '$baseUrl/trees/?farmId=$farmId';
  static String treeById(String mongoId)       => '$baseUrl/trees/$mongoId';

  // ── Prediction endpoints ─────────────────────────────────────────────────
  static const String predict      = '$baseUrl/predict';
  static const String predictions  = '$baseUrl/farms/';

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration timeout    = Duration(seconds: 10);
  static const Duration mlTimeout  = Duration(seconds: 45);
}