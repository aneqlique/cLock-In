import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/user_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/dialogs.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _agree = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      showAppSnack(context, 'Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final userService = UserService();
    try {
      final data = await userService.registerUser(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await userService.saveUserData(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnack(context, 'Sign up failed. ${friendlyError(e)}');
      return;
    }
    // Account exists now — log straight in instead of bouncing to Login.
    try {
      if (!mounted) return;
      await signIn(context, _usernameCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, 'Account created — please log in.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Create your account', style: context.tt.headlineMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Plan your day on the clock, journal it, share it.',
                        style: context.tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _firstNameCtrl,
                              label: 'First name',
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.givenName],
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _lastNameCtrl,
                              label: 'Last name',
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.familyName],
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _usernameCtrl,
                        label: 'Username',
                        prefixIcon: Icons.alternate_email_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Username is required';
                          if (v.trim().length < 3) return 'Min 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _passwordCtrl,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _confirmCtrl,
                        label: 'Confirm password',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onRegister(),
                        validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () => setState(() => _agree = !_agree),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                              Expanded(
                                child: Text(
                                  'I agree to the Terms of Service and Privacy Policy',
                                  style: context.tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(label: 'Create account', loading: _loading, onPressed: _onRegister),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?', style: TextStyle(color: cs.onSurfaceVariant)),
                          TextButton(
                            onPressed: () => Navigator.popAndPushNamed(context, '/login'),
                            child: const Text('Log in'),
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
