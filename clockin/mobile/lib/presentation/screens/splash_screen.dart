import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import '../../core/services/user_service.dart';
import '../widgets/avatar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void initState() {
    super.initState();
    _route();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Skip the login screen while the saved session is still valid.
  Future<void> _route() async {
    final results = await Future.wait([
      UserService().hasValidSession(),
      Future.delayed(const Duration(milliseconds: 1100)),
    ]);
    if (!mounted) return;
    final loggedIn = results.first as bool;
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 72),
                const SizedBox(height: 20),
                Text('cLock-In', style: context.tt.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Part clock, part agenda, part diary.',
                  style: context.tt.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
