class MLFeatureVector {
  final String featureName;
  final double value;
  final String unit;
  final double weightImportance; // Feature importance percentage in GBM

  const MLFeatureVector({
    required this.featureName,
    required this.value,
    required this.unit,
    required this.weightImportance,
  });
}

class LstmForecastPoint {
  final String timeLabel; // e.g. "-45m", "-30m", "-15m", "Now", "+15m", "+30m (Predicted)"
  final double speedKmh;
  final bool isForecast;

  const LstmForecastPoint({
    required this.timeLabel,
    required this.speedKmh,
    required this.isForecast,
  });
}

class MLInferenceService {
  /// Get 23-Feature Vector for Scikit-Learn Gradient Boosting Hazard Model
  List<MLFeatureVector> getGbmFeatureVectors() {
    return const [
      MLFeatureVector(featureName: "vibration_magnitude_z", value: 2.84, unit: "G", weightImportance: 0.28),
      MLFeatureVector(featureName: "segment_avg_speed", value: 34.2, unit: "km/h", weightImportance: 0.16),
      MLFeatureVector(featureName: "traffic_congestion_level", value: 3.0, unit: "level (0-4)", weightImportance: 0.12),
      MLFeatureVector(featureName: "road_surface_type", value: 1.0, unit: "asphalt", weightImportance: 0.09),
      MLFeatureVector(featureName: "monsoon_precipitation", value: 14.5, unit: "mm/h", weightImportance: 0.08),
      MLFeatureVector(featureName: "historical_pothole_density", value: 0.74, unit: "score", weightImportance: 0.06),
      MLFeatureVector(featureName: "fleet_telemetry_count_24h", value: 1420.0, unit: "passes", weightImportance: 0.05),
      MLFeatureVector(featureName: "vehicle_weight_class", value: 2.0, unit: "tier", weightImportance: 0.04),
      MLFeatureVector(featureName: "gyroscope_yaw_std", value: 0.08, unit: "rad/s", weightImportance: 0.03),
      MLFeatureVector(featureName: "temporal_hour_of_day", value: 18.5, unit: "hrs", weightImportance: 0.03),
      MLFeatureVector(featureName: "ambient_temperature", value: 31.2, unit: "°C", weightImportance: 0.02),
      MLFeatureVector(featureName: "road_width_meters", value: 7.5, unit: "m", weightImportance: 0.02),
      MLFeatureVector(featureName: "poi_density_radius_500m", value: 18.0, unit: "nodes", weightImportance: 0.02),
    ];
  }

  /// Get PyTorch LSTM Speed Forecast Sequence (4-step window, 30-min lookahead)
  List<LstmForecastPoint> getLstmTrafficSequence() {
    return const [
      LstmForecastPoint(timeLabel: "-45m", speedKmh: 46.5, isForecast: false),
      LstmForecastPoint(timeLabel: "-30m", speedKmh: 42.0, isForecast: false),
      LstmForecastPoint(timeLabel: "-15m", speedKmh: 37.8, isForecast: false),
      LstmForecastPoint(timeLabel: "Now", speedKmh: 33.5, isForecast: false),
      LstmForecastPoint(timeLabel: "+15m", speedKmh: 29.2, isForecast: true),
      LstmForecastPoint(timeLabel: "+30m (LSTM)", speedKmh: 24.8, isForecast: true),
    ];
  }
}
