import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

/// Holds the app's light/dark/system choice. Persists it on the device and
/// syncs it to the user's `theme` field on the backend.
class ThemeController extends ChangeNotifier {
  static const prefsKey = 'theme_mode';
  static const _values = ['light', 'dark', 'system'];

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  String get modeName => _mode.name;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = _parse(prefs.getString(prefsKey)) ?? ThemeMode.system;
    } catch (_) {}
  }

  /// Change the theme from the UI. Saves locally and on the backend.
  Future<void> setMode(String name) async {
    final parsed = _parse(name);
    if (parsed == null) return;
    await _apply(parsed);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final id = prefs.getString('id') ?? '';
      if (token.isEmpty || id.isEmpty) return;
      await UserService().updateUser(token: token, id: id, updates: {'theme': name});
    } catch (_) {
      // Local choice still applies; the backend copy is best-effort.
    }
  }

  /// Apply the theme stored on the user's account (e.g. after login) without
  /// writing it back to the backend.
  Future<void> applyRemote(Object? name) async {
    final parsed = _parse(name?.toString());
    if (parsed != null) await _apply(parsed);
  }

  Future<void> _apply(ThemeMode mode) async {
    if (mode != _mode) {
      _mode = mode;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, mode.name);
    } catch (_) {}
  }

  ThemeMode? _parse(String? name) {
    if (name == null || !_values.contains(name)) return null;
    return ThemeMode.values.byName(name);
  }
}
