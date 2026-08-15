import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/iot_telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/waveform_painter.dart';

class IoTHeatmapScreen extends StatefulWidget {
  const IoTHeatmapScreen({super.key});

  @override
  State<IoTHeatmapScreen> createState() => _IoTHeatmapScreenState();
}

class _IoTHeatmapScreenState extends State<IoTHeatmapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IoTTelemetryService>(context, listen: false).startTelemetryStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final iotService = Provider.of<IoTTelemetryService>(context);
    final reading = iotService.currentReading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "IOT TELEMETRY INGESTION",
                        style: TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Real-Time Hazard Pipeline",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.hazardRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.hazardRed.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.hazardRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "WEBSOCKET FEED",
                          style: TextStyle(
                            color: AppColors.hazardRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Accelerometer Waveform Chart Card
              CyberCard(
                borderColor: AppColors.borderGlow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "3-AXIS ACCELEROMETER WAVEFORM",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Row(
                          children: [
                            _buildLegendItem("Acc X", AppColors.cyberCyan),
                            const SizedBox(width: 8),
                            _buildLegendItem("Acc Y", AppColors.hazardYellow),
                            const SizedBox(width: 8),
                            _buildLegendItem("Acc Z", AppColors.hazardRed),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: WaveformPainter(history: iotService.readingHistory),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricTile("Vibration Mag", "${reading.vibrationMagnitude} G", AppColors.cyberCyan),
                        _buildMetricTile("Vert Accel Z", "${reading.accelZ} m/s²", AppColors.hazardRed),
                        _buildMetricTile("Current Speed", "${reading.currentSpeedKmh} kmh", AppColors.cyberPurple),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // PostGIS Spatial Segment Snapper Status
              CyberCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.obsidianSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Icon(Icons.hub, color: AppColors.cyberCyan, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PostGIS Spatial Snapping (ST_DWithin)",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Segment: ${reading.snappedSegmentId} • Tier: ${reading.conditionTier.toUpperCase()}",
                            style: TextStyle(
                              color: reading.conditionTier == "severe"
                                  ? AppColors.hazardRed
                                  : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live Hazard WebSocket Alert Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "LIVE HAZARD ALERTS (2-HOUR TTL AUTO-EXPIRY)",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    "${iotService.liveHazardAlerts.length} ACTIVE",
                    style: const TextStyle(
                      color: AppColors.cyberCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...iotService.liveHazardAlerts.map((alert) {
                final String remainingTtl =
                    "${alert.timeToLive.inHours}h ${alert.timeToLive.inMinutes.remainder(60)}m";
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CyberCard(
                    borderColor: alert.conditionTier == "severe"
                        ? AppColors.hazardRed.withOpacity(0.5)
                        : AppColors.borderSubtle,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: alert.conditionTier == "severe"
                                ? AppColors.hazardRed.withOpacity(0.2)
                                : AppColors.hazardOrange.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber,
                            color: alert.conditionTier == "severe"
                                ? AppColors.hazardRed
                                : AppColors.hazardOrange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.segmentName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Peak Vibration: ${alert.peakVibrationG} G • Score: ${alert.hazardScore}",
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.obsidianSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alert.conditionTier.toUpperCase(),
                                style: TextStyle(
                                  color: alert.conditionTier == "severe"
                                      ? AppColors.hazardRed
                                      : AppColors.hazardOrange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "TTL: $remainingTtl",
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
