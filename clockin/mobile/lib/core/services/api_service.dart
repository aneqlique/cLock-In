import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  static Future<List<String>> uploadImages(String token, List<File> images) async {
    if (token.isEmpty) {
      throw Exception('Failed to upload images: missing token (not logged in)');
    }
    if (images.isEmpty) {
      return [];
    }
    if (images.length > 10) {
      throw Exception('Cannot upload more than 10 images');
    }

    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
    request.headers['Authorization'] = 'Bearer $token';

    for (var image in images) {
      final stream = http.ByteStream(image.openRead());
      final length = await image.length();
      
      // Determine content type from file extension
      String? mimeType;
      final extension = image.path.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }
      
      final multipartFile = http.MultipartFile(
        'images',
        stream,
        length,
        filename: image.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['images'] is List) {
        return (decoded['images'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } else {
      final body = res.body.isNotEmpty ? res.body : '<empty body>';
      throw Exception('Failed to upload images: ${res.statusCode} $body');
    }
  }

  // Get all public posts
  static Future<List<dynamic>> getPosts(String token) async {
    if (token.isEmpty) {
      throw Exception('Failed to get posts: missing token (not logged in)');
    }

    final res = await http.get(
      Uri.parse('$_baseUrl/posts'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List;
    } else {
      throw Exception('Failed to load posts: ${res.statusCode}');
    }
  }

  // Toggle like on a post
  static Future<Map<String, dynamic>> toggleLike(String token, String postId) async {
    if (token.isEmpty) {
      throw Exception('Failed to toggle like: missing token (not logged in)');
    }

    final res = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to toggle like: ${res.statusCode}');
    }
  }

  // Add comment to a post
  static Future<Map<String, dynamic>> addComment(String token, String postId, String comment) async {
    if (token.isEmpty) {
      throw Exception('Failed to add comment: missing token (not logged in)');
    }

    final res = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/comment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'comment': comment}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to add comment: ${res.statusCode}');
    }
  }

  // Get comments for a post
  static Future<List<dynamic>> getComments(String token, String postId) async {
    if (token.isEmpty) {
      throw Exception('Failed to get comments: missing token (not logged in)');
    }

    final res = await http.get(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List;
    } else {
      throw Exception('Failed to load comments: ${res.statusCode}');
    }
  }
}
