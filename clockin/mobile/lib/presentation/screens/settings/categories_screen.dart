import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/theme.dart';
import '../../../core/models/task_category.dart';
import '../../../core/services/api_service.dart';
import '../../../core/state/category_controller.dart';
import '../../../core/state/data_sync.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/dialogs.dart';

/// Profile → Categories: add, edit, reorder and delete task categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _loadTasks() async {
    try {
      final list = await ApiService.getTasks(await _token());
      if (mounted) setState(() => _tasks = list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList());
    } catch (_) {}
  }

  int _countFor(String key) => _tasks.where((t) => (t['category'] ?? '').toString() == key).length;

  Future<void> _edit(TaskCategory cat) async {
    await showCategoryEditor(context, existing: cat, onDelete: () => _delete(cat));
  }

  Future<void> _delete(TaskCategory cat) async {
    final ctrl = context.read<CategoryController>();
    final sync = context.read<DataSync>();
    if (ctrl.items.length <= 1) {
      showAppSnack(context, 'You need at least one category.');
      return;
    }
    final using = _tasks.where((t) => (t['category'] ?? '').toString() == cat.key).toList();
    String? moveTo;
    if (using.isNotEmpty) {
      moveTo = await _pickMoveTarget(cat, using.length);
      if (moveTo == null) return;
    } else {
      final ok = await showConfirmDialog(
        context,
        title: 'Delete "${cat.name}"?',
        message: 'No tasks use this category.',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      if (moveTo != null) {
        final token = await _token();
        for (final t in using) {
          final id = (t['_id'] ?? t['id'] ?? '').toString();
          if (id.isNotEmpty) await ApiService.updateTask(token, id, {'category': moveTo});
        }
      }
      await ctrl.remove(cat.key);
      sync.bump();
      await _loadTasks();
      if (mounted) {
        showAppSnack(
          context,
          moveTo == null
              ? 'Deleted "${cat.name}"'
              : 'Deleted "${cat.name}" and moved ${using.length} ${using.length == 1 ? 'task' : 'tasks'} to ${ctrl.byKey(moveTo).name}',
        );
      }
    } catch (e) {
      if (mounted) showAppSnack(context, 'Couldn\'t delete the category. ${friendlyError(e)}');
      await _loadTasks();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _pickMoveTarget(TaskCategory cat, int count) {
    final others = context.read<CategoryController>().items.where((c) => c.key != cat.key).toList();
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        final c = ctx.colors;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text('Delete "${cat.name}"?', style: ctx.tt.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '$count ${count == 1 ? 'task uses' : 'tasks use'} this category. Move ${count == 1 ? 'it' : 'them'} to:',
                  style: ctx.tt.bodyMedium?.copyWith(color: ctx.cs.onSurfaceVariant),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in others)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c.tint(o.color),
                          child: Icon(o.iconData, size: 20, color: AppPalette.ink),
                        ),
                        title: Text(o.name),
                        trailing: const Icon(Icons.arrow_forward_rounded),
                        onTap: () => Navigator.pop(ctx, o.key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CategoryController>();
    final items = ctrl.items;
    final cs = context.cs;
    final c = context.colors;
    final canAdd = items.length < CategoryController.maxCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: _busy
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : () => showCategoryEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            )
          : null,
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: items.length,
        buildDefaultDragHandles: false,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Tap to edit · drag ≡ to reorder · ${items.length}/${CategoryController.maxCategories}',
            style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        onReorderItem: (a, b) async {
          try {
            await ctrl.reorder(a, b);
          } catch (e) {
            if (context.mounted) showAppSnack(context, 'Couldn\'t reorder. ${friendlyError(e)}');
          }
        },
        itemBuilder: (context, i) {
          final cat = items[i];
          final n = _countFor(cat.key);
          return Padding(
            key: ValueKey(cat.key),
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
                side: BorderSide(color: cs.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: _busy ? null : () => _edit(cat),
                leading: CircleAvatar(
                  backgroundColor: c.tint(cat.color),
                  child: Icon(cat.iconData, size: 20, color: AppPalette.ink),
                ),
                title: Text(cat.name),
                subtitle: Text('$n ${n == 1 ? 'task' : 'tasks'}'),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant, semanticLabel: 'Reorder'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
