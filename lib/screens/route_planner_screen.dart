import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../models/vehicle_profile.dart';
import '../services/routing_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/map_canvas_widget.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final RoutingEngineService _routingService = RoutingEngineService();

  RouteLocation _selectedOrigin = RoutingEngineService.mumbaiHotspots[0]; // Kalawad Road
  RouteLocation _selectedDestination = RoutingEngineService.mumbaiHotspots[1]; // 150 Ft Ring Road
  VehicleProfile _selectedVehicle = VehicleProfile.profiles[0]; // Car
  RoutingObjective _selectedObjective = RoutingObjective.fastest;

  RouteResult? _computedRoute;
  bool _isComputing = false;

  final TextEditingController _originController = TextEditingController(text: "");
  final TextEditingController _destController = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    _triggerRouteCalculation();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
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
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Card matching navigation-1/navigation-2 mockups
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.obsidianCard : const Color(0xFFE2E8F0).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? AppColors.borderSubtle : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.obsidianSurface : const Color(0xFF94A3B8),
                        border: Border.all(color: AppColors.cyberCyan, width: 1.5),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    Text(
                      "Argus",
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 44), // Spacer for center alignment
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Full Map Canvas View Container
              SizedBox(
                height: 220,
                child: MapCanvasWidget(
                  activeRoute: _computedRoute,
                  hazardSegments: _computedRoute?.encounteredHazards ?? [],
                  currentVehiclePosition: _selectedOrigin.position,
                ),
              ),
              const SizedBox(height: 24), // Extra Spacing Above the Green Box

              // Plan Route Sheet Container (Sage/Olive Green from navigation-1/2 mockups)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF8A9A65),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header
                    Row(
                      children: const [
                        Icon(Icons.navigation_outlined, color: Color(0xFF0F172A), size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Plan Route",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.extrabold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Origin & Destination Input Card with Dashed Connecting Line
                    Stack(
                      children: [
                        Column(
                          children: [
                            // Origin Field (Blank Placeholder)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B37F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF94A36F)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F172A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _originController,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: "Choose starting point...",
                                        hintStyle: TextStyle(color: Color(0x990F172A)),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _originController.clear(),
                                    child: const Icon(Icons.close, color: Color(0xFF334155), size: 18),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Destination Field (Blank Placeholder)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4B37F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF94A36F)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _destController,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: "Choose destination...",
                                        hintStyle: TextStyle(color: Color(0x990F172A)),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _destController.clear(),
                                    child: const Icon(Icons.close, color: Color(0xFF334155), size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // VEHICLE Section Label
                    const Text(
                      "VEHICLE",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 10,
                        fontWeight: FontWeight.extrabold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 4 Vehicle Selector Chips (Bike, Car, Truck, Supercar)
                    Row(
                      children: [
                        _buildVehicleChip(
                          icon: Icons.directions_bike,
                          label: "Bike",
                          isSelected: _selectedVehicle.type == VehicleType.bike,
                          onTap: () {
                            setState(() => _selectedVehicle = VehicleProfile.profiles[1]);
                            _triggerRouteCalculation();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildVehicleChip(
                          icon: Icons.directions_car,
                          label: "Car",
                          isSelected: _selectedVehicle.type == VehicleType.car,
                          onTap: () {
                            setState(() => _selectedVehicle = VehicleProfile.profiles[0]);
                            _triggerRouteCalculation();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildVehicleChip(
                          icon: Icons.local_shipping,
                          label: "Truck",
                          isSelected: _selectedVehicle.type == VehicleType.truck,
                          onTap: () {
                            setState(() => _selectedVehicle = VehicleProfile.profiles[2]);
                            _triggerRouteCalculation();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildVehicleChip(
                          icon: Icons.bolt,
                          label: "Supercar",
                          isSelected: _selectedVehicle.type == VehicleType.supercar,
                          onTap: () {
                            setState(() => _selectedVehicle = VehicleProfile.profiles[3]);
                            _triggerRouteCalculation();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ROUTE TYPE Section Label
                    const Text(
                      "ROUTE TYPE",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 10,
                        fontWeight: FontWeight.extrabold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 4 Objective Buttons (Fastest [active yellow], Safest, Straightest, Popular)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildObjectiveChip(
                                icon: Icons.bolt,
                                label: "Fastest",
                                isSelected: _selectedObjective == RoutingObjective.fastest,
                                onTap: () {
                                  setState(() => _selectedObjective = RoutingObjective.fastest);
                                  _triggerRouteCalculation();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildObjectiveChip(
                                icon: Icons.shield_outlined,
                                label: "Safest",
                                isSelected: _selectedObjective == RoutingObjective.safest,
                                onTap: () {
                                  setState(() => _selectedObjective = RoutingObjective.safest);
                                  _triggerRouteCalculation();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildObjectiveChip(
                                icon: Icons.arrow_forward,
                                label: "Straightest",
                                isSelected: _selectedObjective == RoutingObjective.straightest,
                                onTap: () {
                                  setState(() => _selectedObjective = RoutingObjective.straightest);
                                  _triggerRouteCalculation();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildObjectiveChip(
                                icon: Icons.star_border,
                                label: "Popular",
                                isSelected: _selectedObjective == RoutingObjective.popular,
                                onTap: () {
                                  setState(() => _selectedObjective = RoutingObjective.popular);
                                  _triggerRouteCalculation();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Route Metrics (DURATION, DISTANCE, SAFETY) from navigation-2 mockup
                    if (_computedRoute != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB4C38F),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF94A36F)),
                        ),
                        child: Row(
                          mainAxisAlignment: SpaceAround,
                          children: [
                            _buildMetricItem(
                              value: "${_computedRoute!.estimatedTimeMinutes}m",
                              label: "DURATION",
                            ),
                            _buildMetricItem(
                              value: "${_computedRoute!.totalDistanceKm.toStringAsFixed(1)} km",
                              label: "DISTANCE",
                            ),
                            _buildMetricItem(
                              value: "${((1.0 - _computedRoute!.compositeHazardScore) * 100).toInt()}%",
                              label: "SAFETY",
                              valueColor: const Color(0xFF166534),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Prominent Start Navigation Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Navigation started on Rajkot spatial route network!"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text(
                          "Start Navigation",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFB4C38F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A36F),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFACC15) : const Color(0xFFB4C38F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFEAB308) : const Color(0xFF94A36F),
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x33FACC15), blurRadius: 8, offset: Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF0F172A),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.extrabold : FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.extrabold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 9,
            fontWeight: FontWeight.extrabold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
