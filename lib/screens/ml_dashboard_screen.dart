import 'package:flutter/material.dart';
import '../services/ml_inference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cyber_card.dart';

class MLDashboardScreen extends StatelessWidget {
  const MLDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mlService = MLInferenceService();
    final lstmSequence = mlService.getLstmTrafficSequence();
    final gbmFeatures = mlService.getGbmFeatureVectors();
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
                        "MACHINE LEARNING INFERENCE",
                        style: TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.extrabold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Dual Model Architecture",
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
                      color: AppColors.cyberPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cyberPurple.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "v2.4.1 MODEL",
                      style: TextStyle(
                        color: AppColors.cyberPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // PyTorch LSTM Speed Forecaster Card
              CyberCard(
                borderColor: AppColors.cyberPurple,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.cyberPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.memory, color: AppColors.cyberPurple, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "PyTorch LSTM Forecaster",
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          "30m Lookahead",
                          style: TextStyle(
                            color: AppColors.cyberCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "2-Layer LSTM (hidden_dim=32, 4-step temporal window) predicts segment speeds 30 minutes ahead for fastest path weight formulation.",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                    ),
                    const SizedBox(height: 14),

                    // Sequence Visualizer
                    Row(
                      children: lstmSequence.map((pt) {
                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                "${pt.speedKmh.toInt()}",
                                style: TextStyle(
                                  color: pt.isForecast ? AppColors.cyberCyan : primaryTextColor,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "km/h",
                                style: TextStyle(color: AppColors.textMuted, fontSize: 8.5),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 40,
                                width: 8,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.obsidianSurface : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                      height: (pt.speedKmh / 50.0 * 40).clamp(4.0, 40.0),
                                      decoration: BoxDecoration(
                                        color: pt.isForecast ? AppColors.cyberCyan : AppColors.cyberPurple,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pt.timeLabel,
                                style: TextStyle(
                                  color: pt.isForecast ? AppColors.cyberCyan : AppColors.textMuted,
                                  fontSize: 8.5,
                                  fontWeight: pt.isForecast ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Scikit-Learn Gradient Boosting Hazard Model Vector
              Text(
                "SCIKIT-LEARN GBM (23-FEATURE VECTOR)",
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              ...gbmFeatures.map((feat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CyberCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              feat.featureName,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              "${feat.value} ${feat.unit}",
                              style: const TextStyle(
                                color: AppColors.cyberCyan,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: feat.weightImportance,
                                backgroundColor: isDark ? AppColors.obsidianSurface : const Color(0xFFE2E8F0),
                                color: AppColors.cyberBlue,
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Weight: ${(feat.weightImportance * 100).toInt()}%",
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9.5,
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
}
