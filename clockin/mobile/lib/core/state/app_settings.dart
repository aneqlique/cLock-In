import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

/// App-wide display preferences. Currently the 12h/24h time format, saved on
/// the device and synced to the user's `timeFormat` field.
class AppSettings extends ChangeNotifier {
  static const prefsKey = 'time_format';

  bool _use24h = false;
  bool get use24h => _use24h;
  String get timeFormat => _use24h ? '24h' : '12h';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _use24h = prefs.getString(prefsKey) == '24h';
    } catch (_) {}
  }

  /// Change the format from the UI. Saves locally and on the backend.
  Future<void> setTimeFormat(String value) async {
    if (value != '12h' && value != '24h') return;
    await _apply(value == '24h');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final id = prefs.getString('id') ?? '';
      if (token.isEmpty || id.isEmpty) return;
      await UserService().updateUser(token: token, id: id, updates: {'timeFormat': value});
    } catch (_) {
      // Local choice still applies; the backend copy is best-effort.
    }
  }

  /// Apply the format stored on the user's account without writing it back.
  Future<void> applyRemote(Object? value) async {
    if (value == '12h' || value == '24h') await _apply(value == '24h');
  }

  Future<void> _apply(bool use24h) async {
    if (use24h != _use24h) {
      _use24h = use24h;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, use24h ? '24h' : '12h');
    } catch (_) {}
  }
}
