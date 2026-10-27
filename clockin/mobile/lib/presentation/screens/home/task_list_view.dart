import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockin/core/config/theme.dart';
import 'package:clockin/core/services/api_service.dart';
import 'package:clockin/core/state/data_sync.dart';
import 'package:clockin/core/utils/date_utils.dart';
import 'package:clockin/presentation/screens/diary/diary_post_modal.dart';
import 'package:clockin/presentation/widgets/dialogs.dart';
import 'package:clockin/presentation/widgets/empty_state.dart';
import 'package:clockin/presentation/widgets/photo_carousel.dart';
import 'package:clockin/presentation/widgets/skeleton.dart';
import 'package:clockin/presentation/widgets/task_card.dart';
import 'package:clockin/presentation/widgets/week_strip.dart';

/// The Journal tab: completed tasks by day, with search across every day.
class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  List<Map<String, dynamic>> _completed = [];
  List<Map<String, dynamic>> _allCompleted = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  DateTime? _selectedDate;
  final TextEditingController _searchCtrl = TextEditingController();
  DataSync? _sync;

  @override
  void initState() {
    super.initState();
    _fetch();
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
    _sync?.removeListener(_onSync);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSync() {
    if (_sync?.source != this) _fetch(silent: true);
  }

  Future<void> _fetch({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final list = await ApiService.getTasks(token);
      final items = list.map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>()).toList();
      final completed = items.where((m) => (m['status'] ?? 'pending') == 'completed').toList();
      if (!mounted) return;
      setState(() {
        _error = null;
        _allCompleted = completed;
        _completed = _filterByDate(completed, _selectedDate);
      });
    } catch (e) {
      if (mounted && !silent) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _entryDate(Map<String, dynamic> task) {
    for (final key in ['completedAt', 'updatedAt']) {
      final v = task[key];
      if (v == null) continue;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>> _filterByDate(List<Map<String, dynamic>> tasks, DateTime? date) {
    final now = DateTime.now();
    final targetDate = date ?? now;
    return tasks.where((task) {
      // Completed on the target date (completedAt, falling back to updatedAt)
      final d = _entryDate(task);
      if (d != null && isSameDay(d, targetDate)) return true;
      // Special handling for tasks that span today to tomorrow
      final timeRange = task['timeRange']?.toString().toLowerCase() ?? '';
      if (timeRange.contains('today') && timeRange.contains('tomorrow')) {
        if (isSameDay(targetDate, now) || isSameDay(targetDate, now.add(const Duration(days: 1)))) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  void _selectDate(DateTime? d) {
    setState(() {
      _selectedDate = (d == null || isSameDay(d, DateTime.now())) ? null : d;
      _completed = _filterByDate(_allCompleted, _selectedDate);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) _selectDate(picked);
  }

  Future<void> _delete(String id) async {
    final prevAll = List<Map<String, dynamic>>.from(_allCompleted);
    final prev = List<Map<String, dynamic>>.from(_completed);
    bool matches(Map m) => (m['_id'] ?? m['id'] ?? '').toString() == id;
    setState(() {
      _completed.removeWhere(matches);
      _allCompleted.removeWhere(matches);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await ApiService.deleteTask(prefs.getString('token') ?? '', id);
      _sync?.bump(this);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allCompleted = prevAll;
        _completed = prev;
      });
      showAppSnack(context, 'Failed to delete: ${friendlyError(e)}');
    }
  }

  void _openEntry(Map<String, dynamic> m) {
    showJournalEntrySheet(
      context,
      data: m,
      onUpdated: (updated) {
        setState(() {
          final id = (updated['_id'] ?? updated['id'] ?? '').toString();
          final i = _allCompleted.indexWhere((x) => (x['_id'] ?? x['id']).toString() == id);
          if (i >= 0) _allCompleted[i] = updated;
          _completed = _filterByDate(_allCompleted, _selectedDate);
        });
        _sync?.bump(this);
      },
      onDelete: _delete,
    );
  }

  List<Map<String, dynamic>> _filtered() {
    if (_query.isEmpty) return _completed;
    // When searching, search across ALL completed tasks (all dates)
    final q = _query.toLowerCase();
    return _allCompleted.where((m) {
      final t = (m['taskTitle'] ?? '').toString().toLowerCase();
      final c = (m['category'] ?? '').toString().toLowerCase();
      final d = (m['description'] ?? '').toString().toLowerCase();
      final tr = (m['timeRange'] ?? '').toString().toLowerCase();
      final date = _entryDate(m);
      final dateStr = date == null ? '' : '${date.month}/${date.day}/${date.year}';
      return t.contains(q) || c.contains(q) || d.contains(q) || tr.contains(q) || dateStr.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered();
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text('Journal', style: context.tt.headlineMedium)),
                      IconButton(
                        tooltip: 'Pick a date',
                        icon: const Icon(Icons.calendar_month_rounded),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _searchField()),
            if (_query.isEmpty) SliverToBoxAdapter(child: _weekStrip()),
            SliverToBoxAdapter(child: _sectionHeader(items.length)),
            if (_loading)
              SliverToBoxAdapter(child: _skeleton())
            else if (_error != null)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Couldn\'t load your journal',
                  message: _error,
                  actionLabel: 'Try again',
                  onAction: _fetch,
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(child: _empty())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _masonry(items)),
              ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24)),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    final cs = context.cs;
    final pill = OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim()),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search all entries',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _query = '';
                    _searchCtrl.clear();
                  }),
                ),
          fillColor: cs.surfaceContainerHigh,
          border: pill,
          enabledBorder: pill,
          focusedBorder: pill,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _weekStrip() {
    final days = <String>{};
    for (final m in _allCompleted) {
      final d = _entryDate(m);
      if (d != null) days.add(dayKey(d));
    }
    return WeekStrip(
      selected: _selectedDate ?? DateTime.now(),
      onSelected: _selectDate,
      daysWithEntries: days,
    );
  }

  Widget _sectionHeader(int count) {
    final cs = context.cs;
    final String title;
    if (_query.isNotEmpty) {
      title = 'Results';
    } else if (_selectedDate == null) {
      title = "Today's entries";
    } else {
      title = formatDayLong(_selectedDate!);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.tt.titleLarge)),
          if (!_loading)
            Text(
              '$count ${count == 1 ? 'entry' : 'entries'}',
              style: context.tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          if (_selectedDate != null && _query.isEmpty)
            TextButton(onPressed: () => _selectDate(null), child: const Text('Today')),
        ],
      ),
    );
  }

  Widget _empty() {
    if (_query.isNotEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try a different word, category or date (e.g. 10/27/2026).',
      );
    }
    if (_selectedDate != null) {
      return const EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Nothing journaled this day',
        message: 'Completed tasks show up here on the day you finish them.',
      );
    }
    return const EmptyState(
      icon: Icons.auto_stories_outlined,
      title: 'Your journal starts here',
      message: 'Complete a task on the Clock and it will appear here, ready for photos and notes.',
    );
  }

  Widget _masonry(List<Map<String, dynamic>> items) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final card = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _JournalCard(data: items[i], onTap: () => _openEntry(items[i])),
      );
      (i.isEven ? left : right).add(card);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ],
    );
  }

  Widget _skeleton() {
    Widget col(List<double> heights) => Expanded(
          child: Column(
            children: [
              for (final h in heights)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: SkeletonBox(height: h, radius: AppRadius.lg)),
            ],
          ),
        );
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [col([220, 140]), const SizedBox(width: 12), col([150, 210])],
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _JournalCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final title = (data['taskTitle'] ?? '').toString();
    final category = (data['category'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final images = data['images'] is List ? (data['images'] as List).map((e) => e.toString()).toList() : <String>[];
    final isPublic = data['setPublic'] == true;

    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg - 4),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkPhoto(url: images.first),
                    if (images.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                              const SizedBox(width: 3),
                              Text('${images.length}', style: context.tt.labelSmall?.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: CategoryChip(category: category, dense: true)),
                      const Spacer(),
                      if (isPublic)
                        Tooltip(
                          message: 'On the feed',
                          child: Icon(Icons.public_rounded, size: 16, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    formatTimeRange((data['timeRange'] ?? '').toString(), use24h: use24hOf(context)),
                    style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: images.isNotEmpty ? 2 : 5,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
