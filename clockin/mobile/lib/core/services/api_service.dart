import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static String get _baseUrl {
    final b = (host.isEmpty) ? 'http://localhost:8000' : host;
    return '$b/api';
  }

  static Future<List<dynamic>> getTasks(String token) async {
    if (token.isEmpty) {
      throw Exception('Failed to fetch tasks: missing token (not logged in)');
    }
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
      final body = res.body.isNotEmpty ? res.body : '<empty body>';
      throw Exception('Failed to fetch tasks: ${res.statusCode} $body');
    }
  }

  static Future<Map<String, dynamic>> createTask(String token, Map<String, dynamic> taskData) async {
    if (token.isEmpty) {
      throw Exception('Failed to create task: missing token (not logged in)');
    }
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
      final body = res.body.isNotEmpty ? res.body : '<empty body>';
      throw Exception('Failed to create task: ${res.statusCode} $body');
    }
  }

  static Future<Map<String, dynamic>> updateTask(String token, String id, Map<String, dynamic> updates) async {
    if (token.isEmpty) {
      throw Exception('Failed to update task: missing token (not logged in)');
    }
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
      final body = res.body.isNotEmpty ? res.body : '<empty body>';
      throw Exception('Failed to update task: ${res.statusCode} $body');
    }
  }

  static Future<void> deleteTask(String token, String id) async {
    if (token.isEmpty) {
      throw Exception('Failed to delete task: missing token (not logged in)');
    }
    final res = await http.delete(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? res.body : '<empty body>';
      throw Exception('Failed to delete task: ${res.statusCode} $body');
    }
  }
}
