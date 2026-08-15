import 'dart:math';
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF0A0E18),
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: _MumbaiMapPainter(
                route: activeRoute,
                hazards: hazardSegments,
                vehiclePos: currentVehiclePosition,
              ),
            ),
            // Map Telemetry Overlay Pill
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.obsidianCard.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGlow.withOpacity(0.4)),
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
                    const SizedBox(width: 8),
                    const Text(
                      "MUMBAI ROAD NETWORK • 85k+ OSM NODES",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
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

  _MumbaiMapPainter({
    required this.route,
    required this.hazards,
    required this.vehiclePos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Draw Cyber Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF161F33)
      ..strokeWidth = 0.8;

    const gridStep = 40.0;
    for (double x = 0; x < width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Coordinates bounding box for Mumbai (approx lat 18.9 to 19.15, lng 72.8 to 72.9)
    Offset toCanvasOffset(LatLng pos) {
      final double normalizedX = (pos.longitude - 72.80) / 0.12;
      final double normalizedY = 1.0 - ((pos.latitude - 18.92) / 0.20);
      return Offset(
        (normalizedX * width).clamp(20.0, width - 20.0),
        (normalizedY * height).clamp(20.0, height - 20.0),
      );
    }

    // Draw Static Mumbai Road Graph Network
    final roadPaint = Paint()
      ..color = const Color(0xFF1C273D)
      ..strokeWidth = 2.5
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

    // Draw Hazard Heatmap Overlay (Color Ramped: Green -> Yellow -> Orange -> Red)
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
          ..color = hazardColor.withOpacity(0.85)
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(p1, p2, hazardPaint);
      }
    }

    // Draw Active Calculated Route Polyline with Neon Glow
    if (route != null && route!.polylinePoints.length >= 2) {
      final glowPaint = Paint()
        ..color = AppColors.cyberCyan.withOpacity(0.35)
        ..strokeWidth = 10.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final routePaint = Paint()
        ..color = AppColors.cyberCyan
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

      // Draw Start & Destination Pin Markers
      final startPt = toCanvasOffset(route!.polylinePoints.first);
      final endPt = toCanvasOffset(route!.polylinePoints.last);

      canvas.drawCircle(startPt, 8.0, Paint()..color = AppColors.hazardGreen);
      canvas.drawCircle(endPt, 8.0, Paint()..color = AppColors.cyberPurple);
    }

    // Draw Live Vehicle Location Marker with Pulse Wave
    final vehiclePt = toCanvasOffset(vehiclePos);
    final pulsePaint = Paint()
      ..color = AppColors.cyberCyan.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final vehiclePaint = Paint()..color = AppColors.cyberCyan;

    canvas.drawCircle(vehiclePt, 16.0, pulsePaint);
    canvas.drawCircle(vehiclePt, 6.0, vehiclePaint);
  }

  @override
  bool shouldRepaint(covariant _MumbaiMapPainter oldDelegate) => true;
}
