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

  Future<void> login(String email, String password) async {
    try {
      final data = await ApiService.login(email, password);
      _token = data['token'];
      _adminData = data['user'];
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      throw e;
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
    // TODO: You might want to fetch admin data again if token exists
    notifyListeners();
  }
}