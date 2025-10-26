import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockin/core/services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _editing = false;

  String _userId = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';
      _userId = prefs.getString('id') ?? '';
      final userSvc = UserService();
      var user = await userSvc.getUserData();
      final missingCore = (user['username'] as String? ?? '').isEmpty || (user['email'] as String? ?? '').isEmpty;
      if (missingCore && _token.isNotEmpty) {
        // Try to fetch full user details and cache them
        await userSvc.fetchAndCacheCurrentUser();
        user = await userSvc.getUserData();
      }
      _firstNameCtrl.text = user['firstName'] ?? '';
      _lastNameCtrl.text = user['lastName'] ?? '';
      _usernameCtrl.text = user['username'] ?? '';
      _emailCtrl.text = user['email'] ?? '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token.isEmpty || _userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not logged in. Please log in again.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final updates = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      };
      final res = await UserService().updateUser(token: _token, id: _userId, updates: updates);
      await UserService().saveUserData({'user': res, 'token': _token});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() => _editing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await UserService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
                      ),
                      IconButton(
                        tooltip: _editing ? 'Cancel' : 'Edit',
                        onPressed: _loading ? null : () => setState(() => _editing = !_editing),
                        icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded, color: cs.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _loading
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          ))
                        : (_editing
                            ? Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _firstNameCtrl,
                                          decoration: const InputDecoration(labelText: 'First name'),
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _lastNameCtrl,
                                          decoration: const InputDecoration(labelText: 'Last name'),
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _usernameCtrl,
                                      decoration: const InputDecoration(labelText: 'Username'),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _emailCtrl,
                                      decoration: const InputDecoration(labelText: 'Email'),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Required';
                                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Invalid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _saving ? null : _save,
                                        child: _saving
                                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Text('Save Changes'),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InfoRow(label: 'Name', value: '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim()),
                                  const SizedBox(height: 8),
                                  _InfoRow(label: 'Username', value: _usernameCtrl.text),
                                  const SizedBox(height: 8),
                                  _InfoRow(label: 'Email', value: _emailCtrl.text),
                                ],
                              )
                          ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.primary.withOpacity(.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}
