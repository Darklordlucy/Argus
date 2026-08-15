import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/vehicle_profile.dart';

class RoutingEngineService {
  // Pre-defined Mumbai Hotspots for realistic dynamic routing
  static const List<RouteLocation> mumbaiHotspots = [
    RouteLocation(
      name: "Bandra Kurla Complex (BKC)",
      address: "G Block, BKC, Bandra East, Mumbai",
      position: LatLng(19.0657, 72.8686),
    ),
    RouteLocation(
      name: "Worli Sea Link Toll",
      address: "Bandra-Worli Sea Link, Worli, Mumbai",
      position: LatLng(19.0330, 72.8185),
    ),
    RouteLocation(
      name: "Chhatrapati Shivaji Airport (T2)",
      address: "Sahar Rd, Vile Parle East, Mumbai",
      position: LatLng(19.0896, 72.8656),
    ),
    RouteLocation(
      name: "Marine Drive Promenade",
      address: "Netaji Subhash Chandra Bose Rd, Churchgate",
      position: LatLng(18.9438, 72.8232),
    ),
    RouteLocation(
      name: "Western Express Highway (Santa Cruz)",
      address: "WEH Flyover Junction, Santa Cruz East",
      position: LatLng(19.0822, 72.8519),
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

    // Base Euclidean distance calculation (approximate km in Mumbai geometry)
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
    double currentSpeedKmh = 42.0;
    double lstmPredictedSpeedKmh = 38.5; // 30-min PyTorch forecast
    double mlHazardScore = 0.32; // Scikit-learn GBM
    double dbHazardScore = 0.28;
    double blendedHazard = 0.7 * mlHazardScore + 0.3 * dbHazardScore;

    double timeMinutes = 0.0;
    double totalHazard = blendedHazard;
    int speedBumpsAvoided = 0;
    String weatherAlert = "Clear skies — 0.0% precipitation impact";

    switch (objective) {
      case RoutingObjective.fastest:
        // Formula: W = L / (S_current / 3.6) * (1 + max(0, (S_limit - S_predicted)/S_limit))
        final double speedRatioPenalty = 1.0 + max(0.0, (speedLimitKmh - lstmPredictedSpeedKmh) / speedLimitKmh);
        final double effectiveSpeed = currentSpeedKmh / speedRatioPenalty;
        timeMinutes = (distKm / effectiveSpeed) * 60.0;
        speedBumpsAvoided = 4;
        break;

      case RoutingObjective.safest:
        // Formula: W = L * (1 + H_blended) * (1 + C_weather)
        final double weatherSeverity = 0.2; // Moderate monsoon dampness
        weatherAlert = "Monsoon Warning — 0.2 weather multiplier applied";
        totalHazard = blendedHazard * 0.45; // 55% hazard reduction over safest path
        final double safeSpeed = currentSpeedKmh * 0.85;
        timeMinutes = (distKm / safeSpeed) * 60.0 + 3.0; // Slightly longer time for maximum safety
        speedBumpsAvoided = 12;
        break;

      case RoutingObjective.straightest:
        // Custom A* angular bearing deviation penalty (delta_theta * 2.5)
        final double bearingSmoothSpeed = currentSpeedKmh * 0.95;
        timeMinutes = (distKm / bearingSmoothSpeed) * 60.0 + 1.2;
        speedBumpsAvoided = 7;
        break;

      case RoutingObjective.popular:
        // POI density bonus routing
        final double popularSpeed = currentSpeedKmh * 0.78;
        timeMinutes = (distKm / popularSpeed) * 60.0 + 4.5; // Scenic detour
        speedBumpsAvoided = 3;
        break;
    }

    // Apply Vehicle Profile Pruning adjustments
    if (vehicle.type == VehicleType.bike) {
      timeMinutes *= 0.88; // Bikes bypass city congestion
    } else if (vehicle.type == VehicleType.truck) {
      timeMinutes *= 1.35; // Heavy fleet restrictions
      speedBumpsAvoided += 5;
    } else if (vehicle.type == VehicleType.supercar) {
      totalHazard *= 0.20; // Extremely strict hazard exclusion
      speedBumpsAvoided += 18;
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
    const double p = 0.017453292519943295; // Pi / 180
    final double a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) *
            cos(p2.latitude * p) *
            (1 - cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  List<LatLng> _generatePathPolyline(
    LatLng start,
    LatLng end,
    RoutingObjective obj,
    VehicleProfile vehicle,
  ) {
    final List<LatLng> points = [start];
    final int steps = 12;

    // Introduce curvature depending on routing objective
    double curveOffset = 0.008;
    if (obj == RoutingObjective.safest) curveOffset = -0.012;
    if (obj == RoutingObjective.straightest) curveOffset = 0.002;
    if (obj == RoutingObjective.popular) curveOffset = 0.018;

    for (int i = 1; i < steps; i++) {
      final double fraction = i / steps;
      final double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      
      // Add subtle curve offset
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
        instruction: "Head North towards Western Express Highway",
        roadName: "BKC Link Road",
        distanceMeters: 450.0,
        hazardScore: 0.12,
        iconType: "arrow_upward",
      ),
      StepInstruction(
        instruction: objective == RoutingObjective.safest
            ? "Bypass severe crater zone via Senapati Bapat Marg"
            : "Merge onto Western Express Flyover (LSTM Traffic Optimal)",
        roadName: "Senapati Bapat Marg",
        distanceMeters: 1800.0,
        hazardScore: objective == RoutingObjective.safest ? 0.08 : 0.42,
        iconType: "turn_slight_right",
      ),
      StepInstruction(
        instruction: vehicle.excludeSpeedBumps
            ? "Rerouted around 3 speed bumps (Supercar constraint active)"
            : "Continue straight past Worli Naka Junction",
        roadName: "Dr. Annie Besant Road",
        distanceMeters: 2200.0,
        hazardScore: 0.18,
        iconType: "arrow_upward",
      ),
      StepInstruction(
        instruction: "Arrive at $destName",
        roadName: "Destination Gate",
        distanceMeters: 150.0,
        hazardScore: 0.05,
        iconType: "place",
      ),
    ];
  }

  List<HazardSegment> _generateEncounteredHazards(List<LatLng> path) {
    if (path.length < 5) return [];
    return [
      HazardSegment(
        segmentId: "OSM-889412",
        roadName: "Kurla West Connector",
        coordinates: [path[3], path[4]],
        hazardScore: 0.84,
        conditionTier: "severe",
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        ttlSeconds: 4320, // 1h 12m remaining
      ),
      HazardSegment(
        segmentId: "OSM-441209",
        roadName: "Sion Circle Underpass",
        coordinates: [path[7], path[8]],
        hazardScore: 0.58,
        conditionTier: "rough",
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ttlSeconds: 5700,
      ),
    ];
  }
}
