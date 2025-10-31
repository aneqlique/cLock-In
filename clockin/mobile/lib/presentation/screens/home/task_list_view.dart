import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart' show XFile, ImagePicker;
import 'package:clockin/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
 

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
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }
  
  // Add this method to allow refresh from home screen
  void refreshTasks() {
    _fetch();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final list = await ApiService.getTasks(token);
      final items = list.map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>()).toList();
      final completed = items.where((m) => (m['status'] ?? 'pending') == 'completed').toList();
      
      setState(() {
        _allCompleted = completed;
        // Filter to show only today's tasks by default
        _completed = _filterByDate(completed, _selectedDate);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterByDate(List<Map<String, dynamic>> tasks, DateTime? date) {
    // Use local time to ensure we're comparing in the correct timezone
    final now = DateTime.now();
    final targetDate = date ?? now;
    
    return tasks.where((task) {
      // Check if task was completed on target date
      final completedAt = task['completedAt'];
      if (completedAt != null) {
        try {
          final taskDate = DateTime.parse(completedAt.toString()).toLocal();
          if (_isSameDay(taskDate, targetDate)) return true;
        } catch (e) {
          // If parsing fails, continue to fallback
        }
      }
      
      // Fallback to updatedAt if completedAt doesn't exist or parsing failed
      final updatedAt = task['updatedAt'];
      if (updatedAt != null) {
        try {
          final taskDate = DateTime.parse(updatedAt.toString()).toLocal();
          if (_isSameDay(taskDate, targetDate)) return true;
        } catch (e) {
          // If parsing fails, continue
        }
      }
      
      // Special handling for tasks that span today to tomorrow
      final timeRange = task['timeRange']?.toString() ?? '';
      if (timeRange.toLowerCase().contains('today') && timeRange.toLowerCase().contains('tomorrow')) {
        // If task spans today-tomorrow and target date is today or tomorrow, include it
        if (_isSameDay(targetDate, now) || _isSameDay(targetDate, now.add(const Duration(days: 1)))) {
          return true;
        }
      }
      
      return false;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _completed = _filterByDate(_allCompleted, _selectedDate);
      });
    }
  }

  void _resetToToday() {
    setState(() {
      _selectedDate = null;
      _completed = _filterByDate(_allCompleted, null);
    });
  }

  Future<void> _delete(String id) async {
    final prev = List<Map<String, dynamic>>.from(_completed);
    setState(() {
      _completed.removeWhere((m) => (m['_id'] ?? m['id'] ?? '').toString() == id);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await ApiService.deleteTask(token, id);
    } catch (e) {
      setState(() {
        _completed = prev;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: const Color(0xFFEAE6E0),
    appBar: AppBar(
    automaticallyImplyLeading: false, // 🔥 removes the default back arrow
    backgroundColor: const Color(0xFFEAE6E0),
    elevation: 0,
    titleSpacing: 0,
    title: Row(
        children: [
        const SizedBox(width: 15),
        GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
            'assets/Logo.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            ),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            decoration: BoxDecoration(
                // color: _searchFocus.hasFocus ? Color(0xFFEAE6E0) : const Color(0xFFF2F2F2), 
                color: Color(0xFFF6F6F6),// 👌 flat transparent background
                borderRadius: BorderRadius.circular(20),
                // border: _searchFocus.hasFocus
                //     ? Border.all(color: Colors.black.withOpacity(0.15)) // subtle border on focus
                //     : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Row(
                children: [
                const Icon(Icons.search, color: Colors.black87, size: 22),
                const SizedBox(width: 6),
                Expanded(
                    child: TextField(
                    focusNode: _searchFocus,
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    onSubmitted: (_) => _searchFocus.unfocus(),
                    decoration: const InputDecoration(
                        fillColor: Color(0xFFF6F6F6),
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.black45),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                    ),
                    cursorColor: Colors.black87,
                    style: const TextStyle(color: Colors.black87),
                    ),
                ),
                if (_query.isNotEmpty)
                    InkWell(
                    onTap: () => setState(() {
                        _query = '';
                        _searchCtrl.clear();
                    }),
                    child: const Icon(Icons.close, color: Colors.black54, size: 20),
                    ),
                ],
            ),
            ),
        ),
        const SizedBox(width: 12),
        ],
    ),
    actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.black),
          onPressed: _pickDate,
          tooltip: 'Select Date',
        ),
    ],
    ),  

      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    )
                  ])
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const Divider(height: 1, color: Color(0xFFE5E5E5)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedDate == null
                                      ? "Today's Completed Tasks!"
                                      : "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year} Tasks",
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                                ),
                                if (_selectedDate != null) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 20),
                                    onPressed: _resetToToday,
                                    tooltip: 'Reset to Today',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final data = _filtered();
                              final m = data[i];
                              final id = (m['_id'] ?? m['id'] ?? '').toString();
                              final title = (m['taskTitle'] ?? '').toString();
                              final category = (m['category'] ?? '').toString();
                              final timeRange = (m['timeRange'] ?? '').toString();
                              final description = (m['description'] ?? '').toString();
                              final images = m['images'] != null && m['images'] is List 
                                  ? (m['images'] as List).map((e) => e.toString()).toList() 
                                  : <String>[];
                              final hasImage = images.isNotEmpty;
                              
                              return InkWell(
                                onTap: () {
                                  _openTaskModal(m);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (hasImage)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(18),
                                            topRight: Radius.circular(18),
                                          ),
                                          child: Image.network(
                                            images.first,
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 120,
                                                color: Colors.grey[800],
                                                child: const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 120,
                                                color: Colors.grey[800],
                                                child: const Center(
                                                  child: Icon(Icons.image_not_supported, color: Colors.white54),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 19.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text(
                                                _toTitleCase(category),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(timeRange,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: Text(
                                                  description,
                                                  maxLines: hasImage ? 2 : 4,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _filtered().length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  String _toTitleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<Map<String, dynamic>> _filtered() {
    if (_query.isEmpty) return _completed;
    
    // When searching, search across ALL completed tasks (all dates)
    final q = _query.toLowerCase();
    return _allCompleted.where((m) {
      final t = (m['taskTitle'] ?? '').toString().toLowerCase();
      final c = (m['category'] ?? '').toString().toLowerCase();
      final d = (m['description'] ?? '').toString().toLowerCase();
      final tr = (m['timeRange'] ?? '').toString().toLowerCase();
      
      // Also search by date
      final completedAt = m['completedAt'] ?? m['updatedAt'];
      String dateStr = '';
      if (completedAt != null) {
        try {
          final date = DateTime.parse(completedAt.toString());
          dateStr = '${date.month}/${date.day}/${date.year}'.toLowerCase();
        } catch (e) {
          // ignore
        }
      }
      
      return t.contains(q) || c.contains(q) || d.contains(q) || tr.contains(q) || dateStr.contains(q);
    }).toList();
  }

  Future<void> _openTaskModal(Map<String, dynamic> m) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskModalSheet(
        data: m,
        onUpdated: (updated) {
          setState(() {
            final id = (updated['_id'] ?? updated['id'] ?? '').toString();
            final idx = _completed.indexWhere((x) => (x['_id'] ?? x['id']).toString() == id);
            if (idx >= 0) _completed[idx] = updated.cast<String, dynamic>();
          });
        },
        onDelete: (id) async {
          await _delete(id);
        },
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2B2B2B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white60),
        ),
      );
}

class _TaskModalSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic> updated) onUpdated;
  final Future<void> Function(String id) onDelete;
  const _TaskModalSheet({required this.data, required this.onUpdated, required this.onDelete});
  @override
  State<_TaskModalSheet> createState() => _TaskModalSheetState();
}

class _TaskModalSheetState extends State<_TaskModalSheet> {
  late bool editable;
  late String id;
  late String cat;
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController startCtrl;
  late TextEditingController endCtrl;
  late bool setPublic;
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    editable = false;
    id = (widget.data['_id'] ?? widget.data['id'] ?? '').toString();
    final title = (widget.data['taskTitle'] ?? '').toString();
    final description = (widget.data['description'] ?? '').toString();
    final timeRange = (widget.data['timeRange'] ?? '').toString();
    cat = (widget.data['category'] ?? 'self').toString();
    setPublic = (widget.data['setPublic'] ?? false) as bool;
    final parts = timeRange.split('-');
    titleCtrl = TextEditingController(text: title);
    descCtrl = TextEditingController(text: description);
    startCtrl = TextEditingController(text: parts.isNotEmpty ? parts[0].trim() : '');
    endCtrl = TextEditingController(text: parts.length > 1 ? parts[1].trim() : '');
    
    // Load existing images
    if (widget.data['images'] != null && widget.data['images'] is List) {
      _existingImageUrls = (widget.data['images'] as List).map((e) => e.toString()).toList();
    }
  }

  Future<void> _pickImages() async {
    try {
      final totalImages = _existingImageUrls.length + _selectedImages.length;
      if (totalImages >= 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot upload more than 10 images per task')),
          );
        }
        return;
      }

      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        final availableSlots = 10 - totalImages;
        final filesToAdd = pickedFiles.take(availableSlots).toList();
        
        if (pickedFiles.length > availableSlots) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Only added $availableSlots images. Maximum is 10 per task.')),
            );
          }
        }
        
        setState(() {
          _selectedImages.addAll(filesToAdd.map((file) => File(file.path)).toList());
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: ${e.toString()}')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<ImageInfo> _loadImage(ImageProvider imageProvider) {
    final completer = Completer<ImageInfo>();
    final stream = imageProvider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      if (!completer.isCompleted) {
        completer.complete(info);
      }
    });
    stream.addListener(listener);
    completer.future.then((_) {
      stream.removeListener(listener);
    });
    return completer.future;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.only(
          top: 68,
          bottom: media.viewInsets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: media.size.width * 0.94,
              maxHeight: media.size.height * 0.85,
            ),
            child: Material(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(editable ? Icons.check : Icons.edit, color: Colors.white70),
                          onPressed: () async {
                            if (!editable) {
                              setState(() => editable = true);
                              return;
                            }
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final token = prefs.getString('token') ?? '';
                              
                              // Upload new images if any
                              List<String> uploadedUrls = [];
                              if (_selectedImages.isNotEmpty) {
                                uploadedUrls = await ApiService.uploadImages(token, _selectedImages);
                              }
                              
                              // Combine existing and new image URLs
                              final allImages = [..._existingImageUrls, ...uploadedUrls];
                              
                              final updates = {
                                'taskTitle': titleCtrl.text.trim(),
                                'category': cat,
                                'timeRange': '${startCtrl.text.trim()}-${endCtrl.text.trim()}',
                                'description': descCtrl.text.trim(),
                                'images': allImages,
                                'setPublic': setPublic,
                              };
                              final updated = await ApiService.updateTask(token, id, updates);
                              widget.onUpdated(updated.cast<String, dynamic>());
                              if (mounted) {
                                setState(() {
                                  editable = false;
                                  _selectedImages.clear();
                                  _existingImageUrls = allImages;
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: ${e.toString()}')));
                              }
                            }
                          },
                          tooltip: editable ? 'Save' : 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white70),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
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
                                    TextButton(
                                      onPressed: () => Navigator.pop(dctx, false),
                                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(dctx, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (confirm == true) {
                              await widget.onDelete(id);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    editable
                        ? TextField(
                            controller: titleCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            decoration: _dec('Title'),
                          )
                        : Text(titleCtrl.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 6),
                    editable
                        ? DropdownButtonFormField<String>(
                            value: cat,
                            items: const [
                              DropdownMenuItem(value: 'school', child: Text('School')),
                              DropdownMenuItem(value: 'work', child: Text('Work')),
                              DropdownMenuItem(value: 'self', child: Text('Self')),
                              DropdownMenuItem(value: 'house', child: Text('House')),
                            ],
                            onChanged: (v) => setState(() => cat = v ?? cat),
                            dropdownColor: Colors.black,
                            style: const TextStyle(color: Colors.white),
                            decoration: _dec('Category'),
                          )
                        : Text(_toTitleCase(cat), style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    editable
                        ? Row(
                            children: [
                              Expanded(child: TextField(controller: startCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Start (HH:mm)'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: endCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('End (HH:mm)'))),
                            ],
                          )
                        : Text('${startCtrl.text}-${endCtrl.text}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            editable
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: descCtrl,
                                        maxLines: 6,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: _dec('Description'),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Theme(
                                            data: Theme.of(context).copyWith(
                                              switchTheme: const SwitchThemeData(
                                                thumbColor: MaterialStatePropertyAll(Colors.black),
                                                trackColor: MaterialStatePropertyAll(Color(0xFFCCCCCC)),
                                              ),
                                            ),
                                            child: Switch(
                                              value: setPublic,
                                              onChanged: (v) => setState(() => setPublic = v),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Set as public', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: _pickImages,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Color(0xFF555555),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add_photo_alternate, size: 20),
                                        label: const Text('Add Images', style: TextStyle(fontSize: 14)),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                : Text(descCtrl.text, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 16),
                            (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_existingImageUrls.isNotEmpty) ...[
                                        const Text('', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        GridView.builder(
                                          itemCount: _existingImageUrls.length,
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 0.75,
                                          ),
                                          itemBuilder: (context, index) {
                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    _existingImageUrls[index],
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return const Center(child: CircularProgressIndicator());
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[800],
                                                        child: const Center(
                                                          child: Icon(Icons.error, color: Colors.white54),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                if (editable)
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () => _removeExistingImage(index),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      if (_selectedImages.isNotEmpty) ...[
                                        const Text('New Images (not uploaded yet)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        GridView.builder(
                                          itemCount: _selectedImages.length,
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 0.75,
                                          ),
                                          itemBuilder: (context, index) {
                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.file(
                                                    _selectedImages[index],
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                                ),
                                                if (editable)
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () => _removeImage(index),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Text(
                                        'No images added yet',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Local helpers to keep the modal self-contained
  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2B2B2B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white60),
        ),
      );

  String _toTitleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
