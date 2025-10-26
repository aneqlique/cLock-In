import 'package:flutter/material.dart';
import 'package:clockin/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
 

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  List<Map<String, dynamic>> _completed = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _completed = items.where((m) => (m['status'] ?? 'pending') == 'completed').toList();
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
    //   appBar: AppBar(
    //     backgroundColor: Colors.white,
    //     elevation: 0.5,
    //     titleSpacing: 0,
    //     title: Row(
    //       children: [
    //         const SizedBox(width: 12),
    //         GestureDetector(
    //           onTap: () => Navigator.pop(context),
    //           child: Image.asset('assets/Logo.png', width: 28, height: 28, fit: BoxFit.contain),
    //         ),
    //         const SizedBox(width: 10),
    //         Expanded(
    //           child: AnimatedContainer(
    //             duration: const Duration(milliseconds: 180),
    //             height: 40,
    //             decoration: BoxDecoration(
    //               color: _searchFocus.hasFocus ? Colors.white : const Color(0xFFF2F2F2),
    //               borderRadius: BorderRadius.circular(20),
    //               boxShadow: _searchFocus.hasFocus
    //                   ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
    //                   : null,
    //             ),
    //             padding: const EdgeInsets.symmetric(horizontal: 12),
    //             alignment: Alignment.centerLeft,
    //             child: Row(
    //               children: [
    //                 const Icon(Icons.search, color: Colors.black87),
    //                 const SizedBox(width: 6),
    //                 Expanded(
    //                   child: TextField(
    //                     focusNode: _searchFocus,
    //                     controller: _searchCtrl,
    //                     onChanged: (v) => setState(() => _query = v.trim()),
    //                     onSubmitted: (_) => _searchFocus.unfocus(),
    //                     decoration: const InputDecoration(
                                              
    //                       hintText: 'Search',
    //                       hintStyle: TextStyle(color: Colors.black45),
    //                       border: InputBorder.none,
    //                       isDense: true,
    //                       contentPadding: EdgeInsets.zero,
    //                     ),
    //                     cursorColor: Colors.black87,
    //                     style: const TextStyle(color: Colors.black87),
    //                   ),
    //                 ),
    //                 if (_query.isNotEmpty)
    //                   InkWell(
    //                     onTap: () => setState(() {
    //                       _query = '';
    //                       _searchCtrl.clear();
    //                     }),
    //                     child: const Icon(Icons.close, color: Colors.black54),
    //                   ),
    //               ],
    //             ),
    //           ),
    //         ),
    //         const SizedBox(width: 12),
    //       ],
    //     ),
    //     actions: const [
    //       Padding(
    //         padding: EdgeInsets.only(right: 12.0),
    //         child: Icon(Icons.calendar_month_rounded, color: Colors.black),
    //       ),
    //     ],
    //   ),
    appBar: AppBar(
    automaticallyImplyLeading: false, // 🔥 removes the default back arrow
    backgroundColor: const Color(0xFFEAE6E0),
    elevation: 0,
    titleSpacing: 0,
    title: Row(
        children: [
        const SizedBox(width: 12),
        GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
            'assets/Logo.png',
            width: 28,
            height: 28,
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
                color: Colors.white,// 👌 flat transparent background
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
                        fillColor: Colors.white,
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
    actions: const [
        Padding(
        padding: EdgeInsets.only(right: 12.0),
        child: Icon(Icons.calendar_month_rounded, color: Colors.black),
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
                          children: const [
                            Divider(height: 1, color: Color(0xFFE5E5E5)),
                            SizedBox(height: 10),
                            Text("Today's Completed Tasks!",
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                            SizedBox(height: 10),
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
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Text(title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16)),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Text(
                                          _toTitleCase(category),
                                          style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Text(timeRange,
                                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Text(
                                          description,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white70),
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
    final q = _query.toLowerCase();
    return _completed.where((m) {
      final t = (m['taskTitle'] ?? '').toString().toLowerCase();
      final c = (m['category'] ?? '').toString().toLowerCase();
      final d = (m['description'] ?? '').toString().toLowerCase();
      final tr = (m['timeRange'] ?? '').toString().toLowerCase();
      return t.contains(q) || c.contains(q) || d.contains(q) || tr.contains(q);
    }).toList();
  }

  Future<void> _openTaskModal(Map<String, dynamic> m) async {
    final id = (m['_id'] ?? m['id'] ?? '').toString();
    final title = (m['taskTitle'] ?? '').toString();
    final category = (m['category'] ?? 'self').toString();
    final timeRange = (m['timeRange'] ?? '').toString();
    final description = (m['description'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool editable = false;
        String titleLocal = title;
        String descLocal = description;
        String timeRangeLocal = timeRange;
        String cat = category;
        final parts = timeRangeLocal.split('-');
        final titleCtrl = TextEditingController(text: titleLocal);
        final descCtrl = TextEditingController(text: descLocal);
        final startCtrl = TextEditingController(text: parts.isNotEmpty ? parts[0].trim() : '');
        final endCtrl = TextEditingController(text: parts.length > 1 ? parts[1].trim() : '');
        bool setPublic = false;

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final media = MediaQuery.of(ctx);
            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: media.size.width * 0.94,
                      maxHeight: media.size.height * 0.9,
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
                            // Header actions (Back on left, actions on right)
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
                                      setSheet(() => editable = true);
                                      return;
                                    }
                                    try {
                                      final prefs = await SharedPreferences.getInstance();
                                      final token = prefs.getString('token') ?? '';
                                      final updates = {
                                        'taskTitle': titleCtrl.text.trim(),
                                        'category': cat,
                                        'timeRange': '${startCtrl.text.trim()}-${endCtrl.text.trim()}',
                                        'description': descCtrl.text.trim(),
                                      };
                                      final updated = await ApiService.updateTask(token, id, updates);
                                      setState(() {
                                        final idx = _completed.indexWhere((x) => (x['_id'] ?? x['id']).toString() == id);
                                        if (idx >= 0) _completed[idx] = updated.cast<String, dynamic>();
                                      });
                                      setSheet(() {
                                        titleLocal = titleCtrl.text.trim();
                                        descLocal = descCtrl.text.trim();
                                        timeRangeLocal = '${startCtrl.text.trim()}-${endCtrl.text.trim()}';
                                        editable = false;
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated')));
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
                                      await _delete(id);
                                      if (mounted) Navigator.pop(context);
                                    }
                                  },
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Title
                            editable
                                ? TextField(
                                    controller: titleCtrl,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                                    decoration: _dec('Title'),
                                  )
                                : Text(titleLocal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                            const SizedBox(height: 6),
                            // Category
                            editable
                                ? DropdownButtonFormField<String>(
                                    value: cat,
                                    items: const [
                                      DropdownMenuItem(value: 'school', child: Text('School')),
                                      DropdownMenuItem(value: 'work', child: Text('Work')),
                                      DropdownMenuItem(value: 'self', child: Text('Self')),
                                      DropdownMenuItem(value: 'house', child: Text('House')),
                                    ],
                                    onChanged: (v) => setSheet(() => cat = v ?? cat),
                                    dropdownColor: Colors.black,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _dec('Category'),
                                  )
                                : Text(_toTitleCase(cat), style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 8),
                            // Time range
                            editable
                                ? Row(
                                    children: [
                                      Expanded(child: TextField(controller: startCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Start (HH:mm)'))),
                                      const SizedBox(width: 12),
                                      Expanded(child: TextField(controller: endCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('End (HH:mm)'))),
                                    ],
                                  )
                                : Text(timeRangeLocal, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            // Scrollable middle
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    editable
                                        ? TextField(controller: descCtrl, maxLines: 6, style: const TextStyle(color: Colors.white), decoration: _dec('Description'))
                                        : Text(descLocal, style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 16),
                                    GridView.builder(
                                      itemCount: 3,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 1.3,
                                      ),
                                      itemBuilder: (_, i) => Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A4A4A),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Bottom actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                        onChanged: (v) => setSheet(() => setPublic = v),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Set as public'),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.white),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Image'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
