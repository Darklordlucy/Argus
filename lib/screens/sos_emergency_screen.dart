import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/cyber_card.dart';

class SOSEmergencyScreen extends StatefulWidget {
  const SOSEmergencyScreen({super.key});

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen> {
  bool _sosActive = false;
  bool _hospitalNotified = false;

  void _triggerCrashSimulation() {
    setState(() {
      _sosActive = true;
      _hospitalNotified = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _hospitalNotified = true);
      }
    });
  }

  void _cancelSOS() {
    setState(() {
      _sosActive = false;
      _hospitalNotified = false;
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
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SOS EMERGENCY SYSTEM",
                        style: TextStyle(
                          color: AppColors.hazardRed,
                          fontSize: 11,
                          fontWeight: FontWeight.extrabold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Accident & G-Force Detection",
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
                      color: AppColors.hazardRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.hazardRed),
                    ),
                    child: const Text(
                      "POSTGIS GEOFENCED",
                      style: TextStyle(
                        color: AppColors.hazardRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // SOS Trigger Big Button
              Center(
                child: GestureDetector(
                  onTap: _triggerCrashSimulation,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _sosActive ? AppColors.hazardRed : (isDark ? AppColors.obsidianCard : Colors.white),
                      border: Border.all(
                        color: _sosActive ? Colors.white : AppColors.hazardRed,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.hazardRed.withOpacity(_sosActive ? 0.6 : 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emergency,
                          color: _sosActive ? Colors.white : AppColors.hazardRed,
                          size: 50,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sosActive ? "SOS ACTIVE" : "SIMULATE CRASH",
                          style: TextStyle(
                            color: _sosActive ? Colors.white : primaryTextColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_sosActive) ...[
                CyberCard(
                  borderColor: AppColors.hazardRed,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sensors, color: AppColors.hazardRed, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Gyroscope High G-Force Threshold Triggered (>4.2G Spike)",
                              style: TextStyle(
                                color: AppColors.hazardRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 8),

                      if (_hospitalNotified) ...[
                        const Row(
                          children: [
                            Icon(Icons.local_hospital, color: AppColors.hazardGreen, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Emergency Dispatch: Synergy Hospital (Rajkot, 150 Ft Ring Rd) notified via PostGIS ST_DWithin (1.2 km away)",
                                style: TextStyle(
                                  color: AppColors.hazardGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.hazardRed),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Broadcasting location to nearest hospital emergency node in Rajkot...",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      TextButton(
                        onPressed: _cancelSOS,
                        child: const Text(
                          "CANCEL EMERGENCY DISPATCH",
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                CyberCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AUTOMATIC ACCIDENT DISPATCH PROTOCOL",
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "1. IoT Telemetry continuously monitors 3-axis accelerometer and gyroscope yaw rate.\n2. When vibration spike exceeds 4.0G impact threshold, an SOS alert is stored in the database with coordinates.\n3. PostGIS ST_DWithin spatial query identifies the nearest emergency hospital node in Rajkot (Gujarat) and dispatches live telemetry payload.",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
