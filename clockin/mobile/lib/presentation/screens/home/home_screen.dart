import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:clockin/presentation/screens/diary/diarytl_screen.dart';
import 'package:clockin/presentation/screens/settings/settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockin/core/services/api_service.dart';
import 'package:clockin/core/services/notifications_service.dart';
import 'package:clockin/presentation/screens/home/task_list_view.dart';

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
  final Set<String> _hidden = <String>{};
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
    _loadHidden();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (dctx) => Theme(
        data: Theme.of(dctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
        ),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          contentTextStyle: const TextStyle(color: Colors.white70),
          title: const Text('Delete task?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx, false), style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dctx, true), style: TextButton.styleFrom(foregroundColor: Colors.white), child: const Text('Delete')),
          ],
        ),
      ),
    );
    return res == true;
  }

  Future<void> _openEditTask(_Task t) async {
    final titleCtrl = TextEditingController(text: t.title);
    final descCtrl = TextEditingController(text: t.description);
    final startCtrl = TextEditingController(text: _formatTOD(TimeOfDay(hour: t.start.hour, minute: t.start.minute)));
    final endCtrl = TextEditingController(text: _formatTOD(TimeOfDay(hour: t.end.hour % 24, minute: t.end.minute)));
    String category = t.category; // Already capitalized
    bool alarmEnabled = t.alarmEnabled;
    int alarmMinutes = t.alarmMinutes;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Edit Task', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white60)),
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
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white60)),
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
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white60)),
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
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white60)),
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
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white60)),
                  ),
                ),
                const SizedBox(height: 16),
                // Alarm Settings
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.alarm, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Alarm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('Set Alarm', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Get notified before task ends', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        value: alarmEnabled,
                        onChanged: (value) {
                          setModalState(() => alarmEnabled = value);
                        },
                        activeColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (alarmEnabled) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: alarmMinutes,
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Remind me before',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white10,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white60),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                            DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                            DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                            DropdownMenuItem(value: 60, child: Text('1 hour before')),
                          ],
                          onChanged: (value) {
                            setModalState(() => alarmMinutes = value ?? 10);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final s = _parse24ToDateToday(startCtrl.text.trim());
                      final e0 = _parse24ToDateToday(endCtrl.text.trim());
                      String? err;
                      if (title.isEmpty) err = 'Please enter a title';
                      if (s == null) err = 'Start time must be in HH:mm (24h)';
                      if (e0 == null) err = 'End time must be in HH:mm (24h)';
                      if (err != null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err!)));
                        }
                        return;
                      }
                      DateTime start = s!;
                      DateTime end = e0!;
                      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token') ?? '';
                        final startStr = _formatTOD(TimeOfDay(hour: start.hour, minute: start.minute));
                        final endStr = _formatTOD(TimeOfDay(hour: end.hour % 24, minute: end.minute));
                        await ApiService.updateTask(token, t.id ?? '', {
                          'taskTitle': title,
                          'category': category.toLowerCase(),
                          'timeRange': '$startStr-$endStr',
                          'description': descCtrl.text.trim(),
                          'alarm': {
                            'enabled': alarmEnabled,
                            'minutesBefore': alarmMinutes,
                          },
                        });
                        
                        // Schedule alarm if enabled
                        if (alarmEnabled) {
                          _scheduleTaskAlarm(t.id ?? '', title, end, alarmMinutes);
                        }
                        setState(() {
                          final i = _tasks.indexOf(t);
                          final oldStatus = t.status;
                          if (i >= 0) {
                            _tasks[i] = _Task(
                              id: t.id,
                              title: title,
                              category: category,
                              description: descCtrl.text.trim(),
                              color: _categoryColor(category),
                              start: start,
                              end: end,
                              status: oldStatus,
                              alarmEnabled: alarmEnabled,
                              alarmMinutes: alarmMinutes,
                            );
                          }
                        });
                        if (mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: ${e.toString()}')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Save Changes'),
                  ),
                ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (updated == true) {
      setState(() {});
    }
  }

  Future<void> _deleteTask(_Task t) async {
    final idx = _tasks.indexOf(t);
    if (idx < 0) return;
    final removed = t;
    setState(() {
      _tasks.removeAt(idx);
    });
    final id = removed.id;
    if (id == null || id.isEmpty) return; // local-only task
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await ApiService.deleteTask(token, id);
    } catch (_) {
      // rollback
      setState(() {
        _tasks.insert(idx, removed);
      });
    }
  }

  int _currentTaskIndex() {
    if (_tasks.isEmpty) return -1;
    final now = DateTime.now();
    for (var i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      // Only consider tasks that are not completed
      if (t.status == 'completed') continue;
      
      final start = t.start;
      final end = t.end; // Use the actual end time, not calculated
      
      // Check if current time is within the task's time range
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
    for (final t in _tasks.where((t) => !_hidden.contains(_taskKey(t)))) {
      final isCurrent = _tasks.indexOf(t) == ci;
      final startMin = _minutesSinceMidnight(t.start).toDouble();
      final endMin = _minutesSinceMidnight(t.end).toDouble();
      final clr = (isCurrent && t.status != 'completed') ? const Color(0xFF4A4A4A) : Colors.transparent;
      final lbl = t.status == 'completed' ? '' : t.title;
      if (t.end.day != t.start.day) {
        final dur = t.durationMinutes.toDouble();
        final midAbs = (startMin + dur / 2) % totalMinutes;
        final firstDur = (totalMinutes - startMin);
        final secondDur = endMin;
        final midInFirst = midAbs >= startMin;
        segs.add(_ChartSeg(start: startMin, duration: firstDur, color: clr, title: midInFirst ? lbl : ''));
        if (secondDur > 0) {
          segs.add(_ChartSeg(start: 0, duration: secondDur, color: clr, title: midInFirst ? '' : lbl));
        }
      } else {
        final dur = t.durationMinutes.toDouble();
        segs.add(_ChartSeg(start: startMin, duration: dur, color: clr, title: lbl));
      }
    }
    segs.sort((a, b) => a.start.compareTo(b.start));

    final sections = <PieChartSectionData>[];
    var cursor = 0.0;
    // Precompute mid angles for staggering labels to reduce overlap
    final mids = <double>[]; // store radians of previous labeled sections
    const double twoPi = 2 * math.pi;
    const double threshold = 0.20; // ~11.5 degrees separation
    const double baseOffset = 0.50; // slightly inward from the edge
    const double bumpOffset = 0.62; // inward even when staggered
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
      // Compute stagger offset for this label if it exists
      double tOffset = baseOffset;
      if (s.title.isNotEmpty) {
        final midMinute = (s.start + s.duration / 2.0) % totalMinutes;
        final midAngle = (midMinute / totalMinutes) * twoPi; // radians
        // Check proximity with previous labels
        for (final prev in mids) {
          final d = (midAngle - prev).abs();
          final dist = d > math.pi ? (twoPi - d) : d;
          if (dist < threshold) {
            tOffset = bumpOffset; // push farther out to avoid overlap
            break;
          }
        }
        mids.add(midAngle);
      }
      sections.add(PieChartSectionData(
        value: s.duration,
        color: s.color,
        title: s.title,
        titleStyle: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
        titlePositionPercentageOffset: tOffset,
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
    // Persist controllers across rebuilds of the bottom sheet to prevent clearing values
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    String category = 'School';
    bool alarmEnabled = false;
    int alarmMinutes = 10;
    final res = await showModalBottomSheet<_Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    // Alarm settings
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.alarm, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              const Text('Set Alarm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Switch(
                                value: alarmEnabled,
                                onChanged: (value) {
                                  setModalState(() {
                                    alarmEnabled = value;
                                  });
                                },
                                activeColor: Colors.white,
                              ),
                            ],
                          ),
                          if (alarmEnabled) ...[
                            const SizedBox(height: 8),
                            const Text('Remind me before:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: alarmMinutes,
                              items: const [
                                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                                DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                                DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                                DropdownMenuItem(value: 60, child: Text('1 hour before')),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  alarmMinutes = value ?? 10;
                                });
                              },
                              dropdownColor: Colors.black,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white10,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white24)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white60)),
                              ),
                            ),
                          ],
                        ],
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
                      String? err;
                      final catNorm = (category.trim().toLowerCase());
                      const allowed = ['school','work','self','house'];
                      if (title.isEmpty) err = 'Please enter a title';
                      else if (!allowed.contains(catNorm)) err = 'Please select a valid category';
                      else if (s == null) err = 'Start time must be in HH:mm (24h)';
                      else if (endParsed == null) err = 'End time must be in HH:mm (24h)';
                      if (err != null) {
                        await showDialog(
                          context: context,
                          builder: (dctx) => Theme(
                            data: Theme.of(dctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.white,
                                secondary: Colors.white,
                                surface: Color(0xFF1E1E1E),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: AlertDialog(
                              backgroundColor: const Color(0xFFEAE6E0),
                              title: const Text('Invalid input'),
                              content: Text(err!),
                              actions: [TextButton(onPressed: () => Navigator.pop(dctx),  child: const Text('OK'
                              ,style: TextStyle(color: Colors.black),))],
                            ),
                          ),
                        );
                        return;
                      }
                      final DateTime sdt = s!;
                      final DateTime edt = endParsed!;
                      DateTime e = edt;
                      if (!e.isAfter(sdt)) {
                        e = e.add(const Duration(days: 1));
                      }
                      final color = _categoryColor(category);
                      final overlaps = _tasks.where((t) => sdt.isBefore(t.end) && e.isAfter(t.start)).toList();
                      if (overlaps.isNotEmpty) {
                        final hasPending = overlaps.any((t) => t.status != 'completed');
                        if (hasPending) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Overlap Detected'),
                              content: const Text('The selected time overlaps with an active task. Please pick a different time.'),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                            ),
                          );
                          return;
                        }
                        final hasCompletedVisible = overlaps.any((t) => t.status == 'completed' && !_hidden.contains(_taskKey(t)));
                        if (hasCompletedVisible) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Completed Task Visible'),
                              content: const Text('This time range overlaps with a completed task that is still shown. Please hide the completed task before creating a new one in this time range.'),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                            ),
                          );
                          return;
                        }
                        // All overlapping tasks are completed and hidden -> allow
                      }
                      Navigator.pop(ctx, _Task(
                        title: title, 
                        category: category, 
                        description: descCtrl.text.trim(), 
                        color: color, 
                        start: sdt, 
                        end: e, 
                        status: 'pending',
                        alarmEnabled: alarmEnabled,
                        alarmMinutes: alarmMinutes,
                      ));
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
          'alarm': {
            'enabled': res.alarmEnabled,
            'minutesBefore': res.alarmMinutes,
          },
        });
        final id = (created['_id'] ?? created['id'] ?? '').toString();
        
        // Schedule alarm if enabled
        if (res.alarmEnabled && id.isNotEmpty) {
          _scheduleTaskAlarm(id, res.title, res.end, res.alarmMinutes);
        }
        
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
            alarmEnabled: res.alarmEnabled,
            alarmMinutes: res.alarmMinutes,
          ));
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create task: ${e.toString()}')));
        }
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
          
          // Parse alarm data
          bool alarmEnabled = false;
          int alarmMinutes = 10;
          if (m['alarm'] != null && m['alarm'] is Map) {
            final alarm = m['alarm'] as Map;
            alarmEnabled = alarm['enabled'] ?? false;
            alarmMinutes = alarm['minutesBefore'] ?? 10;
          }
          
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
                alarmEnabled: alarmEnabled,
                alarmMinutes: alarmMinutes,
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
      
      // Refresh task list view to show updated completed tasks
      _refreshTaskListView();
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
      
      // Add completedAt timestamp when completing task
      final updateData = {'status': t.status};
      if (completed) {
        updateData['completedAt'] = DateTime.now().toIso8601String();
      }
      
      await ApiService.updateTask(token, id, updateData);
      
      // Refresh task list view to show completed tasks
      _refreshTaskListView();
    } catch (_) {
      // revert on failure
      setState(() {
        t.status = old;
      });
    }
  }
  
  void _refreshTaskListView() {
    // This method will trigger a refresh when the user navigates to task list view
    // The actual refresh happens in TaskListView's initState and when user pulls to refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Force a rebuild to update any listeners
        setState(() {});
      }
    });
  }
  
  void _scheduleTaskAlarm(String taskId, String taskTitle, DateTime taskEnd, int minutesBefore) {
    // Calculate alarm time
    final alarmTime = taskEnd.subtract(Duration(minutes: minutesBefore));
    
    // Only schedule if alarm time is in the future
    if (alarmTime.isAfter(DateTime.now())) {
      // Use the notification service to schedule the alarm
      NotificationService.scheduleTaskReminder(
        taskId: taskId,
        taskTitle: taskTitle,
        reminderTime: alarmTime,
      );
      
      print('Alarm scheduled for "$taskTitle" at $alarmTime (${minutesBefore} minutes before end)');
    } else {
      print('Alarm time $alarmTime is in the past, not scheduling');
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAE6E0),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_book_rounded, color: Colors.black),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskListView()));
          },
          tooltip: 'Completed Tasks',
        ),
      ),
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
        animationDuration: Duration(milliseconds: 500),
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
            _formatDateWithTime(DateTime.now()),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final halfHeight = screenHeight * 0.37; // nearly half screen
              final size = math.min(constraints.maxWidth, halfHeight);
              final pieRadius = (size / 2) - 8;
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
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
                        Positioned.fill(child: _ClockOverlay(
                          currentTask: currentIdx >= 0 ? _tasks[currentIdx] : null,
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (currentIdx >= 0 && !_hidden.contains(_taskKey(_tasks[currentIdx])))
            _currentTaskChip(_tasks[currentIdx])
          else
            const SizedBox(),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.separated(
              itemCount: ([..._tasks]
                    ..sort((a, b) {
                      final aWrap = a.end.day != a.start.day;
                      final bWrap = b.end.day != b.start.day;
                      if (aWrap != bWrap) return aWrap ? 1 : -1;
                      return _minutesSinceMidnight(a.start).compareTo(_minutesSinceMidnight(b.start));
                    }))
                  .where((t) => !_hidden.contains(_taskKey(t)))
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
                final visible = sorted.where((t) => !_hidden.contains(_taskKey(t))).toList();
                final t = visible[i];
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
                        checkColor: Colors.black,
                        side: BorderSide(color: Colors.black.withOpacity(.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    title: Row(
                      children: [
                        if (t.alarmEnabled) ...[
                          const Icon(Icons.alarm, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            t.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: t.status == 'completed' ? TextDecoration.lineThrough : TextDecoration.none,
                              color: t.status == 'completed' ? Colors.black54 : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${t.category} | ${_formatTime(t.start)} - ${_formatTime(t.end)}\n${t.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.status == 'completed' ? Colors.black54 : Colors.black87,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'More',
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      icon: const Icon(Icons.more_vert, color: Colors.black45),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openEditTask(t);
                        } else if (value == 'delete') {
                          final ok = await _confirmDelete(context);
                          if (ok) await _deleteTask(t);
                        } else if (value == 'hide') {
                          setState(() => _hidden.add(_taskKey(t)));
                          await _saveHidden();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task hidden')));
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: const [Icon(Icons.edit, color: Colors.black54), SizedBox(width: 8), Text('Edit')]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: const [Icon(Icons.delete, color: Colors.black54), SizedBox(width: 8), Text('Delete')]),
                        ),
                        if (t.status == 'completed')
                          PopupMenuItem(
                            value: 'hide',
                            child: Row(children: const [Icon(Icons.visibility_off, color: Colors.black54), SizedBox(width: 8), Text('Hide')]),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
          Transform.scale(
            scale: 0.95,
            child: Checkbox(
              value: t.status == 'completed',
              onChanged: (val) => _toggleTaskStatus(t, val ?? false),
              fillColor: MaterialStateProperty.all(const Color(0xFF6B6B6B)),
              checkColor: Colors.black,
              side: BorderSide(color: Colors.white.withOpacity(.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 10),
          Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatDateWithTime(DateTime d) {
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final wd = weekdays[d.weekday - 1];
    final m = months[d.month - 1];
    final hh = (d.hour % 12 == 0 ? 12 : d.hour % 12).toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '$wd, $m ${d.day.toString().padLeft(2,'0')} |  $hh:$mm$ap';
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
  String _taskKey(_Task t) => t.id ?? '${t.title}-${t.start.millisecondsSinceEpoch}';
  String _hiddenPrefsKey(String userId) => 'hidden_'
      '${userId.isNotEmpty ? userId : 'guest'}';
  
  Future<void> _loadHidden() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? 'guest';
      final key = _hiddenPrefsKey(userId);
      final list = prefs.getStringList(key) ?? const <String>[];
      setState(() {
        _hidden
          ..clear()
          ..addAll(list);
      });
    } catch (_) {}
  }

  Future<void> _saveHidden() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? 'guest';
      final key = _hiddenPrefsKey(userId);
      await prefs.setStringList(key, _hidden.toList());
    } catch (_) {}
  }
  
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
  bool alarmEnabled;
  int alarmMinutes;
  int get durationMinutes => end.difference(start).inMinutes;
  _Task({
    this.id, 
    required this.title, 
    required this.category, 
    required this.description, 
    required this.color, 
    required this.start, 
    required this.end, 
    this.status = 'pending',
    this.alarmEnabled = false,
    this.alarmMinutes = 10,
  });
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
  final _Task? currentTask;
  
  const _ClockOverlay({this.currentTask});
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClockPainter(currentTask: currentTask),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final _Task? currentTask;
  
  _ClockPainter({this.currentTask});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    // Draw active task shading first (behind other elements)
    if (currentTask != null && currentTask!.status != 'completed') {
      _drawActiveTaskShade(canvas, center, radius);
    }
    
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
          text: TextSpan(text: hour.toString(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
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
  
  void _drawActiveTaskShade(Canvas canvas, Offset center, double radius) {
    if (currentTask == null) return;
    
    final task = currentTask!;
    const totalMinutes = 1440.0;
    
    // Calculate task start and end minutes since midnight
    final startMinutes = _minutesSinceMidnight(task.start);
    final endMinutes = _minutesSinceMidnight(task.end);
    
    // Convert to angles (0 degrees = 12 o'clock, clockwise)
    final startAngle = (startMinutes / totalMinutes) * 2 * math.pi - math.pi / 2;
    final endAngle = (endMinutes / totalMinutes) * 2 * math.pi - math.pi / 2;
    
    // Calculate sweep angle, handling day wrap-around
    double sweepAngle;
    if (task.end.day != task.start.day) {
      // Task spans across days
      sweepAngle = (totalMinutes - startMinutes + endMinutes) / totalMinutes * 2 * math.pi;
    } else {
      sweepAngle = (endMinutes - startMinutes) / totalMinutes * 2 * math.pi;
    }
    
    // Create gradient paint for the active task shade using app theme colors
    final shadePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withOpacity(0.3),
          Colors.black.withOpacity(0.2),
          Colors.black.withOpacity(0.1),
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    // Draw the active task arc shade (larger area)
    final rect = Rect.fromCircle(center: center, radius: radius - 10);
    canvas.drawArc(rect, startAngle, sweepAngle, true, shadePaint);
    
    // Add a border highlight using app theme color
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawArc(rect, startAngle, sweepAngle, false, borderPaint);
  }
  
  int _minutesSinceMidnight(DateTime dt) {
    return dt.hour * 60 + dt.minute;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

