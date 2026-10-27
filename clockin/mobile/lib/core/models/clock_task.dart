import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

/// Reminder offsets the backend accepts (Task.alarm.minutesBefore enum).
const kAlarmMinuteOptions = [5, 10, 30, 60];

/// A task placed on today's 24-hour clock.
class ClockTask {
  final String? id;
  String title;
  String category; // key of a TaskCategory (see CategoryController)
  String description;
  DateTime start;
  DateTime end;
  String status;
  bool alarmEnabled;
  int alarmMinutes;

  ClockTask({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.start,
    required this.end,
    this.status = 'pending',
    this.alarmEnabled = false,
    this.alarmMinutes = 10,
  });

  bool get isCompleted => status == 'completed';
  bool get isOvernight => end.day != start.day;
  int get durationMinutes => end.difference(start).inMinutes;
  int get startMinute => start.hour * 60 + start.minute;
  String get key => id ?? '$title-${start.millisecondsSinceEpoch}';
  String get timeRange =>
      '${formatHHmm(TimeOfDay.fromDateTime(start))}-${formatHHmm(TimeOfDay.fromDateTime(end))}';

  bool isActiveAt(DateTime now) => !isCompleted && now.isAfter(start) && now.isBefore(end);

  /// A task belongs to the day it was created and leaves the Clock at
  /// midnight, done or not — except an overnight task, which stays until it ends.
  bool isOnClock(DateTime now) => isSameDay(start, now) || (start.isBefore(now) && end.isAfter(now));

  /// Whether [minute] (0–1439, minutes since midnight) falls inside this task.
  bool coversMinute(int minute) {
    final offset = (minute - startMinute) % 1440;
    return offset >= 0 && offset < durationMinutes;
  }

  /// Builds start/end on [day] from two times; an end at or before the start
  /// means the task runs past midnight.
  static (DateTime, DateTime) rangeOn(DateTime day, TimeOfDay s, TimeOfDay e) {
    final start = DateTime(day.year, day.month, day.day, s.hour, s.minute);
    var end = DateTime(day.year, day.month, day.day, e.hour, e.minute);
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return (start, end);
  }

  static (DateTime, DateTime) todayRange(TimeOfDay s, TimeOfDay e) => rangeOn(DateTime.now(), s, e);

  static ClockTask? fromApi(Map<String, dynamic> m) {
    final parts = (m['timeRange'] ?? '').toString().split('-');
    if (parts.length != 2) return null;
    final s = parseHHmm(parts[0]);
    final e = parseHHmm(parts[1]);
    if (s == null || e == null) return null;
    // The task's day is the (local) day it was created.
    var day = DateTime.now();
    try {
      if (m['createdAt'] != null) day = DateTime.parse(m['createdAt'].toString()).toLocal();
    } catch (_) {}
    final (start, end) = rangeOn(day, s, e);
    var alarmEnabled = false;
    var alarmMinutes = 10;
    if (m['alarm'] is Map) {
      final alarm = m['alarm'] as Map;
      alarmEnabled = alarm['enabled'] == true;
      final mins = alarm['minutesBefore'];
      if (mins is num) alarmMinutes = mins.toInt();
    }
    final id = (m['_id'] ?? m['id'] ?? '').toString();
    final category = (m['category'] ?? 'self').toString().toLowerCase();
    return ClockTask(
      id: id.isEmpty ? null : id,
      title: (m['taskTitle'] ?? '').toString(),
      category: category.isEmpty ? 'self' : category,
      description: (m['description'] ?? '').toString(),
      start: start,
      end: end,
      status: (m['status'] ?? 'pending').toString(),
      alarmEnabled: alarmEnabled,
      alarmMinutes: alarmMinutes,
    );
  }

  Map<String, dynamic> toApi() => {
        'taskTitle': title,
        'category': category,
        'timeRange': timeRange,
        'description': description,
        'alarm': {'enabled': alarmEnabled, 'minutesBefore': alarmMinutes},
      };
}
