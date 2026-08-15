import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TelemetryGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final String displayValue;
  final Color activeColor;

  const TelemetryGauge({
    super.key,
    required this.value,
    required this.label,
    required this.displayValue,
    this.activeColor = AppColors.cyberCyan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: CustomPaint(
            painter: _GaugePainter(
              value: value.clamp(0.0, 1.0),
              activeColor: activeColor,
              isDark: isDark,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayValue,
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final bool isDark;

  _GaugePainter({required this.value, required this.activeColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    final backgroundPaint = Paint()
      ..color = isDark ? AppColors.obsidianSurface : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    const startAngle = 0.75 * pi; // 135 deg
    const sweepAngle = 1.5 * pi;  // 270 deg arc

    // Draw background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw active arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.activeColor != activeColor || oldDelegate.isDark != isDark;
}
