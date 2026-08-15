import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../theme/app_theme.dart';

class MapCanvasWidget extends StatelessWidget {
  final RouteResult? activeRoute;
  final List<HazardSegment> hazardSegments;
  final LatLng currentVehiclePosition;

  const MapCanvasWidget({
    super.key,
    this.activeRoute,
    required this.hazardSegments,
    required this.currentVehiclePosition,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: isDark ? const Color(0xFF0A0E18) : const Color(0xFFF1F5F9),
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: _MumbaiMapPainter(
                route: activeRoute,
                hazards: hazardSegments,
                vehiclePos: currentVehiclePosition,
                isDark: isDark,
              ),
            ),
            // Map Telemetry Overlay Pill
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.obsidianCard : Colors.white).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.borderGlow.withOpacity(0.4) : AppColors.borderSubtle),
                  boxShadow: [
                    if (!isDark)
                      const BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.hazardGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "MUMBAI ROAD NETWORK • 85k+ NODES",
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MumbaiMapPainter extends CustomPainter {
  final RouteResult? route;
  final List<HazardSegment> hazards;
  final LatLng vehiclePos;
  final bool isDark;

  _MumbaiMapPainter({
    required this.route,
    required this.hazards,
    required this.vehiclePos,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Grid Lines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF161F33) : const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    const gridStep = 32.0;
    for (double x = 0; x < width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Coordinates bounding box for Mumbai
    Offset toCanvasOffset(LatLng pos) {
      final double normalizedX = (pos.longitude - 72.80) / 0.12;
      final double normalizedY = 1.0 - ((pos.latitude - 18.92) / 0.20);
      return Offset(
        (normalizedX * width).clamp(16.0, width - 16.0),
        (normalizedY * height).clamp(16.0, height - 16.0),
      );
    }

    // Static Mumbai Road Graph Network
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1C273D) : const Color(0xFFCBD5E1)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final staticRoads = [
      [const LatLng(19.0657, 72.8686), const LatLng(19.0330, 72.8185)], // BKC to Worli
      [const LatLng(19.0330, 72.8185), const LatLng(18.9438, 72.8232)], // Worli to Marine Drive
      [const LatLng(19.0657, 72.8686), const LatLng(19.0896, 72.8656)], // BKC to Airport
      [const LatLng(19.0822, 72.8519), const LatLng(19.0657, 72.8686)], // WEH to BKC
    ];

    for (var road in staticRoads) {
      final p1 = toCanvasOffset(road[0]);
      final p2 = toCanvasOffset(road[1]);
      canvas.drawLine(p1, p2, roadPaint);
    }

    // Hazard Segments Overlay
    for (var hazard in hazards) {
      if (hazard.coordinates.length >= 2) {
        final p1 = toCanvasOffset(hazard.coordinates[0]);
        final p2 = toCanvasOffset(hazard.coordinates[1]);

        Color hazardColor = AppColors.hazardYellow;
        if (hazard.hazardScore > 0.75) {
          hazardColor = AppColors.hazardRed;
        } else if (hazard.hazardScore > 0.50) {
          hazardColor = AppColors.hazardOrange;
        }

        final hazardPaint = Paint()
          ..color = hazardColor.withOpacity(0.9)
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(p1, p2, hazardPaint);
      }
    }

    // Active Calculated Route Polyline
    if (route != null && route!.polylinePoints.length >= 2) {
      final routeColor = isDark ? AppColors.cyberCyan : const Color(0xFF0284C7);
      
      final glowPaint = Paint()
        ..color = routeColor.withOpacity(0.3)
        ..strokeWidth = 10.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final routePaint = Paint()
        ..color = routeColor
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int i = 0; i < route!.polylinePoints.length; i++) {
        final pt = toCanvasOffset(route!.polylinePoints[i]);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, routePaint);

      // Start & Destination Pin Markers
      final startPt = toCanvasOffset(route!.polylinePoints.first);
      final endPt = toCanvasOffset(route!.polylinePoints.last);

      canvas.drawCircle(startPt, 7.0, Paint()..color = AppColors.hazardGreen);
      canvas.drawCircle(endPt, 7.0, Paint()..color = AppColors.cyberPurple);
    }

    // Live Vehicle Location Marker
    final vehiclePt = toCanvasOffset(vehiclePos);
    final vehicleColor = isDark ? AppColors.cyberCyan : const Color(0xFF0284C7);
    final pulsePaint = Paint()
      ..color = vehicleColor.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final vehiclePaint = Paint()..color = vehicleColor;

    canvas.drawCircle(vehiclePt, 14.0, pulsePaint);
    canvas.drawCircle(vehiclePt, 6.0, vehiclePaint);
  }

  @override
  bool shouldRepaint(covariant _MumbaiMapPainter oldDelegate) => true;
}
