import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/iot_telemetry.dart';

class IoTTelemetryService extends ChangeNotifier {
  final Random _random = Random();
  Timer? _telemetryTimer;

  // Stream state for Rajkot sensor feeds
  IoTReading _currentReading = IoTReading(
    timestamp: DateTime.now(),
    location: const LatLng(22.2854, 70.7725),
    accelX: 0.12,
    accelY: 0.08,
    accelZ: 9.84,
    vibrationMagnitude: 0.15,
    gyroZ: 0.02,
    currentSpeedKmh: 48.5,
    snappedSegmentId: "RJT-882014",
    conditionTier: "smooth",
  );

  final List<IoTReading> _readingHistory = [];
  final List<HazardAlertEvent> _liveHazardAlerts = [
    HazardAlertEvent(
      alertId: "ALT-7891",
      segmentName: "150 Feet Ring Road (KKV Circle)",
      position: const LatLng(22.2921, 70.7834),
      hazardScore: 0.88,
      conditionTier: "severe",
      peakVibrationG: 3.42,
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      timeToLive: const Duration(hours: 1, minutes: 52),
    ),
    HazardAlertEvent(
      alertId: "ALT-4402",
      segmentName: "Kalawad Road (Crystal Mall Junction)",
      position: const LatLng(22.2854, 70.7725),
      hazardScore: 0.65,
      conditionTier: "rough",
      peakVibrationG: 2.15,
      timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
      timeToLive: const Duration(hours: 1, minutes: 38),
    ),
  ];

  IoTReading get currentReading => _currentReading;
  List<IoTReading> get readingHistory => List.unmodifiable(_readingHistory);
  List<HazardAlertEvent> get liveHazardAlerts => List.unmodifiable(_liveHazardAlerts);

  void startTelemetryStream() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _generateNextReading();
    });
  }

  void stopTelemetryStream() {
    _telemetryTimer?.cancel();
  }

  void _generateNextReading() {
    final now = DateTime.now();

    final bool isHazardBump = _random.nextDouble() < 0.12;

    final double baseNoiseX = (_random.nextDouble() - 0.5) * 0.4;
    final double baseNoiseY = (_random.nextDouble() - 0.5) * 0.4;
    double accelZ = 9.81 + (_random.nextDouble() - 0.5) * 0.5;

    if (isHazardBump) {
      accelZ += (_random.nextDouble() * 3.5 + 1.2);
    }

    final double vibMag = sqrt(pow(baseNoiseX, 2) + pow(baseNoiseY, 2) + pow(accelZ - 9.81, 2));

    String tier = "smooth";
    if (vibMag > 2.8) {
      tier = "severe";
    } else if (vibMag > 1.8) {
      tier = "rough";
    } else if (vibMag > 0.9) {
      tier = "moderate";
    }

    _currentReading = IoTReading(
      timestamp: now,
      location: LatLng(
        22.2854 + (_random.nextDouble() - 0.5) * 0.005,
        70.7725 + (_random.nextDouble() - 0.5) * 0.005,
      ),
      accelX: double.parse(baseNoiseX.toStringAsFixed(3)),
      accelY: double.parse(baseNoiseY.toStringAsFixed(3)),
      accelZ: double.parse(accelZ.toStringAsFixed(3)),
      vibrationMagnitude: double.parse(vibMag.toStringAsFixed(3)),
      gyroZ: double.parse(((_random.nextDouble() - 0.5) * 0.1).toStringAsFixed(3)),
      currentSpeedKmh: double.parse((45.0 + (_random.nextDouble() - 0.5) * 6.0).toStringAsFixed(1)),
      snappedSegmentId: "RJT-${(_random.nextInt(900000) + 100000)}",
      conditionTier: tier,
    );

    _readingHistory.add(_currentReading);
    if (_readingHistory.length > 50) {
      _readingHistory.removeAt(0);
    }

    if (isHazardBump && vibMag > 2.5) {
      _broadcastHazardAlert(_currentReading);
    }

    notifyListeners();
  }

  void _broadcastHazardAlert(IoTReading reading) {
    final alert = HazardAlertEvent(
      alertId: "ALT-${_random.nextInt(9000) + 1000}",
      segmentName: "Rajkot Segment ${reading.snappedSegmentId}",
      position: reading.location,
      hazardScore: double.parse((reading.vibrationMagnitude / 4.0).clamp(0.4, 1.0).toStringAsFixed(2)),
      conditionTier: reading.conditionTier,
      peakVibrationG: reading.vibrationMagnitude,
      timestamp: DateTime.now(),
      timeToLive: const Duration(hours: 2),
    );

    _liveHazardAlerts.insert(0, alert);
    if (_liveHazardAlerts.length > 10) {
      _liveHazardAlerts.removeLast();
    }
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
