import 'package:flutter/material.dart';
import '../../../core/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String _gender = 'Prefer not to say';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _ageCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final userService = UserService();
      final data = await userService.registerUser(
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        age: _ageCtrl.text,
        gender: _gender,
        contactNumber: _contactCtrl.text,
        email: _emailCtrl.text,
        username: _usernameCtrl.text,
        address: _addressCtrl.text,
        password: _passwordCtrl.text,
      );
      await userService.saveUserData(data);
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Create account',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start your ClockLife',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'First name',
                                  prefixIcon: Icon(Icons.badge_rounded),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Last name',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  prefixIcon: Icon(Icons.cake_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  final n = int.tryParse(v);
                                  if (n == null || n <= 0) return 'Invalid age';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                                ],
                                onChanged: (v) => setState(() => _gender = v ?? _gender),
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: Icon(Icons.wc_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _contactCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact number',
                            prefixIcon: Icon(Icons.call_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _usernameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'yourname',
                            prefixIcon: Icon(Icons.account_circle_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Username is required';
                            if (v.trim().length < 3) return 'Min 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure1,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure1 = !_obscure1),
                              icon: Icon(_obscure1 ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscure2,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                              icon: Icon(_obscure2 ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                            ),
                          ),
                          validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _onRegister,
                            child: _loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Sign up'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Have an account?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.7))),
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
    );
  }
}
