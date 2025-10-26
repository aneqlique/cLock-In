import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:clockin/presentation/screens/diary/diarytl_screen.dart';
import 'package:clockin/presentation/screens/settings/settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockin/core/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  final navigationKey = GlobalKey<CurvedNavigationBarState>();
  int index = 1;
  late final List<Widget> pages;
  final List<_Task> _tasks = [];
  DateTime _base = DateTime.now();

  @override
  void initState() {
    super.initState();
    pages = const <Widget>[
      DiarytlScreen(), 
      SizedBox.shrink(), 
      SettingsScreen(), 
    ];
    _loadTasks();
  }

  int _currentTaskIndex() {
    if (_tasks.isEmpty) return -1;
    final now = DateTime.now();
    for (var i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      final start = t.start;
      final end = start.add(Duration(minutes: t.durationMinutes));
      if (now.isAfter(start) && now.isBefore(end)) return i;
    }
    return -1;
  }

  List<PieChartSectionData> _sections(Color borderColor, double radius) {
    if (_tasks.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: const Color(0xFF2B2B2B),
          title: '',
          radius: radius,
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        )
      ];
    }
    const totalMinutes = 1440;
    final ci = _currentTaskIndex();

    final segs = <_ChartSeg>[];
    for (final t in _tasks) {
      final isCurrent = _tasks.indexOf(t) == ci;
      final startMin = _minutesSinceMidnight(t.start).toDouble();
      final endMin = _minutesSinceMidnight(t.end).toDouble();
      final clr = isCurrent ? const Color(0xFF3A3A3A) : Colors.transparent;
      if (t.end.day != t.start.day) {
        final dur = t.durationMinutes.toDouble();
        final midAbs = (startMin + dur / 2) % totalMinutes;
        final firstDur = (totalMinutes - startMin);
        final secondDur = endMin;
        final midInFirst = midAbs >= startMin;
        segs.add(_ChartSeg(start: startMin, duration: firstDur, color: clr, title: midInFirst ? t.title : ''));
        if (secondDur > 0) {
          segs.add(_ChartSeg(start: 0, duration: secondDur, color: clr, title: midInFirst ? '' : t.title));
        }
      } else {
        final dur = t.durationMinutes.toDouble();
        segs.add(_ChartSeg(start: startMin, duration: dur, color: clr, title: t.title));
      }
    }
    segs.sort((a, b) => a.start.compareTo(b.start));

    final sections = <PieChartSectionData>[];
    var cursor = 0.0;
    for (final s in segs) {
      final gap = ((s.start - cursor).clamp(0.0, totalMinutes.toDouble())).toDouble();
      if (gap > 0.0) {
        sections.add(PieChartSectionData(
          value: gap,
          color: Colors.transparent,
          title: '',
          radius: radius,
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ));
        cursor += gap;
      }
      sections.add(PieChartSectionData(
        value: s.duration,
        color: s.color,
        title: s.title,
        titleStyle: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
        radius: radius,
        borderSide: const BorderSide(color: Colors.transparent, width: 0),
      ));
      cursor += s.duration;
    }
    if (cursor < totalMinutes.toDouble()) {
      sections.add(PieChartSectionData(
        value: (totalMinutes.toDouble() - cursor),
        color: Colors.transparent,
        title: '',
        radius: radius,
        borderSide: const BorderSide(color: Colors.transparent, width: 0),
      ));
    }
    return sections;
  }

  void _openAddTask() async {
    final res = await showModalBottomSheet<_Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final titleCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        final startCtrl = TextEditingController();
        final endCtrl = TextEditingController();
        String category = 'School';
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('New Task', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white60)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'School', child: Text('School')),
                    DropdownMenuItem(value: 'Work', child: Text('Work')),
                    DropdownMenuItem(value: 'Self', child: Text('Self')),
                    DropdownMenuItem(value: 'House', child: Text('House')),
                  ],
                  onChanged: (v) => category = v ?? category,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white60)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                        _HhMmFormatter(),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Start (HH:mm)',
                        hintText: 'HH:mm',
                        helperText: '24-hour format',
                        helperStyle: const TextStyle(color: Colors.white38),
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white10,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white60)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                        _HhMmFormatter(),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'End (HH:mm)',
                        hintText: 'HH:mm',
                        helperText: '24-hour format',
                        helperStyle: const TextStyle(color: Colors.white38),
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white10,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white60)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white60)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final s = _parse24ToDateToday(startCtrl.text.trim());
                      final endParsed = _parse24ToDateToday(endCtrl.text.trim());
                      if (title.isEmpty || s == null || endParsed == null) {
                        await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Invalid Input'), content: const Text('Enter title and valid HH:mm start/end'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
                        return;
                      }
                      DateTime e = endParsed;
                      if (!e.isAfter(s)) {
                        e = e.add(const Duration(days: 1));
                      }
                      final color = _categoryColor(category);
                      final hasOverlap = _tasks.any((t) => s.isBefore(t.end) && e.isAfter(t.start));
                      if (hasOverlap) {
                        await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Overlap Detected'), content: const Text('Selected time overlaps with another task'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
                        return;
                      }
                      Navigator.pop(ctx, _Task(title: title, category: category, description: descCtrl.text.trim(), color: color, start: s, end: e, status: 'pending'));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Add Task'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (res != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';
        final startStr = _formatTOD(TimeOfDay(hour: res.start.hour, minute: res.start.minute));
        final endStr = _formatTOD(TimeOfDay(hour: res.end.hour % 24, minute: res.end.minute));
        final created = await ApiService.createTask(token, {
          'taskTitle': res.title,
          'category': res.category.toString().toLowerCase(),
          'timeRange': '$startStr-$endStr',
          'description': res.description,
          'status': res.status,
        });
        final id = (created['_id'] ?? created['id'] ?? '').toString();
        setState(() {
          _tasks.add(_Task(
            id: id.isEmpty ? null : id,
            title: res.title,
            category: res.category,
            description: res.description,
            color: res.color,
            start: res.start,
            end: res.end,
            status: (created['status'] ?? res.status).toString(),
          ));
        });
      } catch (_) {
        // Fallback: still add locally if API fails
        setState(() => _tasks.add(res));
      }
    }
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;
      final list = await ApiService.getTasks(token);
      final loaded = <_Task>[];
      for (final item in list) {
        if (item is Map) {
          final m = item.cast<String, dynamic>();
          final id = (m['_id'] ?? m['id'] ?? '').toString();
          final title = (m['taskTitle'] ?? '').toString();
          final category = (m['category'] ?? 'self').toString();
          final timeRange = (m['timeRange'] ?? '').toString();
          final description = (m['description'] ?? '').toString();
          final status = (m['status'] ?? 'pending').toString();
          final parts = timeRange.split('-');
          if (parts.length == 2) {
            final s = _parse24ToDateToday(parts[0].trim());
            final e0 = _parse24ToDateToday(parts[1].trim());
            if (s != null && e0 != null) {
              var e = e0;
              if (!e.isAfter(s)) e = e.add(const Duration(days: 1));
              loaded.add(_Task(
                id: id.isEmpty ? null : id,
                title: title,
                category: category[0].toUpperCase() + category.substring(1),
                description: description,
                color: _categoryColor(category[0].toUpperCase() + category.substring(1)),
                start: s,
                end: e,
                status: status,
              ));
            }
          }
        }
      }
      setState(() {
        _tasks
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // ignore load errors for now
    }
  }

  Future<void> _toggleTaskStatus(_Task t, bool completed) async {
    final old = t.status;
    setState(() {
      t.status = completed ? 'completed' : 'pending';
    });
    final id = t.id;
    if (id == null || id.isEmpty) return; // local only
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await ApiService.updateTask(token, id, {'status': t.status});
    } catch (_) {
      // revert on failure
      setState(() {
        t.status = old;
      });
    }
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'School':
        return const Color(0xFF2C2C2C);
      case 'Work':
        return const Color(0xFF1F1F1F);
      case 'Self':
        return const Color(0xFF262626);
      case 'House':
        return const Color(0xFF303030);
      default:
        return const Color(0xFF2B2B2B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.access_time, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ];
    return Scaffold(
      // extendBody: true,
      body: index == 1
          ? _buildClockTab(context)
          : pages[index],
      bottomNavigationBar: CurvedNavigationBar(
        key: navigationKey,
        height: 60,
        color: Colors.black,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: Colors.black,
        animationDuration: Duration(milliseconds: 400),
        items: items,
        index: index, 
        onTap: (index) => setState(() => this.index = index), // Handle navigation tap
      ),
      floatingActionButton: index == 1
          ? FloatingActionButton(
              onPressed: _openAddTask,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildClockTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = Colors.white.withOpacity(.15);
    final currentIdx = _currentTaskIndex();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            _formatDate(DateTime.now()),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final shortest = math.min(constraints.maxWidth, MediaQuery.of(context).size.height * 0.9);
              final size = shortest * 0.62;
              final pieRadius = (size / 2) - 8;
              return Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF151515),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 10, spreadRadius: 2)],
                        ),
                        child: PieChart(
                          PieChartData(
                            sections: _sections(borderColor, pieRadius),
                            startDegreeOffset: -90,
                            sectionsSpace: 0,
                            centerSpaceRadius: 0,
                          ),
                        ),
                      ),
                      Positioned.fill(child: _ClockOverlay()),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (currentIdx >= 0) _currentTaskChip(_tasks[currentIdx]) else const SizedBox(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: ([..._tasks]
                    ..sort((a, b) {
                      final aWrap = a.end.day != a.start.day;
                      final bWrap = b.end.day != b.start.day;
                      if (aWrap != bWrap) return aWrap ? 1 : -1;
                      return _minutesSinceMidnight(a.start).compareTo(_minutesSinceMidnight(b.start));
                    }))
                  .length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final sorted = [..._tasks]
                  ..sort((a, b) {
                    final aWrap = a.end.day != a.start.day;
                    final bWrap = b.end.day != b.start.day;
                    if (aWrap != bWrap) return aWrap ? 1 : -1;
                    return _minutesSinceMidnight(a.start).compareTo(_minutesSinceMidnight(b.start));
                  });
                final t = sorted[i];
                final tCurrent = currentIdx >= 0 ? _tasks[currentIdx] : null;
                final isCurrent = tCurrent != null && identical(t, tCurrent);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6, offset: const Offset(0,2))],
                  ),
                  child: ListTile(
                    leading: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: t.status == 'completed',
                        onChanged: (val) {
                          _toggleTaskStatus(t, val ?? false);
                        },
                        fillColor: MaterialStateProperty.all(isCurrent ? const Color(0xFF6B6B6B) : Colors.white),
                        checkColor: Colors.white,
                        side: BorderSide(color: Colors.black.withOpacity(.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${t.category} | ${_formatTime(t.start)} - ${_formatTime(t.end)}\n${t.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.more_vert, color: Colors.black45),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentTaskChip(_Task t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF3F3F3F), borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF6B6B6B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(.6), width: 1),
            ),
          ),
          const SizedBox(width: 10),
          Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final wd = weekdays[d.weekday - 1];
    final m = months[d.month - 1];
    return '$wd, $m ${d.day.toString().padLeft(2,'0')}';
  }

  String _formatTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m$ap';
  }

  int _minutesSinceNoon(DateTime dt) {
    final h = dt.hour % 12;
    return h * 60 + dt.minute;
  }

  String _formatTOD(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _minutesSinceMidnight(DateTime dt) => dt.hour * 60 + dt.minute;
  
  DateTime? _parse24ToDateToday(String input) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(input);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final mi = int.tryParse(m.group(2)!);
    if (h == null || mi == null) return null;
    if (h < 0 || h > 23 || mi < 0 || mi > 59) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, mi);
  }
}

