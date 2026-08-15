import 'package:flutter/material.dart';
import '../models/iot_telemetry.dart';
import '../theme/app_theme.dart';

class WaveformPainter extends CustomPainter {
  final List<IoTReading> history;

  WaveformPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double stepX = width / 49; // Up to 50 samples

    // Paints
    final paintX = Paint()
      ..color = AppColors.cyberCyan
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final paintY = Paint()
      ..color = AppColors.hazardYellow
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final paintZ = Paint()
      ..color = AppColors.hazardRed
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final pathX = Path();
    final pathY = Path();
    final pathZ = Path();

    final double midY = height / 2;

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final reading = history[i];

      // Map values (-4G to +4G or vertical accel)
      final yX = midY - (reading.accelX * 12.0);
      final yY = midY - (reading.accelY * 12.0);
      final yZ = midY - ((reading.accelZ - 9.81) * 12.0);

      if (i == 0) {
        pathX.moveTo(x, yX.clamp(4.0, height - 4.0));
        pathY.moveTo(x, yY.clamp(4.0, height - 4.0));
        pathZ.moveTo(x, yZ.clamp(4.0, height - 4.0));
      } else {
        pathX.lineTo(x, yX.clamp(4.0, height - 4.0));
        pathY.lineTo(x, yY.clamp(4.0, height - 4.0));
        pathZ.lineTo(x, yZ.clamp(4.0, height - 4.0));
      }
    }

    // Grid center baseline
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(width, midY), gridPaint);

    // Draw waveform paths
    canvas.drawPath(pathX, paintX);
    canvas.drawPath(pathY, paintY);
    canvas.drawPath(pathZ, paintZ);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
