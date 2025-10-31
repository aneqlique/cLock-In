import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockin/core/services/user_service.dart';
import 'package:clockin/core/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _uploadingImage = false;

  String _userId = '';
  String _token = '';
  String _profilePicture = '';
  String _theme = 'system';
  bool _notificationsEnabled = true;
  bool _taskReminders = true;
  bool _socialInteractions = true;
  String _ringtone = 'default';

  final ImagePicker _picker = ImagePicker();

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
      _profilePicture = user['profilePicture'] ?? prefs.getString('profilePicture') ?? '';
      _theme = user['theme'] ?? 'system';
      final notifSettings = user['notificationSettings'];
      if (notifSettings != null && notifSettings is Map) {
        _notificationsEnabled = notifSettings['enabled'] ?? true;
        _taskReminders = notifSettings['taskReminders'] ?? true;
        _socialInteractions = notifSettings['socialInteractions'] ?? true;
        _ringtone = notifSettings['ringtone'] ?? 'default';
      }
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

  Future<void> _pickAndUploadProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
      if (pickedFile == null) return;

      setState(() => _uploadingImage = true);
      
      final imageUrl = await ApiService.uploadImages(_token, [File(pickedFile.path)]);
      if (imageUrl.isEmpty) throw Exception('Failed to upload image');

      final updates = {'profilePicture': imageUrl.first};
      final res = await UserService().updateUser(token: _token, id: _userId, updates: updates);
      await UserService().saveUserData({'user': res, 'token': _token});
      
      setState(() {
        _profilePicture = imageUrl.first;
      });
      
      // Save to shared preferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePicture', imageUrl.first);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
    try {
      final res = await UserService().updateUser(token: _token, id: _userId, updates: updates);
      await UserService().saveUserData({'user': res, 'token': _token});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: ${e.toString()}')));
      }
    }
  }

  Future<void> _logout() async {
    await UserService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        label: const Text('Log out', style: TextStyle(color: Colors.red)),
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFEAE6E0),
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFFEAE6E0),
      //   elevation: 0,
      //   centerTitle: true,
      //   automaticallyImplyLeading: false,
      //   title: Image.asset('assets/Logo.png', height: 30),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. PROFILE SECTION
            _buildProfileSection(),
            const SizedBox(height: 16),
            
            // 2. THEME TOGGLE
            _buildThemeCard(),
            const SizedBox(height: 16),
            
            // 3. NOTIFICATION SETTINGS
            _buildNotificationCard(),
            const SizedBox(height: 16),
            
            // 4. LOGOUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profilePicture.isNotEmpty
                      ? NetworkImage(_profilePicture)
                      : null,
                  child: _profilePicture.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                if (_uploadingImage)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_editing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_firstNameCtrl.text} ${_lastNameCtrl.text}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '@${_usernameCtrl.text}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            // Edit Profile Button
            OutlinedButton.icon(
              onPressed: () => setState(() => _editing = !_editing),
              icon: Icon(_editing ? Icons.close : Icons.edit),
              label: Text(_editing ? 'Cancel' : 'Edit Profile'),
            ),
            // Show form fields when editing
            if (_editing) ...[
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.palette_outlined),
                SizedBox(width: 12),
                Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildThemeOption('Light', Icons.light_mode, 'light'),
                _buildThemeOption('Dark', Icons.dark_mode, 'dark'),
                _buildThemeOption('System', Icons.settings_brightness, 'system'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String label, IconData icon, String value) {
    final isSelected = _theme == value;
    return GestureDetector(
      onTap: () {
        setState(() => _theme = value);
        _updateSettings({'theme': value});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notifications_outlined),
                SizedBox(width: 12),
                Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            
            // Enable Notifications
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive all notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _updateSettings({
                  'notificationSettings': {
                    'enabled': value,
                    'taskReminders': _taskReminders,
                    'socialInteractions': _socialInteractions,
                    'ringtone': _ringtone,
                  }
                });
              },
            ),
            
            // Task Reminders
            SwitchListTile(
              title: const Text('Task Reminders'),
              subtitle: const Text('Get notified 10 minutes before tasks'),
              value: _taskReminders,
              onChanged: _notificationsEnabled ? (value) {
                setState(() => _taskReminders = value);
                _updateSettings({
                  'notificationSettings': {
                    'enabled': _notificationsEnabled,
                    'taskReminders': value,
                    'socialInteractions': _socialInteractions,
                    'ringtone': _ringtone,
                  }
                });
              } : null,
            ),
            
            // Social Interactions
            SwitchListTile(
              title: const Text('Social Interactions'),
              subtitle: const Text('Likes and comments on your posts'),
              value: _socialInteractions,
              onChanged: _notificationsEnabled ? (value) {
                setState(() => _socialInteractions = value);
                _updateSettings({
                  'notificationSettings': {
                    'enabled': _notificationsEnabled,
                    'taskReminders': _taskReminders,
                    'socialInteractions': value,
                    'ringtone': _ringtone,
                  }
                });
              } : null,
            ),
            
            const Divider(height: 24),
            
            // Ringtone Selector
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Ringtone'),
              subtitle: Text(_ringtone == 'default' ? 'Default' : _ringtone.toUpperCase()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _notificationsEnabled ? _showRingtoneDialog : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showRingtoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Ringtone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRingtoneOption('Default', 'default'),
            _buildRingtoneOption('Chime', 'chime'),
            _buildRingtoneOption('Bell', 'bell'),
            _buildRingtoneOption('Ding', 'ding'),
          ],
        ),
      ),
    );
  }

  Widget _buildRingtoneOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _ringtone,
      onChanged: (val) {
        if (val != null) {
          setState(() => _ringtone = val);
          _updateSettings({
            'notificationSettings': {
              'enabled': _notificationsEnabled,
              'taskReminders': _taskReminders,
              'socialInteractions': _socialInteractions,
              'ringtone': val,
            }
          });
          Navigator.pop(context);
        }
      },
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