class _Task {
  final String? id;
  final String title;
  final String category;
  final String description;
  final Color color;
  final DateTime start;
  final DateTime end;
  String status;
  int get durationMinutes => end.difference(start).inMinutes;
  _Task({this.id, required this.title, required this.category, required this.description, required this.color, required this.start, required this.end, this.status = 'pending'});
}

class _ChartSeg {
  final double start;
  final double duration;
  final Color color;
  final String title;
  _ChartSeg({required this.start, required this.duration, required this.color, required this.title});
}

class _HhMmFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String out = digits;
    if (digits.length >= 3) {
      out = digits.substring(0, 2) + ':' + digits.substring(2, digits.length > 4 ? 4 : digits.length);
    }
    if (digits.length <= 2) {
      out = digits;
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _ClockOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClockPainter(),
    );
  }
}

class _ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final tickPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1;

    final textPainter = (String text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      return tp;
    };

    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * math.pi - math.pi / 2;
      final inner = center + Offset(math.cos(angle) * (radius - 10), math.sin(angle) * (radius - 10));
      final outer = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(inner, outer, tickPaint);
      final hour = i; // 0-23 labels
      final showLabel = true;
      if (showLabel) {
        final tp = TextPainter(
          text: TextSpan(text: hour.toString(), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelPos = center + Offset(math.cos(angle) * (radius - 30), math.sin(angle) * (radius - 30));
        tp.paint(canvas, Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2));
      }
    }

    final now = DateTime.now();
    final hourAngle = (((now.hour % 24) * 60 + now.minute) / 1440) * 2 * math.pi - math.pi / 2;

    final hourPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final hourEnd = center + Offset(math.cos(hourAngle) * (radius - 40), math.sin(hourAngle) * (radius - 40));
    canvas.drawLine(center, hourEnd, hourPaint);

    final hub = Paint()..color = Colors.white;
    canvas.drawCircle(center, 3, hub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

