import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  Future<void> login(String email, String password) async {
    try {
      final data = await ApiService.login(email, password);
      _token = data['token'];
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
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    _token = await ApiService.getToken();
    _isLoggedIn = _token != null;
    notifyListeners();
  }
}