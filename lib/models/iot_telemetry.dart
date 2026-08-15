import 'package:latlong2/latlong.dart';

class IoTReading {
  final DateTime timestamp;
  final LatLng location;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double vibrationMagnitude; // sqrt(x^2 + y^2 + z^2) - 9.81
  final double gyroZ;
  final double currentSpeedKmh;
  final String snappedSegmentId;
  final String conditionTier; // smooth, moderate, rough, severe

  const IoTReading({
    required this.timestamp,
    required this.location,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.vibrationMagnitude,
    required this.gyroZ,
    required this.currentSpeedKmh,
    required this.snappedSegmentId,
    required this.conditionTier,
  });
}

class HazardAlertEvent {
  final String alertId;
  final String segmentName;
  final LatLng position;
  final double hazardScore;
  final String conditionTier;
  final double peakVibrationG;
  final DateTime timestamp;
  final Duration timeToLive;

  const HazardAlertEvent({
    required this.alertId,
    required this.segmentName,
    required this.position,
    required this.hazardScore,
    required this.conditionTier,
    required this.peakVibrationG,
    required this.timestamp,
    required this.timeToLive,
  });
}

class RLHFFeedbackPayload {
  final String routeId;
  final int hazardAccuracyRating;   // 1 to 5
  final int rideComfortRating;       // 1 to 5
  final bool encounteredUnmappedHazard;
  final int routeEfficiencyRating;  // 1 to 5
  final int overallRecommendation;  // 1 to 5
  final String userComments;

  const RLHFFeedbackPayload({
    required this.routeId,
    required this.hazardAccuracyRating,
    required this.rideComfortRating,
    required this.encounteredUnmappedHazard,
    required this.routeEfficiencyRating,
    required this.overallRecommendation,
    this.userComments = "",
  });
}
