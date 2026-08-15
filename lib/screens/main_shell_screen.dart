import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'iot_heatmap_screen.dart';
import 'ml_dashboard_screen.dart';
import 'rlhf_feedback_screen.dart';
import 'route_planner_screen.dart';
import 'sos_emergency_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RoutePlannerScreen(),
    IoTHeatmapScreen(),
    MLDashboardScreen(),
    RLHFFeedbackScreen(),
    SOSEmergencyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.obsidianSurface : AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
          ),
          boxShadow: [
            if (!isDark)
              const BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            elevation: 0,
            selectedItemColor: AppColors.cyberCyan,
            unselectedItemColor: AppColors.textMuted,
            backgroundColor: Colors.transparent,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.navigation_outlined),
                activeIcon: Icon(Icons.navigation),
                label: "Router",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sensors_outlined),
                activeIcon: Icon(Icons.sensors),
                label: "IoT Stream",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology_outlined),
                activeIcon: Icon(Icons.psychology),
                label: "ML Models",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rate_review_outlined),
                activeIcon: Icon(Icons.rate_review),
                label: "RLHF",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sos_outlined),
                activeIcon: Icon(Icons.sos),
                label: "SOS",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
