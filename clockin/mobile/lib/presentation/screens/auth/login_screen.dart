import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/user_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/category_controller.dart';
import '../../../core/state/theme_controller.dart';
import '../../widgets/avatar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/dialogs.dart';

/// Applies the preferences stored on the user's account (theme, time format,
/// categories). Called after login and when the app shell refreshes the user.
Future<void> applyAccountSettings(
  Map<String, dynamic>? me, {
  required ThemeController theme,
  required AppSettings settings,
  required CategoryController categories,
  bool includeTheme = true,
}) async {
  if (me == null) return;
  if (includeTheme) await theme.applyRemote(me['theme']);
  await settings.applyRemote(me['timeFormat']);
  await categories.applyRemote(me['categories']);
}

/// Logs in and caches the user, then applies their saved preferences.
/// Shared by the login and register screens.
Future<void> signIn(BuildContext context, String username, String password) async {
  final userService = UserService();
  final themeController = context.read<ThemeController>();
  final settings = context.read<AppSettings>();
  final categories = context.read<CategoryController>();
  final data = await userService.loginUser(username, password);
  await userService.saveUserData(data);
  // Ensure username is available in prefs even if backend didn't return it
  try {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString('username') ?? '').isEmpty) {
      await prefs.setString('username', username);
    }
  } catch (_) {}
  // Fetch full user details (name, photo, theme) for the rest of the app
  try {
    final me = await userService.fetchAndCacheCurrentUser();
    await applyAccountSettings(me, theme: themeController, settings: settings, categories: categories);
  } catch (_) {}
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await signIn(context, _usernameCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = friendlyError(e);
      showAppSnack(context, msg.contains('Login failed') ? 'Wrong username or password.' : msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: AppLogo(size: 44)),
                      const SizedBox(height: 32),
                      Text('Welcome back', style: context.tt.headlineMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Log in to keep your day on the clock.',
                        style: context.tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        controller: _usernameCtrl,
                        label: 'Username',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _passwordCtrl,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _onLogin(),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showAppSnack(context, 'Password reset isn\'t available yet.'),
                          child: Text('Forgot password?', style: TextStyle(color: cs.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppButton(label: 'Log in', loading: _loading, onPressed: _onLogin),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?", style: TextStyle(color: cs.onSurfaceVariant)),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: const Text('Sign up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
