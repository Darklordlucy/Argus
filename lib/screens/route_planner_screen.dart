import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/vehicle_profile.dart';
import '../services/routing_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/map_canvas_widget.dart';
import '../widgets/telemetry_gauge.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final RoutingEngineService _routingService = RoutingEngineService();

  RouteLocation _selectedOrigin = RoutingEngineService.mumbaiHotspots[0]; // BKC
  RouteLocation _selectedDestination = RoutingEngineService.mumbaiHotspots[1]; // Worli
  VehicleProfile _selectedVehicle = VehicleProfile.profiles[0]; // Standard Car
  RoutingObjective _selectedObjective = RoutingObjective.fastest;

  RouteResult? _computedRoute;
  bool _isComputing = false;

  @override
  void initState() {
    super.initState();
    _triggerRouteCalculation();
  }

  Future<void> _triggerRouteCalculation() async {
    setState(() => _isComputing = true);
    final result = await _routingService.computeRoute(
      origin: _selectedOrigin,
      destination: _selectedDestination,
      objective: _selectedObjective,
      vehicle: _selectedVehicle,
    );
    setState(() {
      _computedRoute = result;
      _isComputing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.obsidianCard : AppColors.cardSubtle;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Live Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ASPHR ENGINE",
                        style: TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.extrabold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Hazard Router",
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cyberCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cyberCyan.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "LIVE DB SYNC",
                      style: TextStyle(
                        color: AppColors.cyberCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Interactive Map View optimized for mobile screen
              SizedBox(
                height: 220,
                child: MapCanvasWidget(
                  activeRoute: _computedRoute,
                  hazardSegments: _computedRoute?.encounteredHazards ?? [],
                  currentVehiclePosition: _selectedOrigin.position,
                ),
              ),
              const SizedBox(height: 14),

              // Vehicle Constraint Selector Chips
              Text(
                "VEHICLE CONSTRAINT PROFILE",
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: VehicleProfile.profiles.map((profile) {
                    final bool isSelected = profile.type == _selectedVehicle.type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(profile.name),
                        selected: isSelected,
                        selectedColor: AppColors.cyberCyan,
                        backgroundColor: cardBg,
                        side: BorderSide(
                          color: isSelected ? AppColors.cyberCyan : AppColors.borderSubtle,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : primaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedVehicle = profile);
                            _triggerRouteCalculation();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Multi-Objective Strategy Buttons
              Text(
                "ROUTING OBJECTIVE FORMULA",
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: RoutingObjective.values.map((obj) {
                  final bool isSelected = obj == _selectedObjective;
                  String label = obj.name.toUpperCase();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          backgroundColor: isSelected ? AppColors.cyberCyan : cardBg,
                          foregroundColor: isSelected ? Colors.white : primaryTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.cyberCyan : AppColors.borderSubtle,
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          setState(() => _selectedObjective = obj);
                          _triggerRouteCalculation();
                        },
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Route Metrics & Telemetry Breakdown Card
              if (_isComputing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.cyberCyan),
                  ),
                )
              else if (_computedRoute != null) ...[
                CyberCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TelemetryGauge(
                            value: 1.0 - (_computedRoute!.compositeHazardScore),
                            label: "Safety Rating",
                            displayValue: "${((1.0 - _computedRoute!.compositeHazardScore) * 100).toInt()}%",
                            activeColor: _computedRoute!.compositeHazardScore < 0.35
                                ? AppColors.hazardGreen
                                : AppColors.hazardOrange,
                          ),
                          TelemetryGauge(
                            value: (_computedRoute!.estimatedTimeMinutes / 45.0).clamp(0.0, 1.0),
                            label: "Est Time",
                            displayValue: "${_computedRoute!.estimatedTimeMinutes}m",
                            activeColor: AppColors.cyberCyan,
                          ),
                          TelemetryGauge(
                            value: (_computedRoute!.predictedSpeedLstmKmh / 60.0).clamp(0.0, 1.0),
                            label: "LSTM Speed",
                            displayValue: "${_computedRoute!.predictedSpeedLstmKmh} kmh",
                            activeColor: AppColors.cyberPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.borderSubtle, height: 1),
                      const SizedBox(height: 10),

                      // Weather Alert Banner
                      Row(
                        children: [
                          const Icon(Icons.thunderstorm, color: AppColors.hazardYellow, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _computedRoute!.weatherAlertText,
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondary : AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.published_with_changes, color: AppColors.cyberCyan, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Avoided ${_computedRoute!.totalSpeedBumpsAvoided} speed bumps & severe hazard segments.",
                              style: const TextStyle(
                                color: AppColors.cyberCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Turn-by-Turn Guidance Steps
                Text(
                  "HAZARD-ENRICHED MANEUVER STEPS",
                  style: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ..._computedRoute!.instructions.map((step) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CyberCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.obsidianSurface : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getStepIcon(step.iconType),
                              color: AppColors.cyberCyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.instruction,
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${step.roadName} • ${step.distanceMeters.toInt()}m",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: step.hazardScore > 0.3
                                  ? AppColors.hazardRed.withOpacity(0.15)
                                  : AppColors.hazardGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Hazard: ${(step.hazardScore * 100).toInt()}%",
                              style: TextStyle(
                                color: step.hazardScore > 0.3
                                    ? AppColors.hazardRed
                                    : AppColors.hazardGreen,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStepIcon(String iconType) {
    switch (iconType) {
      case "turn_slight_right":
        return Icons.turn_slight_right;
      case "place":
        return Icons.place;
      default:
        return Icons.arrow_upward;
    }
  }
}
