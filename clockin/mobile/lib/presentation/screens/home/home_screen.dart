import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:clockin/presentation/screens/diary/diarytl_screen.dart';
import 'package:clockin/presentation/screens/settings/settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

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

  List<PieChartSectionData> _sections(Color borderColor) {
    if (_tasks.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: const Color(0xFF2B2B2B),
          title: '',
          radius: 110,
          borderSide: BorderSide(color: borderColor, width: 1),
        )
      ];
    }
    const totalMinutes = 1440; // 24 hours
    final ci = _currentTaskIndex();
    final sorted = [..._tasks]
      ..sort((a, b) => _minutesSinceMidnight(a.start).compareTo(_minutesSinceMidnight(b.start)));
    final sections = <PieChartSectionData>[];
    var cursor = 0.0; // minutes accumulated
    for (var i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      final startMin = _minutesSinceMidnight(t.start).toDouble();
      final double gap = ((startMin - cursor).clamp(0.0, totalMinutes.toDouble())).toDouble();
      if (gap > 0.0) {
        sections.add(PieChartSectionData(
          value: gap,
          color: const Color(0xFF151515),
          title: '',
          radius: 110,
          borderSide: BorderSide(color: borderColor, width: 1),
        ));
        cursor += gap;
      }
      final isCurrent = _tasks.indexOf(t) == ci;
      final double dur = t.durationMinutes.toDouble();
      sections.add(PieChartSectionData(
        value: dur,
        color: isCurrent ? const Color(0xFF3A3A3A) : t.color,
        title: t.title,
        titleStyle: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
        radius: 110,
        borderSide: BorderSide(color: borderColor, width: 1),
      ));
      cursor += dur;
    }
    if (cursor < totalMinutes.toDouble()) {
      sections.add(PieChartSectionData(
        value: (totalMinutes.toDouble() - cursor),
        color: const Color(0xFF151515),
        title: '',
        radius: 110,
        borderSide: BorderSide(color: borderColor, width: 1),
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
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Start (HH:mm)',
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
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'End (HH:mm)',
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
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final s = _parse24ToDateToday(startCtrl.text.trim());
                      final e = _parse24ToDateToday(endCtrl.text.trim());
                      if (title.isEmpty || s == null || e == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter title and valid HH:mm start/end')));
                        return;
                      }
                      final color = _categoryColor(category);
                      if (!e.isAfter(s)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
                        return;
                      }
                      final hasOverlap = _tasks.any((t) => s.isBefore(t.end) && e.isAfter(t.start));
                      if (hasOverlap) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected time overlaps with another task')));
                        return;
                      }
                      Navigator.pop(ctx, _Task(title: title, category: category, description: descCtrl.text.trim(), color: color, start: s, end: e));
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
      setState(() => _tasks.add(res));
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
      extendBody: true,
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
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF151515),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: PieChart(
                      PieChartData(
                        sections: _sections(borderColor),
                        startDegreeOffset: -90,
                        sectionsSpace: 0,
                        centerSpaceRadius: 16,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: _ClockOverlay()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (currentIdx >= 0) _currentTaskChip(_tasks[currentIdx]) else const SizedBox(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final t = _tasks[i];
                final isCurrent = i == currentIdx;
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
                        value: false,
                        onChanged: (_) {},
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
  final String title;
  final String category;
  final String description;
  final Color color;
  final DateTime start;
  final DateTime end;
  int get durationMinutes => end.difference(start).inMinutes;
  _Task({required this.title, required this.category, required this.description, required this.color, required this.start, required this.end});
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
    final minuteAngle = (now.minute / 60) * 2 * math.pi - math.pi / 2;
    final hourAngle = (((now.hour % 24) * 60 + now.minute) / 1440) * 2 * math.pi - math.pi / 2;

    final minutePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final hourPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final minuteEnd = center + Offset(math.cos(minuteAngle) * (radius - 26), math.sin(minuteAngle) * (radius - 26));
    final hourEnd = center + Offset(math.cos(hourAngle) * (radius - 40), math.sin(hourAngle) * (radius - 40));
    canvas.drawLine(center, hourEnd, hourPaint);
    canvas.drawLine(center, minuteEnd, minutePaint);

    final hub = Paint()..color = Colors.white;
    canvas.drawCircle(center, 3, hub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

