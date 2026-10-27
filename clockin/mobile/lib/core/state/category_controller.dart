import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_category.dart';
import '../services/user_service.dart';

/// The signed-in user's task categories. Cached on the device and saved to
/// the user's `categories` field on the backend.
class CategoryController extends ChangeNotifier {
  static const prefsKey = 'categories_cache';
  static const maxCategories = 12;
  static const maxNameLength = 20;

  List<TaskCategory> _items = List.of(kDefaultCategories);
  List<TaskCategory> get items => List.unmodifiable(_items);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw != null) _items = _parse(jsonDecode(raw)) ?? _items;
    } catch (_) {}
  }

  /// Use the list stored on the user's account (e.g. after login).
  Future<void> applyRemote(Object? raw) async {
    final parsed = _parse(raw);
    if (parsed == null) return;
    _items = parsed;
    notifyListeners();
    await _cache();
  }

  /// Back to defaults, e.g. after logout.
  void reset() {
    _items = List.of(kDefaultCategories);
    notifyListeners();
  }

  TaskCategory byKey(String key) {
    for (final c in _items) {
      if (c.key == key) return c;
    }
    return TaskCategory.fallback(key);
  }

  String get defaultKey => _items.first.key;

  /// Returns an error message, or null if [name] is usable.
  String? validateName(String name, {String? exceptKey}) {
    final n = name.trim();
    if (n.isEmpty) return 'Give the category a name.';
    if (n.length > maxNameLength) return 'Keep it under $maxNameLength characters.';
    final taken = _items.any((c) => c.key != exceptKey && c.name.toLowerCase() == n.toLowerCase());
    if (taken) return 'You already have a category called "$n".';
    return null;
  }

  static String newKey(String name) {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix = Random().nextInt(1 << 20).toRadixString(36);
    final base = slug.isEmpty ? 'cat' : (slug.length > 24 ? slug.substring(0, 24) : slug);
    return '$base-$suffix';
  }

  Future<void> add(TaskCategory c) => _commit([..._items, c]);

  Future<void> update(TaskCategory c) => _commit([for (final x in _items) x.key == c.key ? c : x]);

  /// [newIndex] is the position after removing the item (onReorderItem semantics).
  Future<void> reorder(int oldIndex, int newIndex) {
    final next = List.of(_items);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), item);
    return _commit(next);
  }

  Future<void> remove(String key) {
    if (_items.length <= 1) throw StateError('At least one category is required.');
    return _commit(_items.where((c) => c.key != key).toList());
  }

  // Apply locally right away, save to the backend, roll back on failure.
  Future<void> _commit(List<TaskCategory> next) async {
    final prev = _items;
    _items = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final id = prefs.getString('id') ?? '';
      if (token.isNotEmpty && id.isNotEmpty) {
        await UserService().updateUser(
          token: token,
          id: id,
          updates: {'categories': next.map((c) => c.toJson()).toList()},
        );
      }
      await _cache();
    } catch (e) {
      _items = prev;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _cache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(_items.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }

  List<TaskCategory>? _parse(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    final list = raw.whereType<Map>().map(TaskCategory.fromJson).where((c) => c.key.isNotEmpty).toList();
    return list.isEmpty ? null : list;
  }
}
