import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme.dart';
import '../../core/models/task_category.dart';
import '../../core/state/category_controller.dart';
import 'app_sheet.dart';
import 'custom_button.dart';
import 'custom_input_field.dart';
import 'dialogs.dart';
import 'task_card.dart';

/// One-line, horizontally scrolling category chooser with a "+ New" chip.
class CategoryPickerRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryPickerRow({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = context.colors;
    final items = context.watch<CategoryController>().items;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final cat in items) ...[
            ChoiceChip(
              showCheckmark: false,
              selected: selected == cat.key,
              onSelected: (_) => onSelected(cat.key),
              avatar: Icon(cat.iconData, size: 16, color: selected == cat.key ? AppPalette.ink : c.tintOn(cat.color)),
              label: Text(cat.name),
              labelStyle: context.tt.labelLarge?.copyWith(color: selected == cat.key ? AppPalette.ink : cs.onSurface),
              selectedColor: c.tint(cat.color),
              side: BorderSide(color: selected == cat.key ? c.tint(cat.color) : cs.outlineVariant),
            ),
            const SizedBox(width: 8),
          ],
          if (items.length < CategoryController.maxCategories)
            ActionChip(
              avatar: Icon(Icons.add_rounded, size: 18, color: cs.onSurface),
              label: const Text('New'),
              labelStyle: context.tt.labelLarge,
              side: BorderSide(color: cs.outlineVariant),
              onPressed: () async {
                final created = await showCategoryEditor(context);
                if (created != null) onSelected(created.key);
              },
            ),
        ],
      ),
    );
  }
}

/// Add (when [existing] is null) or edit a category. Returns the saved one.
/// When [onDelete] is given the sheet shows a Delete button that closes the
/// sheet and runs it.
Future<TaskCategory?> showCategoryEditor(
  BuildContext context, {
  TaskCategory? existing,
  Future<void> Function()? onDelete,
}) {
  return showModalBottomSheet<TaskCategory>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CategoryEditor(existing: existing, onDelete: onDelete),
  );
}

class _CategoryEditor extends StatefulWidget {
  final TaskCategory? existing;
  final Future<void> Function()? onDelete;
  const _CategoryEditor({this.existing, this.onDelete});

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late int _color;
  late String _icon;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final count = context.read<CategoryController>().items.length;
    _color = widget.existing?.color ?? count % kTintCount;
    _icon = widget.existing?.icon ?? 'spa';
    _name.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ctrl = context.read<CategoryController>();
    final err = ctrl.validateName(_name.text, exceptKey: widget.existing?.key);
    if (err != null) {
      HapticFeedback.mediumImpact();
      setState(() => _error = err);
      return;
    }
    setState(() => _saving = true);
    final name = _name.text.trim();
    final saved = widget.existing == null
        ? TaskCategory(key: CategoryController.newKey(name), name: name, color: _color, icon: _icon)
        : widget.existing!.copyWith(name: name, color: _color, icon: _icon);
    try {
      if (widget.existing == null) {
        await ctrl.add(saved);
      } else {
        await ctrl.update(saved);
      }
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Couldn\'t save the category. ${friendlyError(e)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = context.colors;
    final preview = TaskCategory(
      key: 'preview',
      name: _name.text.trim().isEmpty ? 'Category' : _name.text.trim(),
      color: _color,
      icon: _icon,
    );
    return AppSheet(
      title: widget.existing == null ? 'New category' : 'Edit category',
      actionLabel: 'Save',
      actionLoading: _saving,
      onAction: _save,
      children: [
        Center(child: Transform.scale(scale: 1.3, child: CategoryChip(category: '', resolved: preview))),
        const SizedBox(height: 24),
        AppTextField(
          controller: _name,
          label: 'Name',
          hint: 'e.g. Gym, Reading, Side project',
          autofocus: widget.existing == null,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(CategoryController.maxNameLength)],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(_error!, style: context.tt.bodySmall?.copyWith(color: cs.error)),
          ),
        const SizedBox(height: 20),
        const FieldLabel('Color'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < kTintCount; i++)
              Semantics(
                button: true,
                selected: _color == i,
                label: 'Color ${i + 1}',
                child: GestureDetector(
                  onTap: () => setState(() => _color = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.tint(i),
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == i ? cs.onSurface : Colors.transparent, width: 2.5),
                    ),
                    child: _color == i ? const Icon(Icons.check_rounded, size: 20, color: AppPalette.ink) : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const FieldLabel('Icon'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final entry in kCategoryIcons.entries)
              Semantics(
                button: true,
                selected: _icon == entry.key,
                label: entry.key,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  onTap: () => setState(() => _icon = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _icon == entry.key ? c.tint(_color) : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    child: Icon(entry.value, color: _icon == entry.key ? AppPalette.ink : cs.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        if (widget.existing != null && widget.onDelete != null) ...[
          const SizedBox(height: 28),
          AppButton(
            label: 'Delete category',
            icon: Icons.delete_outline_rounded,
            variant: AppButtonVariant.danger,
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete!();
            },
          ),
        ],
      ],
    );
  }
}
