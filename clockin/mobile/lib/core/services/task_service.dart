import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class TaskService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$host/api/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createTask(String title, String description) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$host/api/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'title': title, 'description': description},
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create task: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> updates) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$host/api/tasks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }

  Future<void> deleteTask(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$host/api/tasks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }
}
