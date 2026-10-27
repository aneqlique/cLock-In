import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/state/app_settings.dart';
import 'core/state/category_controller.dart';
import 'core/state/data_sync.dart';
import 'core/state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {

  }
  final themeController = ThemeController();
  final settings = AppSettings();
  final categories = CategoryController();
  await Future.wait([themeController.load(), settings.load(), categories.load()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: categories),
        ChangeNotifierProvider(create: (_) => DataSync()),
      ],
      child: const ClockInApp(),
    ),
  );
}
