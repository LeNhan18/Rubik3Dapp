import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../models/chat_message.dart';

class ApiService {
  // Local development
  static const String baseUrl = 'http://192.168.2.26:8000/api';
  
  // Fly.io production (commented)
  // static const String baseUrl = 'https://app-falling-wind-2135.fly.dev/api';

  // Get stored token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Public method to get token (for WebSocket)
  Future<String?> getToken() async {
    return _getToken();
  }

  // Save token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Get headers with auth
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ========== AUTH ==========
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await _saveToken(token);
      return data;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception('Failed to get current user');
    }
  }

  // ========== MATCHES ==========
  Future<Match> createMatch({int? opponentId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/create'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (opponentId != null) 'opponent_id': opponentId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Match.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Failed to create match');
    }
  }

  Future<Match> findOpponent() async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/find-opponent'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Match.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Failed to find opponent');
    }
  }

  Future<Match> getMatch(String matchId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/matches/$matchId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Match.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Failed to get match');
    }
  }

  Future<Match> startMatch(String matchId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/$matchId/start'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Match.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Failed to start match');
    }
  }

  Future<Match> submitResult(String matchId, int solveTime) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/$matchId/submit-result'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'solve_time': solveTime,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Match.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Failed to submit result');
    }
  }

  Future<List<Match>> getMyMatches({String? statusFilter, int limit = 20}) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (statusFilter != null) {
      queryParams['status_filter'] = statusFilter;
    }

    final uri = Uri.parse('$baseUrl/matches/').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Match.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get matches');
    }
  }

  // ========== CHAT ==========
  Future<ChatMessage> sendMessage({
    required String matchId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'match_id': matchId,
        'content': content,
        'message_type': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatMessage.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Failed to send message');
    }
  }

  Future<List<ChatMessage>> getMessages(String matchId, {int limit = 50, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/$matchId/messages?limit=$limit&offset=$offset'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get messages');
    }
  }

  // ========== FRIENDS ==========
  Future<List<User>> getFriends() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((json) {
          try {
            return User.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing user: $e, json: $json');
            rethrow;
          }
        }).toList();
      } catch (e) {
        print('Error parsing friends response: $e, body: ${response.body}');
        rethrow;
      }
    } else {
      throw Exception('Failed to get friends: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/search/$query'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  // Send friend request
  Future<Map<String, dynamic>> sendFriendRequest(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/request'),
      headers: await _getHeaders(),
      body: jsonEncode({'user2_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to send friend request: ${response.statusCode} - ${response.body}');
    }
  }

  // Accept friend request
  Future<Map<String, dynamic>> acceptFriendRequest(int friendshipId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/$friendshipId/accept'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to accept friend request: ${response.statusCode} - ${response.body}');
    }
  }

  // Get pending friend requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/pending'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to get pending requests: ${response.statusCode} - ${response.body}');
    }
  }

  // ========== LEADERBOARD ==========
  Future<List<User>> getLeaderboard({int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/leaderboard?limit=$limit'),
      headers: await _getHeaders(includeAuth: false), // Public endpoint
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get leaderboard');
    }
  }

  // ========== PROFILE UPDATE ==========
  Future<User> updateProfile({
    String? username,
    String? email,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['detail'] ?? 'Failed to update profile');
    }
  }

  // ========== UPLOAD AVATAR ==========
  Future<User> uploadAvatar(String imagePath) async {
    try {
      // Kiểm tra file có tồn tại không
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('File không tồn tại');
      }
      
      final uri = Uri.parse('$baseUrl/users/me/avatar');
      final request = http.MultipartRequest('POST', uri);
      
      // Thêm token vào headers
      final headers = await _getHeaders();
      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
      });
      
      // Thêm file với content type
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imagePath,
        filename: imagePath.split('/').last,
      );
      request.files.add(multipartFile);
      
      // Gửi request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        // Parse error message
        String errorMessage = 'Failed to upload avatar';
        try {
          final error = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = error['detail'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi khi upload ảnh: ${e.toString()}');
    }
  }

  // ========== GET AVATAR URL ==========
  String getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return '';
    }
    // Nếu đã là full URL thì trả về luôn
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }
    // Nếu là relative path, thêm base URL
    if (avatarPath.startsWith('/')) {
      // Local development
      return 'http://172.20.10.5:8000$avatarPath';
      // Fly.io production (commented)
      // return 'https://app-falling-wind-2135.fly.dev$avatarPath';
    }
    // Nếu là path dạng "api/users/avatars/..."
    if (avatarPath.startsWith('api/')) {
      // Local development
      return 'http://172.20.10.5:8000/$avatarPath';
      // Fly.io production (commented)
      // return 'https://app-falling-wind-2135.fly.dev/$avatarPath';
    }
    return '$baseUrl/avatars/$avatarPath';
  }
}

