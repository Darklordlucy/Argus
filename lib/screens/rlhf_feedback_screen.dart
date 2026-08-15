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
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        "RLHF FEEDBACK LOOP",
                        style: TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "5-Dimension Spatial Feedback",
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
                      color: AppColors.hazardGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.hazardGreen.withOpacity(0.4)),
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
              const SizedBox(height: 16),

              if (_submitted) ...[
                CyberCard(
                  borderColor: AppColors.hazardGreen,
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.hazardGreen, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        "Feedback Successfully Fused!",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Your post-journey spatial ratings have been appended to the model fine-tuning database.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                ),
                const SizedBox(height: 12),

                // Dimension 2: Ride Comfort
                _buildRatingDimension(
                  "2. Ride Comfort",
                  "Pavement smoothness and suspension comfort level",
                  _rideComfort,
                  (v) => setState(() => _rideComfort = v),
                ),
                const SizedBox(height: 12),

                // Dimension 3: Unmapped Hazard Encountered
                CyberCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "3. Unmapped Hazard Encountered?",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Did you hit any unmapped crater or speed bump?",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      Switch(
                        value: _unmappedHazard,
                        activeColor: AppColors.hazardRed,
                        onChanged: (val) => setState(() => _unmappedHazard = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Dimension 4: Route Efficiency
                _buildRatingDimension(
                  "4. Route Efficiency",
                  "Did the engine avoid unnecessary detours?",
                  _routeEfficiency,
                  (v) => setState(() => _routeEfficiency = v),
                ),
                const SizedBox(height: 12),

                // Dimension 5: Overall Recommendation
                _buildRatingDimension(
                  "5. Overall Recommendation",
                  "Likelihood of recommending Asphr route engine",
                  _overallRating,
                  (v) => setState(() => _overallRating = v),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyberCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitFeedback,
                    child: const Text(
                      "LOG SPATIAL FEEDBACK PAYLOAD",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
  ) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
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
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
