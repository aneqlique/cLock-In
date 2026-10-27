# Settings & Alarm Implementation Guide

## ✅ Completed Changes

### Backend Updates

1. **User Model** (`backend/models/User.js`)
   - Added `profilePicture: String`
   - Added `notificationSettings` object:
     - `enabled: Boolean`
     - `taskReminders: Boolean`
     - `socialInteractions: Boolean`
     - `ringtone: String`
   - Added `theme: String` (enum: 'light', 'dark', 'system')

2. **Task Model** (`backend/models/Task.js`)
   - Added `alarm` object:
     - `enabled: Boolean`
     - `minutesBefore: Number` (enum: [5, 10, 30, 60])

### Frontend - Settings Screen Updates

**File:** `mobile/lib/presentation/screens/settings/settings_screen.dart`

**Changes Made:**
- Added imports for `dart:io`, `ApiService`, and `image_picker`
- Added state variables for profile picture, theme, and notification settings
- Added `_pickAndUploadProfilePicture()` method
- Added `_updateSettings()` method
- Updated `_loadUser()` to load new fields

---

## 🔨 Required Manual Updates

### 1. Settings Screen UI (Needs Complete Rewrite)

The settings screen UI needs to be rebuilt with a modern design. Here's the structure:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFEAE6E0),
    appBar: AppBar(
      backgroundColor: const Color(0xFFEAE6E0),
      elevation: 0,
      centerTitle: true,  // CENTER THE LOGO
      automaticallyImplyLeading: false,
      title: Image.asset('assets/Logo.png', height: 30),
    ),
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
          _buildLogoutButton(),
        ],
      ),
    ),
  );
}
```

### Profile Section Widget:
```dart
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
            // Add form fields here
          ],
        ],
      ),
    ),
  );
}
```

### Theme Toggle Widget:
```dart
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
```

### Notification Settings Widget:
```dart
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
```

---

## 2. Home Screen - Add Alarm Functionality

**File:** `mobile/lib/presentation/screens/home/home_screen.dart`

### Add Alarm Icon to Task Cards:

In the task card build method, add an alarm indicator icon:

```dart
// In the task card widget
Row(
  children: [
    Text(task['taskTitle']),
    const Spacer(),
    if (task['alarm'] != null && task['alarm']['enabled'] == true)
      const Icon(Icons.alarm, size: 16, color: Colors.amber),
  ],
)
```

### Add Alarm Setting in Task Modal:

```dart
// In task edit modal
Column(
  children: [
    // ... existing fields ...
    
    const SizedBox(height: 16),
    const Text('Alarm', style: TextStyle(fontWeight: FontWeight.bold)),
    SwitchListTile(
      title: const Text('Set Alarm'),
      value: _alarmEnabled,
      onChanged: (value) {
        setState(() => _alarmEnabled = value);
      },
    ),
    if (_alarmEnabled)
      DropdownButtonFormField<int>(
        value: _alarmMinutes,
        decoration: const InputDecoration(labelText: 'Remind me before'),
        items: const [
          DropdownMenuItem(value: 5, child: Text('5 minutes before')),
          DropdownMenuItem(value: 10, child: Text('10 minutes before')),
          DropdownMenuItem(value: 30, child: Text('30 minutes before')),
          DropdownMenuItem(value: 60, child: Text('1 hour before')),
        ],
        onChanged: (value) {
          setState(() => _alarmMinutes = value ?? 10);
        },
      ),
  ],
)

// When saving task:
final taskData = {
  // ... existing fields ...
  'alarm': {
    'enabled': _alarmEnabled,
    'minutesBefore': _alarmMinutes,
  },
};
```

---

## 3. Background Notifications Setup

### Required Packages:

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  workmanager: ^0.5.2
```

### Create Notification Service:

**File:** `mobile/lib/core/services/notification_service.dart`

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(settings);
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }
  
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'clockin_channel',
      'ClockIn Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.show(id, title, body, details);
  }
  
  static Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    // Schedule notification
    await _notifications.zonedSchedule(
      taskId.hashCode,
      'Task Reminder',
      'Task "$taskTitle" starts in 10 minutes!',
      TZDateTime.from(reminderTime, local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background task logic here
    return Future.value(true);
  });
}
```

---

## 4. Restart Backend & Test

```bash
cd backend
nodemon index.js
```

## 5. Test Checklist

- [ ] Settings screen shows centered logo
- [ ] Profile picture upload works
- [ ] Theme toggle updates and persists
- [ ] Notification toggles work
- [ ] Ringtone selector opens and saves
- [ ] Alarm can be set on tasks
- [ ] Alarm icon shows on tasks with alarms
- [ ] Backend saves all new fields properly

---

## Notes

- Background notifications require platform-specific setup (Android: Manifest permissions, iOS: Capabilities)
- For production, implement proper notification scheduling service
- Consider using Firebase Cloud Messaging for cross-device notifications
- Ringtone playback requires native audio services
