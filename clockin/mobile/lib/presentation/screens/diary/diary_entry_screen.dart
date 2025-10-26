import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockin/core/services/api_service.dart';

class DiaryEntryScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const DiaryEntryScreen({super.key, required this.task});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _start;
  late TextEditingController _end;
  String _category = 'self';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.task;
    _title = TextEditingController(text: (m['taskTitle'] ?? '').toString());
    _description = TextEditingController(text: (m['description'] ?? '').toString());
    final range = (m['timeRange'] ?? '').toString();
    final parts = range.split('-');
    _start = TextEditingController(text: parts.isNotEmpty ? parts[0].trim() : '');
    _end = TextEditingController(text: parts.length > 1 ? parts[1].trim() : '');
    _category = (m['category'] ?? 'self').toString();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = (widget.task['_id'] ?? widget.task['id'] ?? '').toString();
    final title = _title.text.trim();
    final s = _start.text.trim();
    final e = _end.text.trim();
    final desc = _description.text.trim();

    // Validate
    String? error;
    final hhmm = RegExp(r'^\d{1,2}:\d{2}$');
    if (title.isEmpty) error = 'Please enter a title';
    else if (!hhmm.hasMatch(s)) error = 'Start time must be in HH:mm';
    else if (!hhmm.hasMatch(e)) error = 'End time must be in HH:mm';
    else {
      final sp = s.split(':'), ep = e.split(':');
      final sh = int.parse(sp[0]), sm = int.parse(sp[1]);
      final eh = int.parse(ep[0]), em = int.parse(ep[1]);
      if (sh < 0 || sh > 23 || sm < 0 || sm > 59) error = 'Invalid start time';
      if (eh < 0 || eh > 23 || em < 0 || em > 59) error = 'Invalid end time';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error!)));
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final updates = {
        'taskTitle': title,
        'category': _category,
        'timeRange': '$s-$e',
        'description': desc,
      };
      final updated = await ApiService.updateTask(token, id, updates);
      if (mounted) {
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Task Details', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                decoration: _dec('Title'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'school', child: Text('School')),
                  DropdownMenuItem(value: 'work', child: Text('Work')),
                  DropdownMenuItem(value: 'self', child: Text('Self')),
                  DropdownMenuItem(value: 'house', child: Text('House')),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Category'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _start, style: const TextStyle(color: Colors.white), decoration: _dec('Start (HH:mm)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _end, style: const TextStyle(color: Colors.white), decoration: _dec('End (HH:mm)'))),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: _dec('Description'),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              )
            ],
          ),
        ),
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
