import 'package:latlong2/latlong.dart';

enum RoutingObjective { fastest, safest, straightest, popular }

class StepInstruction {
  final String instruction;
  final String roadName;
  final double distanceMeters;
  final double hazardScore; // 0.0 to 1.0
  final String iconType;

  const StepInstruction({
    required this.instruction,
    required this.roadName,
    required this.distanceMeters,
    required this.hazardScore,
    required this.iconType,
  });
}

class HazardSegment {
  final String segmentId;
  final String roadName;
  final List<LatLng> coordinates;
  final double hazardScore; // 0.0 to 1.0
  final String conditionTier; // smooth, moderate, rough, severe
  final DateTime timestamp;
  final int ttlSeconds;

  const HazardSegment({
    required this.segmentId,
    required this.roadName,
    required this.coordinates,
    required this.hazardScore,
    required this.conditionTier,
    required this.timestamp,
    required this.ttlSeconds,
  });
}

class RouteLocation {
  final String name;
  final String address;
  final LatLng position;

  const RouteLocation({
    required this.name,
    required this.address,
    required this.position,
  });
}

class RouteResult {
  final String routeId;
  final RoutingObjective objective;
  final String vehicleTypeName;
  final double totalDistanceKm;
  final double estimatedTimeMinutes;
  final double averageSpeedKmh;
  final double predictedSpeedLstmKmh;
  final double compositeHazardScore; // 0.0 to 1.0
  final int totalSpeedBumpsAvoided;
  final List<LatLng> polylinePoints;
  final List<StepInstruction> instructions;
  final List<HazardSegment> encounteredHazards;
  final String weatherAlertText;

  const RouteResult({
    required this.routeId,
    required this.objective,
    required this.vehicleTypeName,
    required this.totalDistanceKm,
    required this.estimatedTimeMinutes,
    required this.averageSpeedKmh,
    required this.predictedSpeedLstmKmh,
    required this.compositeHazardScore,
    required this.totalSpeedBumpsAvoided,
    required this.polylinePoints,
    required this.instructions,
    required this.encounteredHazards,
    required this.weatherAlertText,
  });
}
