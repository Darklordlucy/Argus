import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/main_shell_screen.dart';
import 'services/iot_telemetry_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set tactical dark status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.obsidianSurface,
      systemNavigationBarIconBrightness: Brightness.light,
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
      title: 'Asphr — AI Spatial Intelligence & Route Engine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShellScreen(),
    );
  }
}
