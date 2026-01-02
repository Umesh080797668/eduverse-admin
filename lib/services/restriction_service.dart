import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class RestrictionService {
  final String baseUrl = ApiService.baseUrl;

  /// Super Admin: Get all teachers
  Future<List<dynamic>> getAllTeachers() async {
    try {
      final token = await ApiService.getToken();
      print('DEBUG: RestrictionService - Fetching teachers with token: ${token != null ? "present" : "null"}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/super-admin/teachers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: RestrictionService - Teachers response status: ${response.statusCode}');
      print('DEBUG: RestrictionService - Teachers response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('DEBUG: RestrictionService - Parsed response data type: ${responseData.runtimeType}');
        if (responseData is Map<String, dynamic>) {
          print('DEBUG: RestrictionService - Response keys: ${responseData.keys.toList()}');
          if (responseData.containsKey('teachers')) {
            print('DEBUG: RestrictionService - Found teachers key, returning: ${responseData['teachers']}');
            return responseData['teachers'] as List<dynamic>;
          } else if (responseData.containsKey('data')) {
            print('DEBUG: RestrictionService - Found data key, returning: ${responseData['data']}');
            return responseData['data'] as List<dynamic>;
          } else {
            print('DEBUG: RestrictionService - No teachers or data key found');
            throw Exception('Unexpected response format: missing "teachers" or "data" key');
          }
        } else if (responseData is List) {
          print('DEBUG: RestrictionService - Response is List, returning directly');
          return responseData;
        } else {
          print('DEBUG: RestrictionService - Unexpected response format: $responseData');
          throw Exception('Unexpected response format');
        }
      } else {
        print('DEBUG: RestrictionService - Failed to fetch teachers: ${response.statusCode}');
        throw Exception('Failed to fetch teachers: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: RestrictionService - Error fetching teachers: $e');
      rethrow;
    }
  }

  /// Super Admin: Get all students
  Future<List<dynamic>> getAllStudents() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/super-admin/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          return responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          return responseData;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to fetch students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching students: $e');
      rethrow;
    }
  }

  /// Super Admin: Restrict teacher
  Future<Map<String, dynamic>> restrictTeacher({
    required String teacherId,
    required String adminId,
    String? reason,
  }) async {
    try {
      final token = await ApiService.getToken();
      print('DEBUG: RestrictionService - Restricting teacher with teacherId: $teacherId, adminId: $adminId, reason: $reason');
      final requestBody = {
        'teacherId': teacherId,
        'adminId': adminId,
        'reason': reason ?? 'No reason provided',
      };
      print('DEBUG: RestrictionService - Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/super-admin/restrict-teacher'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('DEBUG: RestrictionService - Restrict teacher response status: ${response.statusCode}');
      print('DEBUG: RestrictionService - Restrict teacher response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('DEBUG: RestrictionService - Failed to restrict teacher: ${response.statusCode}');
        throw Exception('Failed to restrict teacher: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: RestrictionService - Error restricting teacher: $e');
      rethrow;
    }
  }

  /// Super Admin: Unrestrict teacher
  Future<Map<String, dynamic>> unrestrictTeacher(String teacherId) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/super-admin/unrestrict-teacher'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'teacherId': teacherId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to unrestrict teacher: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unrestricting teacher: $e');
      rethrow;
    }
  }

  /// Super Admin: Restrict student
  Future<Map<String, dynamic>> restrictStudent({
    required String studentId,
    required String adminId,
    String? reason,
  }) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/super-admin/restrict-student'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'studentId': studentId,
          'adminId': adminId,
          'reason': reason ?? 'No reason provided',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to restrict student: ${response.statusCode}');
      }
    } catch (e) {
      print('Error restricting student: $e');
      rethrow;
    }
  }

  /// Super Admin: Unrestrict student
  Future<Map<String, dynamic>> unrestrictStudent(String studentId) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/super-admin/unrestrict-student'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'studentId': studentId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to unrestrict student: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unrestricting student: $e');
      rethrow;
    }
  }
}
