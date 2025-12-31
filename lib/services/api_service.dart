import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://teacher-eight-chi.vercel.app'; // Updated to match backend port

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> setToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      String errorMessage = 'Login failed';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  static Future<List<dynamic>> getTeachers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/teachers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load teachers');
    }
  }

  static Future<List<dynamic>> getStudentsForTeacher(String teacherId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/teachers/$teacherId/students'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load students');
    }
  }

  static Future<Map<String, dynamic>> getEarningsForTeacher(String teacherId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/teachers/$teacherId/earnings'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load earnings');
    }
  }

  static Future<void> activateTeacher(String teacherId, bool activate) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/teachers/$teacherId/${activate ? 'activate' : 'deactivate'}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update teacher status');
    }
  }

  // Super Admin Methods
  static Future<List<dynamic>> getSuperAdminTeachers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/super-admin/teachers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['teachers'];
    } else {
      throw Exception('Failed to load teachers');
    }
  }

  static Future<Map<String, dynamic>> getSuperAdminStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/super-admin/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load stats');
    }
  }

  static Future<Map<String, dynamic>> getStudentsForTeacherSuperAdmin(String teacherId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/super-admin/teachers/$teacherId/students'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load students');
    }
  }

  static Future<void> toggleTeacherStatus(String teacherId, String status) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/super-admin/teachers/$teacherId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update teacher status');
    }
  }

  static Future<List<Map<String, dynamic>>> getMonthlyEarningsForTeacher(String teacherId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/super-admin/reports/monthly-earnings-by-class?teacherId=$teacherId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load monthly earnings');
    }
  }

  static Future<List<dynamic>> getProblemReports() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/reports/problems'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load problem reports');
    }
  }

  static Future<List<dynamic>> getPaymentProofs() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/payment-proofs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payment proofs');
    }
  }

  static Future<Map<String, dynamic>> reviewPaymentProof(
    String proofId,
    String action,
    String adminEmail,
    String? notes,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/payment-proofs/$proofId/review'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': action,
        'adminEmail': adminEmail,
        'notes': notes,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to review payment proof');
    }
  }
}