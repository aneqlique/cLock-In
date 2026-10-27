import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/category_controller.dart';
import '../../../core/state/data_sync.dart';
import '../../../core/state/theme_controller.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/avatar.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/dialogs.dart';
import 'categories_screen.dart';

/// The Profile tab: account, appearance, notifications and logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _firstName = '';
  String _lastName = '';
  String _username = '';
  String _email = '';
  String _userId = '';
  String _token = '';
  String _profilePicture = '';
  bool _uploadingImage = false;
  int _entries = 0;
  int _shared = 0;

  bool _notificationsEnabled = true;
  bool _taskReminders = true;
  bool _socialInteractions = true;
  String _ringtone = 'default';

  final ImagePicker _picker = ImagePicker();
  DataSync? _sync;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sync == null) {
      _sync = context.read<DataSync>();
      _sync!.addListener(_loadStats);
    }
  }

  @override
  void dispose() {
    _sync?.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _userId = prefs.getString('id') ?? '';
    final userSvc = UserService();
    var user = await userSvc.getUserData();
    final missingCore = (user['username'] as String? ?? '').isEmpty || (user['email'] as String? ?? '').isEmpty;
    if (missingCore && _token.isNotEmpty) {
      // Try to fetch full user details and cache them
      try {
        await userSvc.fetchAndCacheCurrentUser();
      } catch (_) {}
      user = await userSvc.getUserData();
      _userId = prefs.getString('id') ?? _userId;
    }
    if (!mounted) return;
    setState(() => _applyUser(user));
    _loadStats();
  }

  void _applyUser(Map<String, dynamic> user) {
    _firstName = (user['firstName'] ?? '').toString();
    _lastName = (user['lastName'] ?? '').toString();
    _username = (user['username'] ?? '').toString();
    _email = (user['email'] ?? '').toString();
    _profilePicture = (user['profilePicture'] ?? '').toString();
    final notif = user['notificationSettings'];
    if (notif is Map) {
      _notificationsEnabled = notif['enabled'] ?? true;
      _taskReminders = notif['taskReminders'] ?? true;
      _socialInteractions = notif['socialInteractions'] ?? true;
      _ringtone = notif['ringtone'] ?? 'default';
    }
  }

  // Journal entries = completed tasks; shared = those posted to the feed.
  Future<void> _loadStats() async {
    if (_token.isEmpty) return;
    try {
      final list = await ApiService.getTasks(_token);
      final completed = list.whereType<Map>().where((m) => m['status'] == 'completed');
      if (!mounted) return;
      setState(() {
        _entries = completed.length;
        _shared = completed.where((m) => m['setPublic'] == true).length;
      });
    } catch (_) {}
  }

  Future<void> _saveUser(Map<String, dynamic> updates) async {
    final res = await UserService().updateUser(token: _token, id: _userId, updates: updates);
    await UserService().saveUserData({'user': res, 'token': _token});
    final user = await UserService().getUserData();
    if (mounted) setState(() => _applyUser(user));
  }

  Future<void> _pickAndUploadProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
      if (pickedFile == null) return;
      setState(() => _uploadingImage = true);
      final imageUrl = await ApiService.uploadImages(_token, [File(pickedFile.path)]);
      if (imageUrl.isEmpty) throw Exception('Failed to upload image');
      await _saveUser({'profilePicture': imageUrl.first});
      if (mounted) showAppSnack(context, 'Profile picture updated');
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to upload: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _updateNotifications({bool? enabled, bool? reminders, bool? social, String? ringtone}) async {
    setState(() {
      _notificationsEnabled = enabled ?? _notificationsEnabled;
      _taskReminders = reminders ?? _taskReminders;
      _socialInteractions = social ?? _socialInteractions;
      _ringtone = ringtone ?? _ringtone;
    });
    try {
      await _saveUser({
        'notificationSettings': {
          'enabled': _notificationsEnabled,
          'taskReminders': _taskReminders,
          'socialInteractions': _socialInteractions,
          'ringtone': _ringtone,
        }
      });
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to update: ${friendlyError(e)}');
    }
  }

  Future<void> _logout() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You can log back in any time with your username and password.',
      confirmLabel: 'Log out',
    );
    if (!ok || !mounted) return;
    final categories = context.read<CategoryController>();
    await UserService().logout();
    categories.reset();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _openEditProfile() {
    if (_token.isEmpty || _userId.isEmpty) {
      showAppSnack(context, 'You are not logged in. Please log in again.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(
        profilePicture: _profilePicture,
        onChangePhoto: _pickAndUploadProfilePicture,
        firstName: _firstName,
        lastName: _lastName,
        username: _username,
        email: _email,
        onSave: (updates) async {
          await _saveUser(updates);
          _sync?.bump(this);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final settings = context.watch<AppSettings>();
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await UserService().fetchAndCacheCurrentUser();
          } catch (_) {}
          await _loadUser();
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16,
              MediaQuery.paddingOf(context).bottom + 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text('Profile', style: context.tt.headlineMedium),
            ),
            _profileHeader(),
            const SizedBox(height: 24),
            _section('Account', [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Edit profile'),
                subtitle: const Text('Name, username and email'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openEditProfile,
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Change photo'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _uploadingImage ? null : _pickAndUploadProfilePicture,
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categories'),
                subtitle: Text('${context.watch<CategoryController>().items.length} categories'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
              ),
            ]),
            _section('Appearance', [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                          ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                          ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
                        ],
                        selected: {themeController.modeName},
                        onSelectionChanged: (s) => themeController.setMode(s.first),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Time format', style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: '12h', label: Text('12-hour  ·  2:30 PM')),
                          ButtonSegment(value: '24h', label: Text('24-hour  ·  14:30')),
                        ],
                        selected: {settings.timeFormat},
                        onSelectionChanged: (s) => settings.setTimeFormat(s.first),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            _section('Notifications', [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Enable notifications'),
                subtitle: const Text('Receive all notifications'),
                value: _notificationsEnabled,
                onChanged: (v) => _updateNotifications(enabled: v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.alarm_outlined),
                title: const Text('Task reminders'),
                subtitle: const Text('Get notified before tasks end'),
                value: _taskReminders,
                onChanged: _notificationsEnabled ? (v) => _updateNotifications(reminders: v) : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.favorite_border_rounded),
                title: const Text('Social interactions'),
                subtitle: const Text('Likes and comments on your posts'),
                value: _socialInteractions,
                onChanged: _notificationsEnabled ? (v) => _updateNotifications(social: v) : null,
              ),
              ListTile(
                enabled: _notificationsEnabled,
                leading: const Icon(Icons.music_note_outlined),
                title: const Text('Ringtone'),
                subtitle: Text(_ringtoneLabel(_ringtone)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showRingtonePicker,
              ),
            ]),
            _section('', [
              ListTile(
                leading: Icon(Icons.logout_rounded, color: cs.error),
                title: Text('Log out', style: TextStyle(color: cs.error)),
                onTap: _logout,
              ),
            ]),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'cLock-In · v1.0.0',
                style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    final cs = context.cs;
    final name = '$_firstName $_lastName'.trim();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Avatar(imageUrl: _profilePicture, name: name.isEmpty ? _username : name, radius: 48),
              if (_uploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: cs.primary,
                  shape: CircleBorder(side: BorderSide(color: cs.surfaceContainerLow, width: 3)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploadingImage ? null : _pickAndUploadProfilePicture,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.photo_camera_rounded, size: 18, color: cs.onPrimary, semanticLabel: 'Change photo'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name.isEmpty ? 'Your name' : name, style: context.tt.titleLarge, textAlign: TextAlign.center),
          if (_username.isNotEmpty)
            Text('@$_username', style: context.tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _stat('$_entries', 'Journal entries')),
              Container(width: 1, height: 32, color: cs.outlineVariant),
              Expanded(child: _stat('$_shared', 'Shared to feed')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value, style: context.tt.titleLarge),
          Text(label, style: context.tt.bodySmall?.copyWith(color: context.cs.onSurfaceVariant)),
        ],
      );

  Widget _section(String title, List<Widget> children) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                title.toUpperCase(),
                style: context.tt.labelMedium?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1),
              ),
            ),
          Material(
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg - 4),
              side: BorderSide(color: cs.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 56),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ringtoneLabel(String v) => v.isEmpty ? 'Default' : v[0].toUpperCase() + v.substring(1);

  void _showRingtonePicker() {
    const options = ['default', 'chime', 'bell', 'ding'];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Select ringtone', style: ctx.tt.titleLarge),
            ),
            for (final o in options)
              ListTile(
                leading: Icon(o == _ringtone ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: o == _ringtone ? ctx.cs.primary : null),
                title: Text(_ringtoneLabel(o)),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateNotifications(ringtone: o);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String profilePicture;
  final Future<void> Function() onChangePhoto;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final Future<void> Function(Map<String, dynamic> updates) onSave;

  const _EditProfileSheet({
    required this.profilePicture,
    required this.onChangePhoto,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameCtrl = TextEditingController(text: widget.firstName);
  late final _lastNameCtrl = TextEditingController(text: widget.lastName);
  late final _usernameCtrl = TextEditingController(text: widget.username);
  late final _emailCtrl = TextEditingController(text: widget.email);
  late String _picture = widget.profilePicture;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    setState(() => _uploading = true);
    await widget.onChangePhoto();
    final user = await UserService().getUserData();
    if (!mounted) return;
    setState(() {
      _uploading = false;
      _picture = (user['profilePicture'] ?? _picture).toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, 'Profile updated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
    final name = '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim();
    return Form(
      key: _formKey,
      child: AppSheet(
        title: 'Edit profile',
        actionLabel: 'Save',
        actionLoading: _saving,
        onAction: _save,
        children: [
          Center(
            child: Stack(
              children: [
                Avatar(imageUrl: _picture, name: name.isEmpty ? _usernameCtrl.text : name, radius: 44),
                if (_uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: _uploading ? null : _changePhoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Change photo'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _firstNameCtrl,
                  label: 'First name',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: required,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _lastNameCtrl,
                  label: 'Last name',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: required,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _usernameCtrl,
            label: 'Username',
            prefixIcon: Icons.alternate_email_rounded,
            textInputAction: TextInputAction.next,
            validator: required,
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _emailCtrl,
            label: 'Email',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Your username is how others see you on the Feed.',
            style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
