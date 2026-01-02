import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://teacher-eight-chi.vercel.app'; // Updated to match backend port
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('DEBUG: ApiService - Login request for email: $email');
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    print('DEBUG: ApiService - Login response status: ${response.statusCode}');
    print('DEBUG: ApiService - Login response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('DEBUG: ApiService - Parsed login data: $data');
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
      print('DEBUG: ApiService - Login error: $errorMessage');
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
    print('DEBUG: ApiService - getSuperAdminTeachers called');
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/super-admin/teachers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('DEBUG: ApiService - getSuperAdminTeachers response status: ${response.statusCode}');
    print('DEBUG: ApiService - getSuperAdminTeachers response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('DEBUG: ApiService - getSuperAdminTeachers parsed data: $data');
      print('DEBUG: ApiService - getSuperAdminTeachers data type: ${data.runtimeType}');
      if (data is Map<String, dynamic>) {
        print('DEBUG: ApiService - getSuperAdminTeachers data keys: ${data.keys.toList()}');
        if (data.containsKey('teachers')) {
          print('DEBUG: ApiService - getSuperAdminTeachers returning data["teachers"]: ${data['teachers']}');
          return data['teachers'];
        } else {
          print('DEBUG: ApiService - getSuperAdminTeachers no "teachers" key found');
          throw Exception('Unexpected response format: missing "teachers" key');
        }
      } else {
        print('DEBUG: ApiService - getSuperAdminTeachers data is not a Map');
        throw Exception('Unexpected response format');
      }
    } else {
      print('DEBUG: ApiService - getSuperAdminTeachers failed: ${response.statusCode}');
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

  static Future<List<dynamic>> getFeatureRequests() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/reports/feature-requests'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load feature requests');
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

  static Future<void> setTeacherSubscriptionFree(String teacherId) async {
    print('DEBUG: ApiService - Setting teacher subscription free for teacherId: $teacherId');
    final token = await getToken();
    print('DEBUG: ApiService - Token present: ${token != null}');
    final url = '$baseUrl/api/super-admin/teachers/$teacherId/set-free';
    print('DEBUG: ApiService - Request URL: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    print('DEBUG: ApiService - Response status: ${response.statusCode}');
    print('DEBUG: ApiService - Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      print('DEBUG: ApiService - Failed to set teacher subscription free: ${response.statusCode}');
      throw Exception('Failed to set teacher subscription free');
    }
  }

  static Future<void> setTeacherSubscriptionFreeWithOptions(String teacherId, {
    bool isLifetime = true,
    int? freeDays,
  }) async {
    print('DEBUG: ApiService - Setting teacher subscription free with options for teacherId: $teacherId, isLifetime: $isLifetime, freeDays: $freeDays');
    final token = await getToken();
    final body = {
      'isLifetime': isLifetime,
      if (!isLifetime && freeDays != null) 'freeDays': freeDays,
    };
    print('DEBUG: ApiService - Request body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/api/super-admin/teachers/$teacherId/set-free-options'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    
    print('DEBUG: ApiService - Response status: ${response.statusCode}');
    print('DEBUG: ApiService - Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      print('DEBUG: ApiService - Failed to set teacher subscription free with options: ${response.statusCode}');
      throw Exception('Failed to set teacher subscription free with options');
    }
  }

  static Future<Map<String, dynamic>> getAdminProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch admin profile');
    }
  }

  static Future<void> startTeacherSubscription(String teacherId, String subscriptionType) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/super-admin/teachers/$teacherId/start-subscription'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'subscriptionType': subscriptionType}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to start teacher subscription');
    }
  }
}