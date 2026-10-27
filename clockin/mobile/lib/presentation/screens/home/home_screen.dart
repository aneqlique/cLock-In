import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clockin/core/services/user_service.dart';
import 'package:clockin/core/state/app_settings.dart';
import 'package:clockin/core/state/category_controller.dart';
import 'package:clockin/core/state/theme_controller.dart';
import 'package:clockin/presentation/screens/auth/login_screen.dart';
import 'package:clockin/presentation/screens/diary/diarytl_screen.dart';
import 'package:clockin/presentation/screens/home/clock_view.dart';
import 'package:clockin/presentation/screens/home/task_list_view.dart';
import 'package:clockin/presentation/screens/settings/settings_screen.dart';
import 'package:clockin/presentation/widgets/app_nav_bar.dart';

/// App shell: Clock · Journal · Feed · Profile behind a floating nav bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const _items = [
    AppNavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule_rounded, label: 'Clock'),
    AppNavItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Journal'),
    AppNavItem(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Feed'),
    AppNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final _clockKey = GlobalKey<ClockViewState>();
  late final AnimationController _fade =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  int index = 0;

  late final List<Widget> pages = [
    ClockView(key: _clockKey),
    const TaskListView(),
    const DiarytlScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshAccount();
  }

  // Pick up categories / time format changed on another device.
  Future<void> _refreshAccount() async {
    final theme = context.read<ThemeController>();
    final settings = context.read<AppSettings>();
    final categories = context.read<CategoryController>();
    try {
      final me = await UserService().fetchAndCacheCurrentUser();
      await applyAccountSettings(me,
          theme: theme, settings: settings, categories: categories, includeTheme: false);
    } catch (_) {}
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == index) return;
    setState(() => index = i);
    _fade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: AppNavBar(items: _items, currentIndex: index, onTap: _select),
      floatingActionButton: index == 0
          ? FloatingActionButton(
              tooltip: 'Add task',
              onPressed: () => _clockKey.currentState?.openAddTask(),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}
