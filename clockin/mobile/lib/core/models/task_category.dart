import 'package:flutter/material.dart';

/// Number of tints in AppColors.categoryFill.
const kTintCount = 8;

/// Icons a category can use, keyed by the value stored on the backend.
const kCategoryIcons = <String, IconData>{
  'school': Icons.school_rounded,
  'work': Icons.work_rounded,
  'spa': Icons.spa_rounded,
  'home': Icons.home_rounded,
  'fitness': Icons.fitness_center_rounded,
  'book': Icons.menu_book_rounded,
  'code': Icons.code_rounded,
  'brush': Icons.brush_rounded,
  'music': Icons.music_note_rounded,
  'food': Icons.restaurant_rounded,
  'cart': Icons.shopping_cart_rounded,
  'people': Icons.people_rounded,
  'heart': Icons.favorite_rounded,
  'travel': Icons.flight_rounded,
  'game': Icons.sports_esports_rounded,
  'sleep': Icons.bedtime_rounded,
};

/// A user-defined task category. Tasks store [key]; name, tint and icon can
/// change without touching them.
@immutable
class TaskCategory {
  final String key;
  final String name;
  final int color; // index into the tint palette
  final String icon; // key into kCategoryIcons

  const TaskCategory({required this.key, required this.name, required this.color, required this.icon});

  IconData get iconData => kCategoryIcons[icon] ?? Icons.label_rounded;

  factory TaskCategory.fromJson(Map m) {
    final c = m['color'];
    return TaskCategory(
      key: (m['key'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      color: (c is num ? c.toInt() : 0).clamp(0, kTintCount - 1),
      icon: (m['icon'] ?? 'spa').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'name': name, 'color': color, 'icon': icon};

  TaskCategory copyWith({String? name, int? color, String? icon}) =>
      TaskCategory(key: key, name: name ?? this.name, color: color ?? this.color, icon: icon ?? this.icon);

  /// Stand-in for a key that isn't in the user's list (e.g. another user's
  /// category on the feed): title-cased key and a stable tint.
  factory TaskCategory.fallback(String key) {
    final k = key.trim();
    final name = k.isEmpty ? 'Other' : k[0].toUpperCase() + k.substring(1).split('-').first;
    final tint = k.codeUnits.fold<int>(0, (a, b) => a + b) % kTintCount;
    return TaskCategory(key: k, name: name, color: tint, icon: 'label');
  }
}

const kDefaultCategories = [
  TaskCategory(key: 'school', name: 'School', color: 0, icon: 'school'),
  TaskCategory(key: 'work', name: 'Work', color: 1, icon: 'work'),
  TaskCategory(key: 'self', name: 'Self', color: 2, icon: 'spa'),
  TaskCategory(key: 'house', name: 'House', color: 3, icon: 'home'),
];
