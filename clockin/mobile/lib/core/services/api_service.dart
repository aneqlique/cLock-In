import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static String get _baseUrl {
    final b = (host.isEmpty) ? 'http://localhost:8000' : host;
    return '$b/api';
  }

  static Future<List<dynamic>> getTasks(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['tasks'] is List) {
        return decoded['tasks'] as List;
      }
      if (decoded is List) return decoded;
      return [];
    } else {
      throw Exception('Failed to fetch tasks: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> createTask(String token, Map<String, dynamic> taskData) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(taskData),
    );
    if (res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      return (decoded is Map) ? decoded.cast<String, dynamic>() : {'data': decoded};
    } else {
      throw Exception('Failed to create task: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateTask(String token, String id, Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return (decoded is Map) ? decoded.cast<String, dynamic>() : {'data': decoded};
    } else {
      throw Exception('Failed to update task: ${res.statusCode}');
    }
  }

  static Future<void> deleteTask(String token, String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete task: ${res.statusCode}');
    }
  }
}
