// lib/models/prediction.dart
//
// Matches the actual Flask backend response from /predict:
// {
//   "final_prediction":       "Liberica" | "Not Liberica"
//   "plant_part_mode":        "leaf" | "bark" | "cherry" | "mix"
//   "confidence_ratio":       99.18
//   "gradcam_image":          "data:image/png;base64,..."  (or null)
//   "individual_predictions": {
//     "leaf":   { "prediction": "Liberica", "confidence": 97.5 },
//     "bark":   { "prediction": "Not Liberica", "confidence": 62.1 },
//     "cherry": { "prediction": "Liberica", "confidence": 88.3 }
//   }
// }
//
// When saved to MongoDB (via FarmModel.create), the document also includes:
// {
//   "_id":              { "$oid": "..." }
//   "coordinates":      { "lat": double, "lng": double }
//   "prediction":       "Liberica" | "Not Liberica"  ← note: not "final_prediction"
//   "confidence_ratio": double
//   "plant_part_mode":  string
// }

class IndividualPrediction {
  final String prediction;
  final double confidence;

  IndividualPrediction({required this.prediction, required this.confidence});

  factory IndividualPrediction.fromJson(Map<String, dynamic> json) {
    return IndividualPrediction(
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class Prediction {
  // ── Core fields (from /predict response) ─────────────────────────────────
  final String mongoId;
  final String finalPrediction;     // "Liberica" or "Not Liberica"
  final String plantPartMode;       // "leaf" | "bark" | "cherry" | "mix"
  final double confidenceRatio;     // 0.0 – 100.0
  final String? gradCamImage;       // base64 "data:image/png;base64,..."
  final Map<String, IndividualPrediction> individualPredictions;

  // ── Coordinate fields (saved to MongoDB alongside prediction) ────────────
  final double? latitude;
  final double? longitude;

  Prediction({
    this.mongoId = '',
    required this.finalPrediction,
    required this.plantPartMode,
    required this.confidenceRatio,
    this.gradCamImage,
    this.individualPredictions = const {},
    this.latitude,
    this.longitude,
  });

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isLiberica => finalPrediction.toLowerCase() == 'liberica';

  String get confidenceLabel => '${confidenceRatio.toStringAsFixed(1)}%';

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasGradCam => gradCamImage != null && gradCamImage!.isNotEmpty;

  String get modeLabel {
    switch (plantPartMode) {
      case 'leaf':   return '🍃 Leaf';
      case 'bark':   return '🪵 Bark';
      case 'cherry': return '🍒 Cherry';
      case 'mix':    return '🔀 Combined';
      default:       return plantPartMode;
    }
  }

  // ── Deserialize from /predict response ───────────────────────────────────
  factory Prediction.fromPredictResponse(Map<String, dynamic> json) {
    final rawIndividual =
        json['individual_predictions'] as Map<String, dynamic>? ?? {};
    final individual = rawIndividual.map(
      (key, value) => MapEntry(
        key,
        IndividualPrediction.fromJson(value as Map<String, dynamic>),
      ),
    );

    return Prediction(
      finalPrediction: json['final_prediction'] as String,
      plantPartMode:   json['plant_part_mode']  as String,
      confidenceRatio: (json['confidence_ratio'] as num).toDouble(),
      gradCamImage:    json['gradcam_image']     as String?,
      individualPredictions: individual,
    );
  }

  // ── Deserialize from MongoDB saved document (GET /farms) ─────────────────
  factory Prediction.fromMongoDoc(Map<String, dynamic> json) {
    final id = json['_id'];
    final mongoId = id is Map
        ? (id['\$oid'] ?? '') as String
        : (id ?? '') as String;

    final coords = json['coordinates'] as Map<String, dynamic>?;

    return Prediction(
      mongoId:         mongoId,
      finalPrediction: json['prediction'] as String,   // saved field name differs
      plantPartMode:   json['plant_part_mode'] as String,
      confidenceRatio: (json['confidence_ratio'] as num).toDouble(),
      latitude:  coords != null ? (coords['lat'] as num).toDouble() : null,
      longitude: coords != null ? (coords['lng'] as num).toDouble() : null,
    );
  }
}