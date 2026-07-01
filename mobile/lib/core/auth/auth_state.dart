import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/services/auth_service.dart';

class AuthState extends ChangeNotifier {
  // Singleton instance
  static final AuthState _instance = AuthState._internal();
  static AuthState get instance => _instance;

  AuthState._internal();

  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;

  /// Check token and load user data at app startup
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    String? savedToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedToken = prefs.getString('auth_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        // Token exists, verify by getting user
        final userData = await _authService.getCurrentUser(savedToken);
        _token = savedToken;
        _user = userData;
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      if (e.toString().contains('Gagal terhubung')) {
        // Network error, keep the token but we might not have user data.
        // We will consider them logged in so they can access the app and retry later.
        _token = savedToken;
        _isLoggedIn = true;
      } else {
        // Invalid token
        _isLoggedIn = false;
        _token = null;
        _user = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateLocalUser(Map<String, dynamic> updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  /// Login and save token
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email: email, password: password);
      _token = response['token'];
      _user = response['user'];
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Register without auto login
  Future<void> register(String name, String email, String phone, String password, String passwordConfirmation) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      // Removed token saving and auto-login logic to force manual login
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Logout and clear token
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await _authService.logout(_token!);
      }
    } catch (e) {
      // Proceed to clear local data even if API fails
    }

    _isLoggedIn = false;
    _user = null;
    _token = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    _isLoading = false;
    notifyListeners();
  }

  /// Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    if (_token == null) throw Exception('Tidak ada sesi yang aktif. Silakan login kembali.');
    
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.changePassword(
        token: _token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow; // Pass error message back to UI
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update Profile
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? username,
  }) async {
    if (_token == null) throw Exception('Tidak ada sesi yang aktif. Silakan login kembali.');
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.updateProfile(
        token: _token!,
        name: name,
        email: email,
        phone: phone,
        username: username,
      );
      
      // Update local user with response data
      if (response['user'] != null) {
        _user = response['user'];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }
}
