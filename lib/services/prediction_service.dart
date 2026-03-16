// lib/services/prediction_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/prediction.dart';
import 'api_config.dart';

class PredictionService {
  // ── POST /predict ─────────────────────────────────────────────────────────
  // Uses XFile + Uint8List so it works on both Flutter Web and mobile.
  Future<Prediction> predict({
    required XFile imageFile,
    required Uint8List imageBytes,
    required String plantPartMode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.predict),
      );

      // ── Image — use fromBytes so it works on web ──────────────────────────
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.name,
        ),
      );

      // ── Plant part ────────────────────────────────────────────────────────
      request.fields['plant_part'] = plantPartMode;

      // ── Optional coordinates ──────────────────────────────────────────────
      if (latitude != null && longitude != null) {
        request.fields['lat'] = latitude.toString();
        request.fields['lng'] = longitude.toString();
      }

      final streamedResponse = await request.send().timeout(
        ApiConfig.mlTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final prediction = Prediction.fromPredictResponse(json);
        // Re-attach the coordinates the user entered — the backend response
        // does not echo them back, so we inject them here.
        return Prediction(
          mongoId:               prediction.mongoId,
          finalPrediction:       prediction.finalPrediction,
          plantPartMode:         prediction.plantPartMode,
          confidenceRatio:       prediction.confidenceRatio,
          gradCamImage:          prediction.gradCamImage,
          individualPredictions: prediction.individualPredictions,
          latitude:              latitude,
          longitude:             longitude,
        );
      }
      throw Exception(
          'Prediction failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      throw Exception('Prediction error: $e');
    }
  }

  // ── GET /farms/ — fetch saved predictions from MongoDB ───────────────────
  Future<List<Prediction>> getAllPredictions() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.predictions))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .where((doc) =>
                doc is Map<String, dynamic> && doc.containsKey('prediction'))
            .map((doc) => Prediction.fromMongoDoc(doc as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load predictions [${response.statusCode}]');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Prediction>> getPredictionsByMode(String mode) async {
    final all = await getAllPredictions();
    if (mode == 'all') return all;
    return all.where((p) => p.plantPartMode == mode).toList();
  }
}