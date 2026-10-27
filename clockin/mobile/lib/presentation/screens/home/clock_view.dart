import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/theme.dart';
import '../../../core/models/clock_task.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/state/data_sync.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/state/category_controller.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/clock_pie_chart.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/task_card.dart';
import '../diary/diary_post_modal.dart';

/// The Clock tab: greeting, the 24h dial and today's tasks.
class ClockView extends StatefulWidget {
  const ClockView({super.key});

  @override
  State<ClockView> createState() => ClockViewState();
}

class ClockViewState extends State<ClockView> with WidgetsBindingObserver {
  final List<ClockTask> _tasks = [];
  final Set<String> _hidden = <String>{};
  bool _loading = true;
  String _firstName = '';
  DateTime _now = DateTime.now();
  Timer? _ticker;
  DataSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTasks();
    _loadHidden();
    _loadName();
    // Keep the dial hand and header time live; redraw only when the minute changes.
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();
      if (mounted && now.minute != _now.minute) setState(() => _now = now);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sync == null) {
      _sync = context.read<DataSync>();
      _sync!.addListener(_onSync);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sync?.removeListener(_onSync);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _now = DateTime.now());
      _loadTasks();
    }
  }

  void _onSync() {
    if (_sync?.source == this) return;
    _loadTasks();
    _loadName();
  }

  void _notifyOthers() => _sync?.bump(this);

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ---------------------------------------------------------------- data

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _firstName = prefs.getString('firstName') ?? '');
  }

  Future<void> _loadTasks() async {
    try {
      final token = await _token();
      if (token.isEmpty) return;
      final list = await ApiService.getTasks(token);
      final loaded = <ClockTask>[];
      for (final item in list) {
        if (item is Map) {
          final t = ClockTask.fromApi(item.cast<String, dynamic>());
          if (t != null) loaded.add(t);
        }
      }
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // Keep whatever is on screen; pull-to-refresh retries.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _hiddenPrefsKey(String userId) => 'hidden_${userId.isNotEmpty ? userId : 'guest'}';

  Future<void> _loadHidden() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_hiddenPrefsKey(prefs.getString('id') ?? 'guest')) ?? const <String>[];
      if (!mounted) return;
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
      await prefs.setStringList(_hiddenPrefsKey(prefs.getString('id') ?? 'guest'), _hidden.toList());
    } catch (_) {}
  }

  /// Tasks that belong on today's clock (auto-hides earlier days' tasks).
  List<ClockTask> get _onClock => _tasks.where((t) => t.isOnClock(_now)).toList();

  List<ClockTask> get _visible {
    final v = _onClock.where((t) => !_hidden.contains(t.key)).toList()
      ..sort((a, b) {
        if (a.isOvernight != b.isOvernight) return a.isOvernight ? 1 : -1;
        return a.startMinute.compareTo(b.startMinute);
      });
    return v;
  }

  ClockTask? _currentOf(List<ClockTask> visible) {
    for (final t in visible) {
      if (t.isActiveAt(_now)) return t;
    }
    return null;
  }

  ClockTask? _nextOf(List<ClockTask> visible) {
    final upcoming = visible.where((t) => !t.isCompleted && t.start.isAfter(_now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  // ------------------------------------------------------------- actions

  Future<void> _toggle(ClockTask t, bool completed) async {
    final old = t.status;
    setState(() => t.status = completed ? 'completed' : 'pending');
    final id = t.id;
    if (id == null || id.isEmpty) return; // local-only task
    try {
      final updates = <String, dynamic>{'status': t.status};
      if (completed) updates['completedAt'] = DateTime.now().toIso8601String();
      final updated = await ApiService.updateTask(await _token(), id, updates);
      _notifyOthers();
      if (completed && mounted) {
        showAppSnack(
          context,
          'Nice! "${t.title}" is done.',
          actionLabel: 'Add to journal',
          onAction: () => _openJournalFor(updated),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => t.status = old);
      showAppSnack(context, 'Couldn\'t update the task. ${friendlyError(e)}');
    }
  }

  void _openJournalFor(Map<String, dynamic> data) {
    if (!mounted) return;
    showJournalEntrySheet(
      context,
      data: data,
      startEditing: true,
      onUpdated: (_) => _notifyOthers(),
      onDelete: (id) async {
        await ApiService.deleteTask(await _token(), id);
        if (!mounted) return;
        setState(() => _tasks.removeWhere((t) => t.id == id));
        _notifyOthers();
      },
    );
  }

  Future<bool> _confirmDelete() => showConfirmDialog(
        context,
        title: 'Delete task?',
        message: 'This action cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true,
      );

  Future<void> _deleteTask(ClockTask t) async {
    final idx = _tasks.indexOf(t);
    if (idx < 0) return;
    setState(() => _tasks.removeAt(idx));
    final id = t.id;
    if (id == null || id.isEmpty) return; // local-only task
    try {
      await ApiService.deleteTask(await _token(), id);
      _notifyOthers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _tasks.insert(idx.clamp(0, _tasks.length), t));
      showAppSnack(context, 'Couldn\'t delete the task. ${friendlyError(e)}');
    }
  }

  Future<void> _hide(ClockTask t) async {
    setState(() => _hidden.add(t.key));
    await _saveHidden();
    if (!mounted) return;
    showAppSnack(context, 'Task hidden', actionLabel: 'Undo', onAction: () async {
      setState(() => _hidden.remove(t.key));
      await _saveHidden();
    });
  }

  Future<void> _unhideAll() async {
    setState(() => _hidden.removeWhere((k) => _onClock.any((t) => t.key == k)));
    await _saveHidden();
  }

  void _scheduleTaskAlarm(String taskId, String taskTitle, DateTime taskEnd, int minutesBefore) {
    final alarmTime = taskEnd.subtract(Duration(minutes: minutesBefore));
    if (alarmTime.isAfter(DateTime.now())) {
      NotificationService.scheduleTaskReminder(taskId: taskId, taskTitle: taskTitle, reminderTime: alarmTime);
    }
  }

  /// Opens the "New task" sheet. Public so the shell's add button can call it.
  Future<void> openAddTask() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TaskSheet(
        existing: null,
        tasks: _onClock,
        hidden: _hidden,
        onSubmit: (draft) async {
          final (start, end) = ClockTask.todayRange(draft.start, draft.end);
          final task = ClockTask(
            title: draft.title,
            category: draft.category,
            description: draft.description,
            start: start,
            end: end,
            alarmEnabled: draft.alarmEnabled,
            alarmMinutes: draft.alarmMinutes,
          );
          try {
            final created = await ApiService.createTask(await _token(), {...task.toApi(), 'status': 'pending'});
            final id = (created['_id'] ?? created['id'] ?? '').toString();
            final saved = ClockTask(
              id: id.isEmpty ? null : id,
              title: task.title,
              category: task.category,
              description: task.description,
              start: start,
              end: end,
              status: (created['status'] ?? 'pending').toString(),
              alarmEnabled: task.alarmEnabled,
              alarmMinutes: task.alarmMinutes,
            );
            if (saved.alarmEnabled && id.isNotEmpty) {
              _scheduleTaskAlarm(id, saved.title, saved.end, saved.alarmMinutes);
            }
            if (mounted) setState(() => _tasks.add(saved));
            _notifyOthers();
          } catch (e) {
            // Fallback: still add locally if the API fails.
            if (mounted) {
              setState(() => _tasks.add(task));
              showAppSnack(context, 'Saved on this device only. ${friendlyError(e)}');
            }
          }
          return null;
        },
      ),
    );
  }

  Future<void> _openEdit(ClockTask t) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TaskSheet(
        existing: t,
        tasks: _onClock,
        hidden: _hidden,
        onSubmit: (draft) async {
          // Editing keeps the task on its own day.
          final (start, end) = ClockTask.rangeOn(t.start, draft.start, draft.end);
          final next = ClockTask(
            id: t.id,
            title: draft.title,
            category: draft.category,
            description: draft.description,
            start: start,
            end: end,
            status: t.status,
            alarmEnabled: draft.alarmEnabled,
            alarmMinutes: draft.alarmMinutes,
          );
          try {
            await ApiService.updateTask(await _token(), t.id ?? '', next.toApi());
          } catch (e) {
            return 'Failed to update: ${friendlyError(e)}';
          }
          if (next.alarmEnabled) _scheduleTaskAlarm(t.id ?? '', next.title, next.end, next.alarmMinutes);
          if (mounted) {
            setState(() {
              final i = _tasks.indexOf(t);
              if (i >= 0) _tasks[i] = next;
            });
          }
          _notifyOthers();
          return null;
        },
      ),
    );
  }

  // ----------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final visible = _visible;
    final current = _currentOf(visible);
    final hiddenCount = _onClock.where((t) => _hidden.contains(t.key)).length;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(child: _header(visible)),
            ),
            SliverToBoxAdapter(child: _dial(visible, current)),
            SliverToBoxAdapter(child: _legend(visible)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('Today', style: context.tt.titleLarge),
                    const SizedBox(width: 8),
                    if (visible.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('${visible.length}', style: context.tt.labelMedium),
                      ),
                    const Spacer(),
                    if (hiddenCount > 0)
                      TextButton.icon(
                        onPressed: _unhideAll,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text('Show $hiddenCount hidden'),
                      ),
                  ],
                ),
              ),
            ),
            if (_loading)
              SliverToBoxAdapter(child: _skeletonList())
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.schedule_rounded,
                  title: 'Your day is wide open',
                  message: 'Add tasks to see them on your clock.',
                  actionLabel: 'Add a task',
                  actionIcon: Icons.add_rounded,
                  onAction: openAddTask,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _swipeable(visible[i], identical(visible[i], current)),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 96)),
          ],
        ),
      ),
    );
  }

  Widget _header(List<ClockTask> visible) {
    final cs = context.cs;
    final done = visible.where((t) => t.isCompleted).length;
    final total = visible.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${greetingFor(_now)},', style: context.tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                    Text(
                      _firstName.isEmpty ? 'there' : _firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.headlineMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(formatDayLong(_now), style: context.tt.labelLarge),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text('$done of $total done today', style: context.tt.labelLarge),
                const Spacer(),
                Text(
                  '${(done / total * 100).round()}%',
                  style: context.tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: done / total),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dial(List<ClockTask> visible, ClockTask? current) {
    final screenH = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: screenH * 0.42),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12)),
                ],
              ),
              child: ClockDial(
                tasks: visible,
                current: current,
                now: _now,
                onTaskTap: (t) {
                  HapticFeedback.selectionClick();
                  _openEdit(t);
                },
                center: _dialCenter(visible, current),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialCenter(List<ClockTask> visible, ClockTask? current) {
    final c = context.colors;
    final use24h = use24hOf(context);
    final h = use24h ? _now.hour.toString().padLeft(2, '0') : '${_now.hour % 12 == 0 ? 12 : _now.hour % 12}';
    final next = _nextOf(visible);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 150,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$h:${_now.minute.toString().padLeft(2, '0')}',
                  style: context.tt.displaySmall?.copyWith(color: c.dialHand, fontSize: 40),
                ),
                if (!use24h)
                  TextSpan(
                    text: _now.hour >= 12 ? ' PM' : ' AM',
                    style: context.tt.labelLarge?.copyWith(color: c.dialLabel),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            if (current != null) ...[
              Text(
                current.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.tt.titleSmall?.copyWith(color: c.dialHand, fontWeight: FontWeight.w700),
              ),
              Text(
                '${formatDuration(current.end.difference(_now).inMinutes + 1)} left',
                style: context.tt.labelSmall?.copyWith(color: c.dialLabel),
              ),
              const SizedBox(height: 10),
              Material(
                color: c.dialHand.withValues(alpha: 0.14),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => _toggle(current, true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: c.dialHand),
                        const SizedBox(width: 4),
                        Text('Mark done', style: context.tt.labelMedium?.copyWith(color: c.dialHand)),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text('Free time', style: context.tt.titleSmall?.copyWith(color: c.dialHand)),
              if (next != null)
                Text(
                  'Next: ${next.title} · ${formatClock(next.start, use24h: use24h)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.tt.labelSmall?.copyWith(color: c.dialLabel),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Only the categories used on today's clock.
  Widget _legend(List<ClockTask> visible) {
    final c = context.colors;
    final categories = context.watch<CategoryController>();
    final used = <String>{for (final t in visible) t.category};
    if (used.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 6,
        children: [
          for (final key in used)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: c.tint(categories.byKey(key).color), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  categories.byKey(key).name,
                  style: context.tt.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _swipeable(ClockTask t, bool isCurrent) {
    final cs = context.cs;
    final c = context.colors;
    Widget bg(Alignment align, Color color, IconData icon, String label) => Container(
          alignment: align,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.lg - 4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: context.tt.labelLarge?.copyWith(color: Colors.white)),
            ],
          ),
        );

    return Dismissible(
      key: ValueKey(t.key),
      background: bg(Alignment.centerLeft, c.success, t.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
          t.isCompleted ? 'Undo' : 'Done'),
      secondaryBackground: bg(Alignment.centerRight, cs.error, Icons.delete_outline_rounded, 'Delete'),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await _toggle(t, !t.isCompleted);
          return false;
        }
        return _confirmDelete();
      },
      onDismissed: (_) => _deleteTask(t),
      child: TaskCard(
        task: t,
        isCurrent: isCurrent,
        onToggle: (v) => _toggle(t, v),
        onTap: () => _openEdit(t),
        onEdit: () => _openEdit(t),
        onDelete: () async {
          if (await _confirmDelete()) await _deleteTask(t);
        },
        onHide: t.isCompleted ? () => _hide(t) : null,
      ),
    );
  }

  Widget _skeletonList() {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SkeletonBox(height: 84, radius: AppRadius.lg - 4),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ task sheet

class _TaskDraft {
  final String title;
  final String category;
  final TimeOfDay start;
  final TimeOfDay end;
  final String description;
  final bool alarmEnabled;
  final int alarmMinutes;
  _TaskDraft(this.title, this.category, this.start, this.end, this.description, this.alarmEnabled, this.alarmMinutes);
}

/// Add/Edit task sheet. [onSubmit] returns an error message, or null to close.
class _TaskSheet extends StatefulWidget {
  final ClockTask? existing;
  final List<ClockTask> tasks;
  final Set<String> hidden;
  final Future<String?> Function(_TaskDraft draft) onSubmit;

  const _TaskSheet({required this.existing, required this.tasks, required this.hidden, required this.onSubmit});

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late String _category;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late bool _alarm;
  late int _alarmMinutes;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? '');
    _desc = TextEditingController(text: t?.description ?? '');
    _category = t?.category ?? context.read<CategoryController>().defaultKey;
    if (t != null) {
      _start = TimeOfDay.fromDateTime(t.start);
      _end = TimeOfDay.fromDateTime(t.end);
    } else {
      // Default to the next quarter hour, one hour long.
      final now = DateTime.now();
      final rounded = DateTime(now.year, now.month, now.day, now.hour, (now.minute ~/ 15 + 1) * 15);
      _start = TimeOfDay.fromDateTime(rounded);
      _end = TimeOfDay.fromDateTime(rounded.add(const Duration(hours: 1)));
    }
    _alarm = t?.alarmEnabled ?? false;
    final mins = t?.alarmMinutes ?? 10;
    _alarmMinutes = kAlarmMinuteOptions.contains(mins) ? mins : 10;
    _title.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  /// The day this task sits on: its own day when editing, today when adding.
  DateTime get _day => widget.existing?.start ?? DateTime.now();

  // Moving the start keeps the task's length by shifting the end with it.
  void _setStart(TimeOfDay v) {
    final (s, e) = ClockTask.rangeOn(_day, _start, _end);
    final minutes = e.difference(s).inMinutes;
    final end = DateTime(2000, 1, 1, v.hour, v.minute).add(Duration(minutes: minutes));
    setState(() {
      _start = v;
      _end = TimeOfDay.fromDateTime(end);
      _error = null;
    });
  }

  String? _validate() {
    if (_title.text.trim().isEmpty) return 'Please enter a title.';
    if (!_isNew) return null;
    final (s, e) = ClockTask.rangeOn(_day, _start, _end);
    final overlaps = widget.tasks.where((t) => s.isBefore(t.end) && e.isAfter(t.start)).toList();
    if (overlaps.any((t) => !t.isCompleted)) {
      return 'This time overlaps with an active task. Please pick a different time.';
    }
    if (overlaps.any((t) => t.isCompleted && !widget.hidden.contains(t.key))) {
      return 'This time overlaps a completed task that is still shown. Hide that task first to reuse this slot.';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      HapticFeedback.mediumImpact();
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.onSubmit(_TaskDraft(
      _title.text.trim(),
      _category,
      _start,
      _end,
      _desc.text.trim(),
      _alarm,
      _alarmMinutes,
    ));
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final (s, e) = ClockTask.rangeOn(_day, _start, _end);
    final minutes = e.difference(s).inMinutes;

    return AppSheet(
      title: _isNew ? 'New task' : 'Edit task',
      bottom: AppButton(
        label: _isNew ? 'Add task' : 'Save changes',
        icon: _isNew ? Icons.add_rounded : Icons.check_rounded,
        loading: _saving,
        onPressed: _submit,
      ),
      children: [
        AppTextField(
          controller: _title,
          label: 'Title',
          hint: 'What are you clocking?',
          autofocus: _isNew,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 20),
        const FieldLabel('Category'),
        CategoryPickerRow(selected: _category, onSelected: (k) => setState(() => _category = k)),
        const SizedBox(height: 20),
        FieldLabel(
          'Time',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timelapse_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                e.day != s.day ? '${formatDuration(minutes)} · ends tomorrow' : formatDuration(minutes),
                style: context.tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TimePickerField(
                label: 'Starts',
                value: _start,
                icon: Icons.play_circle_outline_rounded,
                onChanged: _setStart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TimePickerField(
                label: 'Ends',
                value: _end,
                icon: Icons.stop_circle_outlined,
                onChanged: (v) => setState(() {
                  _end = v;
                  _error = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _desc,
          label: 'Notes',
          hint: 'Optional',
          maxLines: 4,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 20),
        SheetSection(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.alarm_rounded, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reminder', style: context.tt.titleSmall),
                        Text(
                          'Get notified before the task ends',
                          style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: _alarm, onChanged: (v) => setState(() => _alarm = v)),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: !_alarm
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in kAlarmMinuteOptions)
                              ChoiceChip(
                                selected: _alarmMinutes == m,
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _alarmMinutes = m),
                                label: Text(m == 60 ? '1 hour' : '$m min'),
                                labelStyle: context.tt.labelLarge?.copyWith(
                                  color: _alarmMinutes == m ? cs.onPrimary : cs.onSurface,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: context.tt.bodyMedium?.copyWith(color: cs.error)),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
