import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'route_planner_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      HomeScreen(
        onNavigateToRoute: () => setState(() => _currentIndex = 1),
        onNavigateToProfile: () => setState(() => _currentIndex = 2),
      ),
      const RoutePlannerScreen(),
      ProfileScreen(
        onNavigateToRoute: () => setState(() => _currentIndex = 1),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.navigation_outlined),
                activeIcon: Icon(Icons.navigation),
                label: "Navigation",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
