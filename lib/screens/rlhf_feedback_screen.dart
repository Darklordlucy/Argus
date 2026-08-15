import 'package:flutter/material.dart';
import '../models/iot_telemetry.dart';
import '../theme/app_theme.dart';
import '../widgets/cyber_card.dart';

class RLHFFeedbackScreen extends StatefulWidget {
  const RLHFFeedbackScreen({super.key});

  @override
  State<RLHFFeedbackScreen> createState() => _RLHFFeedbackScreenState();
}

class _RLHFFeedbackScreenState extends State<RLHFFeedbackScreen> {
  int _hazardAccuracy = 5;
  int _rideComfort = 4;
  bool _unmappedHazard = false;
  int _routeEfficiency = 5;
  int _overallRating = 5;

  bool _submitted = false;

  void _submitFeedback() {
    setState(() => _submitted = true);
    final payload = RLHFFeedbackPayload(
      routeId: "ASPHR-884920",
      hazardAccuracyRating: _hazardAccuracy,
      rideComfortRating: _rideComfort,
      encounteredUnmappedHazard: _unmappedHazard,
      routeEfficiencyRating: _routeEfficiency,
      overallRecommendation: _overallRating,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cyberCyan,
        content: Text(
          "Spatial RLHF feedback logged for ${payload.routeId}! Retraining loop active.",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
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
                        "RLHF FEEDBACK LOOP",
                        style: TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.extrabold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Spatial Feedback",
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
                      color: AppColors.hazardGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.hazardGreen.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "SELF-IMPROVING DB",
                      style: TextStyle(
                        color: AppColors.hazardGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_submitted) ...[
                CyberCard(
                  borderColor: AppColors.hazardGreen,
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.hazardGreen, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        "Feedback Successfully Fused!",
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Your post-journey spatial ratings have been appended to the model fine-tuning database.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cyberCyan,
                          side: const BorderSide(color: AppColors.cyberCyan),
                        ),
                        onPressed: () => setState(() => _submitted = false),
                        child: const Text("Submit Another Rating"),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Dimension 1: Hazard Accuracy
                _buildRatingDimension(
                  "1. Hazard Accuracy",
                  "Did mapped hazards reflect actual road condition?",
                  _hazardAccuracy,
                  (v) => setState(() => _hazardAccuracy = v),
                  primaryTextColor,
                ),
                const SizedBox(height: 10),

                // Dimension 2: Ride Comfort
                _buildRatingDimension(
                  "2. Ride Comfort",
                  "Pavement smoothness and suspension comfort level",
                  _rideComfort,
                  (v) => setState(() => _rideComfort = v),
                  primaryTextColor,
                ),
                const SizedBox(height: 10),

                // Dimension 3: Unmapped Hazard Encountered
                CyberCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "3. Unmapped Hazard Encountered?",
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Did you hit any unmapped crater or bump?",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _unmappedHazard,
                        activeColor: AppColors.hazardRed,
                        onChanged: (val) => setState(() => _unmappedHazard = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Dimension 4: Route Efficiency
                _buildRatingDimension(
                  "4. Route Efficiency",
                  "Did the engine avoid unnecessary detours?",
                  _routeEfficiency,
                  (v) => setState(() => _routeEfficiency = v),
                  primaryTextColor,
                ),
                const SizedBox(height: 10),

                // Dimension 5: Overall Recommendation
                _buildRatingDimension(
                  "5. Overall Recommendation",
                  "Likelihood of recommending Asphr route engine",
                  _overallRating,
                  (v) => setState(() => _overallRating = v),
                  primaryTextColor,
                ),
                const SizedBox(height: 18),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyberCyan,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitFeedback,
                    child: const Text(
                      "LOG SPATIAL FEEDBACK PAYLOAD",
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingDimension(
    String title,
    String subtitle,
    int currentValue,
    ValueChanged<int> onChanged,
    Color textColor,
  ) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final starVal = index + 1;
              final bool active = starVal <= currentValue;
              return IconButton(
                onPressed: () => onChanged(starVal),
                icon: Icon(
                  active ? Icons.star : Icons.star_border,
                  color: active ? AppColors.hazardYellow : AppColors.textMuted,
                  size: 26,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
