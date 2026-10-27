import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme.dart';
import 'core/config/routes.dart';
import 'core/state/app_settings.dart';
import 'core/state/theme_controller.dart';

class ClockInApp extends StatelessWidget {
  const ClockInApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;
    final use24h = context.watch<AppSettings>().use24h;
    return MaterialApp(
      title: 'ClockIn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // The user's 12h/24h choice drives every time display and time picker.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24h),
        child: child!,
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
