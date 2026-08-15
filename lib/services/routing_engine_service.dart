import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/vehicle_profile.dart';

class RoutingEngineService {
  // Pre-defined Gujarat > Rajkot Hotspots for realistic dynamic routing
  static const List<RouteLocation> rajkotHotspots = [
    RouteLocation(
      name: "Kalawad Road (Crystal Mall)",
      address: "Kalawad Rd, Opp. Crystal Mall, Rajkot",
      position: LatLng(22.2854, 70.7725),
    ),
    RouteLocation(
      name: "150 Feet Ring Road (KKV Circle)",
      address: "150 Feet Ring Rd, KKV Hall Circle, Rajkot",
      position: LatLng(22.2921, 70.7834),
    ),
    RouteLocation(
      name: "Yagnik Road (Imperial Palace)",
      address: "Dr. Yagnik Rd, Near Race Course, Rajkot",
      position: LatLng(22.3012, 70.8021),
    ),
    RouteLocation(
      name: "Metoda GIDC Industrial Hub",
      address: "Metoda GIDC, Lodhika, Rajkot District",
      position: LatLng(22.2489, 70.6845),
    ),
    RouteLocation(
      name: "Gondal Road Overbridge",
      address: "Gondal Rd, Malaviya Nagar Junction, Rajkot",
      position: LatLng(22.2678, 70.8012),
    ),
  ];

