import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import '../../core/utils/date_utils.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// Month header with ‹ › and a swipeable Mon–Sun week of day cells.
/// Future days are disabled; [daysWithEntries] (see [dayKey]) get a dot.
class WeekStrip extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final Set<String> daysWithEntries;

  const WeekStrip({super.key, required this.selected, required this.onSelected, required this.daysWithEntries});

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  static final _earliest = DateTime(2020, 1, 6); // a Monday
  late final DateTime _thisWeek = _weekStart(DateTime.now());
  late final int _weekCount = _thisWeek.difference(_earliest).inDays ~/ 7 + 1;
  late final PageController _pages = PageController(initialPage: _pageFor(widget.selected));
  late int _page = _pageFor(widget.selected);

  static DateTime _weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  // Page 0 is the current week; higher pages go back in time.
  int _pageFor(DateTime d) => (_thisWeek.difference(_weekStart(d)).inDays ~/ 7).clamp(0, _weekCount - 1);
  DateTime _weekOf(int page) => DateTime(_thisWeek.year, _thisWeek.month, _thisWeek.day - 7 * page);

  @override
  void didUpdateWidget(WeekStrip old) {
    super.didUpdateWidget(old);
    final target = _pageFor(widget.selected);
    if (!isSameDay(old.selected, widget.selected) && target != _page && _pages.hasClients) {
      _pages.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String _title(DateTime start) {
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) return '${_monthNames[start.month - 1]} ${start.year}';
    final y = start.year == end.year ? '' : ' ${start.year}';
    return '${monthShort(start)}$y – ${monthShort(end)} ${end.year}';
  }

  void _go(int page) =>
      _pages.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(_title(_weekOf(_page)), style: context.tt.titleSmall),
                ),
              ),
              IconButton(
                tooltip: 'Previous week',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _page < _weekCount - 1 ? () => _go(_page + 1) : null,
              ),
              IconButton(
                tooltip: 'Next week',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _page > 0 ? () => _go(_page - 1) : null,
              ),
            ],
          ),
          SizedBox(
            height: 76,
            child: PageView.builder(
              controller: _pages,
              reverse: true,
              itemCount: _weekCount,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, page) {
                final start = _weekOf(page);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(child: _dayCell(context, cs, start.add(Duration(days: i)))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, ColorScheme cs, DateTime d) {
    final now = DateTime.now();
    final isFuture = d.isAfter(DateTime(now.year, now.month, now.day));
    final isToday = isSameDay(d, now);
    final isSel = isSameDay(d, widget.selected);
    final hasEntries = widget.daysWithEntries.contains(dayKey(d));
    final fg = isSel ? cs.onPrimary : (isFuture ? cs.onSurfaceVariant.withValues(alpha: 0.4) : cs.onSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: true,
        enabled: !isFuture,
        selected: isSel,
        label: formatDayLong(d),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: isFuture ? null : () => widget.onSelected(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSel ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSel ? cs.primary : (isToday ? cs.onSurface : Colors.transparent),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayShort(d).substring(0, 1),
                  style: context.tt.labelSmall?.copyWith(
                    color: isSel ? fg : cs.onSurfaceVariant.withValues(alpha: isFuture ? 0.4 : 1),
                  ),
                ),
                const SizedBox(height: 2),
                Text('${d.day}', style: context.tt.titleMedium?.copyWith(color: fg)),
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEntries ? (isSel ? cs.onPrimary : cs.onSurface) : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
