import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/theme.dart';
import 'package:provider/provider.dart';
import '../../core/models/clock_task.dart';
import '../../core/models/task_category.dart';
import '../../core/state/category_controller.dart';
import '../../core/utils/date_utils.dart';

/// Small pill showing a task category in its muted tint.
class CategoryChip extends StatelessWidget {
  final String category;
  final bool dense;

  /// Use this instead of looking [category] up in the user's list (e.g. a
  /// feed post that carries the author's category snapshot).
  final TaskCategory? resolved;

  const CategoryChip({super.key, required this.category, this.dense = false, this.resolved});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cat = resolved ?? context.watch<CategoryController>().byKey(category);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: c.tint(cat.color).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cat.iconData, size: dense ? 12 : 14, color: c.tintOn(cat.color)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              cat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.tt.labelSmall?.copyWith(
                color: c.tintOn(cat.color),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round completion toggle used on task cards.
class CheckCircle extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;
  final double size;
  const CheckCircle({super.key, required this.checked, required this.onChanged, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Semantics(
      checked: checked,
      label: checked ? 'Mark as not done' : 'Mark as done',
      child: InkResponse(
        radius: 24,
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!checked);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? cs.primary : Colors.transparent,
              border: Border.all(color: checked ? cs.primary : cs.outline, width: 1.8),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: checked ? 1 : 0,
              child: Icon(Icons.check_rounded, size: size * 0.65, color: cs.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// A task row on the Clock tab.
class TaskCard extends StatelessWidget {
  final ClockTask task;
  final bool isCurrent;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onHide;

  const TaskCard({
    super.key,
    required this.task,
    required this.isCurrent,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = context.colors;
    final done = task.isCompleted;
    final tint = c.tint(context.watch<CategoryController>().byKey(task.category).color);
    final use24h = use24hOf(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: done ? 0.7 : 1,
      child: Material(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg - 4),
          side: BorderSide(
            color: isCurrent ? cs.primary : cs.outlineVariant,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: done ? tint.withValues(alpha: 0.35) : tint),
                const SizedBox(width: 4),
                Center(child: CheckCircle(checked: done, onChanged: onToggle)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.tt.titleMedium?.copyWith(
                                  decoration: done ? TextDecoration.lineThrough : null,
                                  color: done ? cs.onSurfaceVariant : cs.onSurface,
                                ),
                              ),
                            ),
                            if (isCurrent && !done) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  'NOW',
                                  style: context.tt.labelSmall?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            CategoryChip(category: task.category, dense: true),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule_rounded, size: 14, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${formatClock(task.start, use24h: use24h)} – ${formatClock(task.end, use24h: use24h)}',
                                  style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                            if (task.alarmEnabled)
                              Icon(Icons.alarm_rounded, size: 15, color: cs.onSurfaceVariant),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                    if (v == 'hide') onHide?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: _MenuRow(Icons.edit_outlined, 'Edit')),
                    if (done && onHide != null)
                      const PopupMenuItem(value: 'hide', child: _MenuRow(Icons.visibility_off_outlined, 'Hide')),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(Icons.delete_outline_rounded, 'Delete', color: cs.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: color ?? context.cs.onSurfaceVariant),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: color)),
    ]);
  }
}
