import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/match.dart';
import '../models/chat_message.dart';
import '../models/role.dart';
import 'api_service.dart';

class AdminApiService {
  final ApiService _apiService = ApiService();
  // Local development
  static const String baseUrl = 'https://172.20.10.5:8000/api/admin';
  
  // Fly.io production (commented)
  // static const String baseUrl = 'https://app-falling-wind-2135.fly.dev/api/admin';

  // Get headers with auth
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await _apiService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ========== STATISTICS ==========
  Future<Map<String, dynamic>> getStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get statistics: ${response.statusCode}');
    }
  }

  // ========== USER MANAGEMENT ==========
  Future<List<User>> getAllUsers({int limit = 100, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users?limit=$limit&offset=$offset'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get users: ${response.statusCode}');
    }
  }

  Future<int> getUserCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/count'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['count'] as int;
    } else {
      throw Exception('Failed to get user count: ${response.statusCode}');
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }

  Future<User> toggleAdmin(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/toggle-admin'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception('Failed to toggle admin: ${response.statusCode}');
    }
  }

  Future<User> banUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/ban'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception('Failed to ban user: ${response.statusCode}');
    }
  }

  // ========== MATCH MANAGEMENT ==========
  Future<List<Match>> getAllMatches({
    int limit = 100,
    int offset = 0,
    String? statusFilter,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (statusFilter != null) {
      queryParams['status_filter'] = statusFilter;
    }

    final uri = Uri.parse('$baseUrl/matches').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Match.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get matches: ${response.statusCode}');
    }
  }

  Future<int> getMatchCount({String? statusFilter}) async {
    final queryParams = <String, String>{};
    if (statusFilter != null) {
      queryParams['status_filter'] = statusFilter;
    }

    final uri = Uri.parse('$baseUrl/matches/count').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['count'] as int;
    } else {
      throw Exception('Failed to get match count: ${response.statusCode}');
    }
  }

  Future<void> deleteMatch(String matchId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/matches/$matchId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete match: ${response.statusCode}');
    }
  }

  // ========== MESSAGE MANAGEMENT ==========
  Future<List<ChatMessage>> getAllMessages({
    int limit = 100,
    int offset = 0,
    String? matchId,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (matchId != null) {
      queryParams['match_id'] = matchId;
    }

    final uri = Uri.parse('$baseUrl/messages').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get messages: ${response.statusCode}');
    }
  }

  Future<int> getMessageCount({String? matchId}) async {
    final queryParams = <String, String>{};
    if (matchId != null) {
      queryParams['match_id'] = matchId;
    }

    final uri = Uri.parse('$baseUrl/messages/count').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['count'] as int;
    } else {
      throw Exception('Failed to get message count: ${response.statusCode}');
    }
  }

  Future<void> deleteMessage(int messageId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.statusCode}');
    }
  }

  // ========== ROLE MANAGEMENT ==========
  Future<List<Role>> getAllRoles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/roles'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Role.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get roles: ${response.statusCode}');
    }
  }

  Future<Role> createRole(String name, {String? description}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/roles'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Role.fromJson(data);
    } else {
      throw Exception('Failed to create role: ${response.statusCode}');
    }
  }

  Future<Role> updateRole(int roleId, {String? name, String? description}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/roles/$roleId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Role.fromJson(data);
    } else {
      throw Exception('Failed to update role: ${response.statusCode}');
    }
  }

  Future<void> deleteRole(int roleId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/roles/$roleId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete role: ${response.statusCode}');
    }
  }

  // ========== PERMISSION MANAGEMENT ==========
  Future<List<Permission>> getAllPermissions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/permissions'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Permission.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get permissions: ${response.statusCode}');
    }
  }

  Future<Permission> createPermission(String name, String resource, String action, {String? description}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/permissions'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'resource': resource,
        'action': action,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Permission.fromJson(data);
    } else {
      throw Exception('Failed to create permission: ${response.statusCode}');
    }
  }

  // ========== ROLE-PERMISSION MANAGEMENT ==========
  Future<List<Permission>> getRolePermissions(int roleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/roles/$roleId/permissions'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Permission.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get role permissions: ${response.statusCode}');
    }
  }

  Future<Role> assignPermissionToRole(int roleId, int permissionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/roles/$roleId/permissions/$permissionId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Role.fromJson(data);
    } else {
      throw Exception('Failed to assign permission: ${response.statusCode}');
    }
  }

  Future<Role> removePermissionFromRole(int roleId, int permissionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/roles/$roleId/permissions/$permissionId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Role.fromJson(data);
    } else {
      throw Exception('Failed to remove permission: ${response.statusCode}');
    }
  }

  // ========== USER-ROLE MANAGEMENT ==========
  Future<List<Role>> getUserRoles(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/roles'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Role.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get user roles: ${response.statusCode}');
    }
  }

  Future<User> assignRoleToUser(int userId, int roleId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/roles/$roleId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception('Failed to assign role: ${response.statusCode}');
    }
  }

  Future<User> removeRoleFromUser(int userId, int roleId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/roles/$roleId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception('Failed to remove role: ${response.statusCode}');
    }
  }
}