  /// Compute multi-objective route based on Asphr spatial edge weight formulas
  Future<RouteResult> computeRoute({
    required RouteLocation origin,
    required RouteLocation destination,
    required RoutingObjective objective,
    required VehicleProfile vehicle,
  }) async {
    // Simulate graph lookup delay
    await Future.delayed(const Duration(milliseconds: 350));

    // Base Euclidean distance calculation (approximate km in Rajkot geometry)
    final double distKm = _calculateDistanceKm(origin.position, destination.position);
    
    // Polyline geometry simulation based on selected objective
    final List<LatLng> pathPoints = _generatePathPolyline(
      origin.position,
      destination.position,
      objective,
      vehicle,
    );

    // Mathematical Edge Weight Modifications per formula:
    double speedLimitKmh = 60.0;
    double currentSpeedKmh = 45.0;
    double lstmPredictedSpeedKmh = 42.5; // 30-min PyTorch forecast
    double mlHazardScore = 0.28; // Scikit-learn GBM
    double dbHazardScore = 0.22;
    double blendedHazard = 0.7 * mlHazardScore + 0.3 * dbHazardScore;

    double timeMinutes = 0.0;
    double totalHazard = blendedHazard;
    int speedBumpsAvoided = 0;
    String weatherAlert = "Clear skies in Rajkot — 0.0% precipitation impact";

    switch (objective) {
      case RoutingObjective.fastest:
        final double speedRatioPenalty = 1.0 + max(0.0, (speedLimitKmh - lstmPredictedSpeedKmh) / speedLimitKmh);
        final double effectiveSpeed = currentSpeedKmh / speedRatioPenalty;
        timeMinutes = (distKm / effectiveSpeed) * 60.0;
        speedBumpsAvoided = 3;
        break;

      case RoutingObjective.safest:
        weatherAlert = "Monsoon Warning — 0.2 weather multiplier applied";
        totalHazard = blendedHazard * 0.45;
        final double safeSpeed = currentSpeedKmh * 0.85;
        timeMinutes = (distKm / safeSpeed) * 60.0 + 2.5;
        speedBumpsAvoided = 10;
        break;

      case RoutingObjective.straightest:
        final double bearingSmoothSpeed = currentSpeedKmh * 0.95;
        timeMinutes = (distKm / bearingSmoothSpeed) * 60.0 + 1.0;
        speedBumpsAvoided = 5;
        break;

      case RoutingObjective.popular:
        final double popularSpeed = currentSpeedKmh * 0.78;
        timeMinutes = (distKm / popularSpeed) * 60.0 + 3.8;
        speedBumpsAvoided = 2;
        break;
    }

    // Apply Vehicle Profile Pruning adjustments
    if (vehicle.type == VehicleType.bike) {
      timeMinutes *= 0.88;
    } else if (vehicle.type == VehicleType.truck) {
      timeMinutes *= 1.35;
      speedBumpsAvoided += 4;
    } else if (vehicle.type == VehicleType.supercar) {
      totalHazard *= 0.20;
      speedBumpsAvoided += 14;
    }

    final double avgSpeed = (distKm / (timeMinutes / 60.0));

    // Generate Step Instructions
    final List<StepInstruction> instructions = _generateStepInstructions(
      origin.name,
      destination.name,
      objective,
      vehicle,
    );

    // Generate Encountered Hazards
    final List<HazardSegment> hazards = _generateEncounteredHazards(pathPoints);

    return RouteResult(
      routeId: "ASPHR-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}",
      objective: objective,
      vehicleTypeName: vehicle.name,
      totalDistanceKm: double.parse(distKm.toStringAsFixed(2)),
      estimatedTimeMinutes: double.parse(timeMinutes.toStringAsFixed(1)),
      averageSpeedKmh: double.parse(avgSpeed.toStringAsFixed(1)),
      predictedSpeedLstmKmh: double.parse(lstmPredictedSpeedKmh.toStringAsFixed(1)),
      compositeHazardScore: double.parse(totalHazard.toStringAsFixed(2)),
      totalSpeedBumpsAvoided: speedBumpsAvoided,
      polylinePoints: pathPoints,
      instructions: instructions,
      encounteredHazards: hazards,
      weatherAlertText: weatherAlert,
    );
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) *
            cos(p2.latitude * p) *
            (1 - cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  List<LatLng> _generatePathPolyline(
    LatLng start,
    LatLng end,
    RoutingObjective obj,
    VehicleProfile vehicle,
  ) {
    final List<LatLng> points = [start];
    final int steps = 12;

    double curveOffset = 0.008;
    if (obj == RoutingObjective.safest) curveOffset = -0.012;
    if (obj == RoutingObjective.straightest) curveOffset = 0.002;
    if (obj == RoutingObjective.popular) curveOffset = 0.018;

    for (int i = 1; i < steps; i++) {
      final double fraction = i / steps;
      final double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      
      final double perpOffset = sin(fraction * pi) * curveOffset;
      points.add(LatLng(lat + perpOffset, lng + (perpOffset * 0.5)));
    }

    points.add(end);
    return points;
  }

  List<StepInstruction> _generateStepInstructions(
    String originName,
    String destName,
    RoutingObjective objective,
    VehicleProfile vehicle,
  ) {
    return [
      StepInstruction(
        instruction: "Head West towards Kalawad Road",
        roadName: "Kalawad Road",
        distanceMeters: 450.0,
        hazardScore: 0.10,
        iconType: "arrow_upward",
      ),
      StepInstruction(
        instruction: objective == RoutingObjective.safest
            ? "Bypass KKV Circle crater via University Road"
            : "Merge onto 150 Feet Ring Road Flyover (LSTM Traffic Optimal)",
        roadName: "150 Feet Ring Road",
        distanceMeters: 1800.0,
        hazardScore: objective == RoutingObjective.safest ? 0.06 : 0.38,
        iconType: "turn_slight_right",
      ),
      StepInstruction(
        instruction: vehicle.excludeSpeedBumps
            ? "Rerouted around 3 speed bumps near Crystal Mall"
            : "Continue past KKV Hall Circle Junction",
        roadName: "Yagnik Road",
        distanceMeters: 2200.0,
        hazardScore: 0.14,
        iconType: "arrow_upward",
      ),
      StepInstruction(
        instruction: "Arrive at $destName",
        roadName: "Destination Gate",
        distanceMeters: 150.0,
        hazardScore: 0.04,
        iconType: "place",
      ),
    ];
  }

  List<HazardSegment> _generateEncounteredHazards(List<LatLng> path) {
    if (path.length < 5) return [];
    return [
      HazardSegment(
        segmentId: "RJT-889412",
        roadName: "KKV Hall Circle Crossing",
        coordinates: [path[3], path[4]],
        hazardScore: 0.82,
        conditionTier: "severe",
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        ttlSeconds: 4320,
      ),
      HazardSegment(
        segmentId: "RJT-441209",
        roadName: "Gondal Road Underpass",
        coordinates: [path[7], path[8]],
        hazardScore: 0.54,
        conditionTier: "rough",
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ttlSeconds: 5700,
      ),
    ];
  }
}
