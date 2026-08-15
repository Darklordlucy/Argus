import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/main_shell_screen.dart';
import 'services/iot_telemetry_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set crisp white mobile status bar and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Dark status bar icons for white background
      statusBarBrightness: Brightness.light,    // iOS light status bar
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IoTTelemetryService()),
      ],
      child: const AsphrApp(),
    ),
  );
}

class AsphrApp extends StatelessWidget {
  const AsphrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asphr — Mobile Hazard-Aware Dynamic Router',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default to clean White Mode UI
      home: const MainShellScreen(),
    );
  }
}
