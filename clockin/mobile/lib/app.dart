import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'core/config/theme.dart';
import 'core/config/routes.dart';

class ClockInApp extends StatelessWidget {
  const ClockInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClockLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
