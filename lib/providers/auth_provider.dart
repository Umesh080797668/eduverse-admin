import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _adminData;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get adminData => _adminData;
  String? get adminEmail => _adminData?['email'];
  String? get adminId => _adminData?['id'] ?? _adminData?['_id'];

  Future<void> login(String email, String password) async {
    try {
      print('DEBUG: AuthProvider - Attempting login for email: $email');
      final data = await ApiService.login(email, password);
      print('DEBUG: AuthProvider - Login response data: $data');
      _token = data['token'];
      _adminData = data['user'];
      print('DEBUG: AuthProvider - Admin data: $_adminData');
      print('DEBUG: AuthProvider - Admin ID: $adminId');
      print('DEBUG: AuthProvider - Admin email: ${data['user']?['email']}');
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      print('DEBUG: AuthProvider - Login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _isLoggedIn = false;
    _token = null;
    _adminData = null;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    _token = await ApiService.getToken();
    _isLoggedIn = _token != null;
    
    // Fetch admin data if token exists
    if (_isLoggedIn) {
      try {
        _adminData = await ApiService.getAdminProfile();
        print('DEBUG: AuthProvider - Restored admin data: $_adminData');
      } catch (e) {
        print('DEBUG: AuthProvider - Failed to fetch admin data: $e');
        // If we can't fetch admin data, consider the user not logged in
        _isLoggedIn = false;
        _token = null;
        _adminData = null;
      }
    }
    
    notifyListeners();
  }
}