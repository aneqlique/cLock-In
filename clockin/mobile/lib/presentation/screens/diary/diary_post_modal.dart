import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile, ImagePicker;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/image_viewer.dart';
import '../../widgets/photo_carousel.dart';
import '../../widgets/task_card.dart';

const _maxImages = 10;

/// Opens a completed task as a journal entry: view it, add photos, edit it,
/// share it to the feed or delete it.
Future<void> showJournalEntrySheet(
  BuildContext context, {
  required Map<String, dynamic> data,
  bool startEditing = false,
  ValueChanged<Map<String, dynamic>>? onUpdated,
  Future<void> Function(String id)? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _JournalEntrySheet(
      data: data,
      startEditing: startEditing,
      onUpdated: onUpdated,
      onDelete: onDelete,
    ),
  );
}

class _JournalEntrySheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool startEditing;
  final ValueChanged<Map<String, dynamic>>? onUpdated;
  final Future<void> Function(String id)? onDelete;

  const _JournalEntrySheet({required this.data, required this.startEditing, this.onUpdated, this.onDelete});

  @override
  State<_JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<_JournalEntrySheet> {
  final ImagePicker _picker = ImagePicker();
  late Map<String, dynamic> _data;
  late bool _editing;
  bool _saving = false;
  bool _sharing = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late String _cat;
  TimeOfDay? _start;
  TimeOfDay? _end;
  late bool _setPublic;
  List<String> _existingImageUrls = [];
  final List<File> _selectedImages = [];

  String get _id => (_data['_id'] ?? _data['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
    _editing = widget.startEditing;
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _resetFields();
  }

  void _resetFields() {
    _titleCtrl.text = (_data['taskTitle'] ?? '').toString();
    _descCtrl.text = (_data['description'] ?? '').toString();
    _cat = (_data['category'] ?? 'self').toString().toLowerCase();
    _setPublic = _data['setPublic'] == true;
    final parts = (_data['timeRange'] ?? '').toString().split('-');
    _start = parts.isNotEmpty ? parseHHmm(parts[0]) : null;
    _end = parts.length > 1 ? parseHHmm(parts[1]) : null;
    _existingImageUrls = _data['images'] is List
        ? (_data['images'] as List).map((e) => e.toString()).toList()
        : <String>[];
    _selectedImages.clear();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _pickImages() async {
    final total = _existingImageUrls.length + _selectedImages.length;
    if (total >= _maxImages) {
      showAppSnack(context, 'Cannot upload more than $_maxImages images per task');
      return;
    }
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      final available = _maxImages - total;
      if (picked.length > available && mounted) {
        showAppSnack(context, 'Only added $available images. Maximum is $_maxImages per task.');
      }
      setState(() => _selectedImages.addAll(picked.take(available).map((f) => File(f.path))));
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to pick images: ${friendlyError(e)}');
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      showAppSnack(context, 'Please enter a title.');
      return;
    }
    setState(() => _saving = true);
    try {
      final token = await _token();
      // Upload new images first, then save them alongside the existing ones.
      var uploadedUrls = <String>[];
      if (_selectedImages.isNotEmpty) {
        uploadedUrls = await ApiService.uploadImages(token, _selectedImages);
      }
      final allImages = [..._existingImageUrls, ...uploadedUrls];
      final timeRange = (_start != null && _end != null)
          ? '${formatHHmm(_start!)}-${formatHHmm(_end!)}'
          : (_data['timeRange'] ?? '').toString();
      final updated = await ApiService.updateTask(token, _id, {
        'taskTitle': _titleCtrl.text.trim(),
        'category': _cat,
        'timeRange': timeRange,
        'description': _descCtrl.text.trim(),
        'images': allImages,
        'setPublic': _setPublic,
      });
      widget.onUpdated?.call(updated.cast<String, dynamic>());
      if (!mounted) return;
      setState(() {
        _data = updated.cast<String, dynamic>();
        _editing = false;
        _resetFields();
      });
      showAppSnack(context, _setPublic ? 'Saved and shared to the feed' : 'Entry saved');
    } catch (e) {
      if (mounted) showAppSnack(context, 'Update failed: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// One-tap share/unshare without entering edit mode.
  Future<void> _toggleShare() async {
    final next = !(_data['setPublic'] == true);
    setState(() => _sharing = true);
    try {
      final updated = await ApiService.updateTask(await _token(), _id, {'setPublic': next});
      widget.onUpdated?.call(updated.cast<String, dynamic>());
      if (!mounted) return;
      setState(() {
        _data = updated.cast<String, dynamic>();
        _resetFields();
      });
      showAppSnack(context, next ? 'Shared to the feed' : 'Removed from the feed');
    } catch (e) {
      if (mounted) showAppSnack(context, 'Couldn\'t update sharing. ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete task?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || widget.onDelete == null) return;
    try {
      await widget.onDelete!(_id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to delete: ${friendlyError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return Column(
          children: [
            _topBar(),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
                children: _editing ? _editBody() : _viewBody(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _topBar() {
    final cs = context.cs;
    if (_editing) {
      return SheetHeader(
        title: 'Edit entry',
        onClose: _saving
            ? () {}
            : () => setState(() {
                  _editing = false;
                  _resetFields();
                }),
        actionLabel: 'Save',
        actionLoading: _saving,
        onAction: _save,
      );
    }
    return SheetHeader(
      title: 'Journal entry',
      onClose: () => Navigator.pop(context),
      extraActions: [
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => setState(() => _editing = true),
        ),
        if (widget.onDelete != null)
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            onPressed: _delete,
          ),
      ],
    );
  }

  List<Widget> _viewBody() {
    final cs = context.cs;
    final images = _existingImageUrls;
    final isPublic = _data['setPublic'] == true;
    final description = (_data['description'] ?? '').toString();
    return [
      if (images.isNotEmpty) ...[
        PhotoCarousel(
          images: images,
          heroPrefix: 'journal-$_id',
          height: 300,
          onTap: (i) => ImageViewer.open(context, images, i, 'journal-$_id'),
        ),
        const SizedBox(height: 20),
      ],
      Text((_data['taskTitle'] ?? '').toString(), style: context.tt.headlineSmall),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CategoryChip(category: _cat),
          _InfoPill(
            icon: Icons.schedule_rounded,
            label: formatTimeRange((_data['timeRange'] ?? '').toString(), use24h: use24hOf(context)),
          ),
          _InfoPill(
            icon: isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            label: isPublic ? 'On the feed' : 'Private',
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        description.isEmpty ? 'No notes for this one.' : description,
        style: context.tt.bodyLarge?.copyWith(
          color: description.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
          fontStyle: description.isEmpty ? FontStyle.italic : null,
        ),
      ),
      if (images.isEmpty) ...[
        const SizedBox(height: 20),
        _AddPhotosPlaceholder(onTap: () async {
          setState(() => _editing = true);
          await _pickImages();
        }),
      ],
      const SizedBox(height: 24),
      AppButton(
        label: isPublic ? 'Remove from feed' : 'Share to feed',
        icon: isPublic ? Icons.public_off_rounded : Icons.ios_share_rounded,
        variant: isPublic ? AppButtonVariant.secondary : AppButtonVariant.primary,
        loading: _sharing,
        onPressed: _toggleShare,
      ),
    ];
  }

  List<Widget> _editBody() {
    final cs = context.cs;
    final count = _existingImageUrls.length + _selectedImages.length;
    return [
      FieldLabel('Photos', trailing: Text('$count/$_maxImages',
          style: context.tt.labelMedium?.copyWith(color: cs.onSurfaceVariant))),
      SizedBox(
        height: 88,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            if (count < _maxImages)
              _AddPhotoTile(onTap: _pickImages),
            for (var i = 0; i < _existingImageUrls.length; i++)
              _PhotoTile(
                child: NetworkPhoto(url: _existingImageUrls[i]),
                onRemove: () => setState(() => _existingImageUrls.removeAt(i)),
              ),
            for (var i = 0; i < _selectedImages.length; i++)
              _PhotoTile(
                isNew: true,
                child: Image.file(_selectedImages[i], fit: BoxFit.cover),
                onRemove: () => setState(() => _selectedImages.removeAt(i)),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      AppTextField(controller: _titleCtrl, label: 'Title', textCapitalization: TextCapitalization.sentences),
      const SizedBox(height: 20),
      const FieldLabel('Category'),
      CategoryPickerRow(selected: _cat, onSelected: (k) => setState(() => _cat = k)),
      const SizedBox(height: 20),
      const FieldLabel('Time'),
      Row(
        children: [
          Expanded(
            child: TimePickerField(
              label: 'Started',
              value: _start,
              icon: Icons.play_circle_outline_rounded,
              onChanged: (v) => setState(() => _start = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TimePickerField(
              label: 'Ended',
              value: _end,
              icon: Icons.stop_circle_outlined,
              onChanged: (v) => setState(() => _end = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      AppTextField(
        controller: _descCtrl,
        label: 'Notes',
        hint: 'How did it go?',
        maxLines: 6,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 20),
      SheetSection(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SwitchListTile(
          secondary: Icon(_setPublic ? Icons.public_rounded : Icons.lock_outline_rounded),
          title: const Text('Share to feed'),
          subtitle: const Text('Post this entry publicly with its photos'),
          value: _setPublic,
          onChanged: (v) => setState(() => _setPublic = v),
        ),
      ),
    ];
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: cs.brightness == Brightness.dark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          onTap: onTap,
          child: SizedBox(
            width: 88,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: cs.onSurfaceVariant),
                const SizedBox(height: 4),
                Text('Add', style: context.tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: context.tt.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  final bool isNew;
  const _PhotoTile({required this.child, required this.onRemove, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        child: SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (isNew)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.white, semanticLabel: 'Remove photo'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotosPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotosPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 32, color: cs.onSurfaceVariant),
              const SizedBox(height: 8),
              Text('Add photos', style: context.tt.titleSmall),
              Text(
                'Capture the moment — up to $_maxImages photos',
                style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
