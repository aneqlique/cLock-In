import 'package:flutter/material.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];
String monthShort(DateTime d) => _months[d.month - 1];

/// "Tue, Oct 27"
String formatDayLong(DateTime d) => '${weekdayShort(d)}, ${monthShort(d)} ${d.day}';

/// Whether the user chose 24-hour time (set app-wide in ClockInApp.builder).
bool use24hOf(BuildContext context) => MediaQuery.alwaysUse24HourFormatOf(context);

/// "2:05 PM", or "14:05" in 24-hour mode.
String formatClock(DateTime d, {bool use24h = false}) {
  final m = d.minute.toString().padLeft(2, '0');
  if (use24h) return '${d.hour.toString().padLeft(2, '0')}:$m';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

/// Dial label for an hour: "06" in 24-hour mode, "6a" / "12p" otherwise.
String formatHourLabel(int hour, {bool use24h = false}) {
  if (use24h) return hour.toString().padLeft(2, '0');
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h${hour < 12 ? 'a' : 'p'}';
}

/// "14:05" — the format stored in a task's timeRange.
String formatHHmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Parses "HH:mm" (24h). Returns null for anything else.
TimeOfDay? parseHHmm(String input) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(input.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final mi = int.parse(m.group(2)!);
  if (h > 23 || mi > 59) return null;
  return TimeOfDay(hour: h, minute: mi);
}

/// "09:00-10:30" → "9:00 AM – 10:30 AM" (falls back to the raw text).
String formatTimeRange(String timeRange, {bool use24h = false}) {
  final parts = timeRange.split('-');
  if (parts.length != 2) return timeRange;
  final s = parseHHmm(parts[0]);
  final e = parseHHmm(parts[1]);
  if (s == null || e == null) return timeRange;
  final base = DateTime(2000);
  String f(TimeOfDay t) => formatClock(base.add(Duration(hours: t.hour, minutes: t.minute)), use24h: use24h);
  return '${f(s)} – ${f(e)}';
}

/// "2h 30m", "45m"
String formatDuration(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String greetingFor(DateTime d) {
  if (d.hour < 5) return 'Good night';
  if (d.hour < 12) return 'Good morning';
  if (d.hour < 18) return 'Good afternoon';
  return 'Good evening';
}

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "now", "5m", "3h", "Yesterday", "4d", "10.12.2025"
String timeAgo(String isoDate) {
  if (isoDate.isEmpty) return '';
  try {
    final date = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}.${date.day}.${date.year}';
  } catch (_) {
    return '';
  }
}
