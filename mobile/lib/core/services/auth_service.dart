import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_config.dart';

class AuthService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Register a new customer
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mobile/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        if ((response.statusCode == 422 || response.statusCode == 400) && error['errors'] != null) {
          final errors = error['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first[0];
          throw Exception(firstError);
        }
        throw Exception(error['message'] ?? 'Gagal mendaftar');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Login a customer
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mobile/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        if ((response.statusCode == 422 || response.statusCode == 400 || response.statusCode == 401) && error['errors'] != null) {
          final errors = error['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first[0];
          throw Exception(firstError);
        }
        throw Exception(error['message'] ?? 'Email, username, atau password tidak sesuai');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mobile/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Token tidak valid');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Logout customer
  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/mobile/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignored for logout
    }
  }

  /// Change customer password
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/mobile/change-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final error = jsonDecode(response.body);
        
        // Handle Laravel validation errors specifically for change password
        if (response.statusCode == 422 && error['errors'] != null) {
          final errors = error['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first[0];
          throw Exception(firstError);
        }
        
        throw Exception(error['message'] ?? 'Gagal mengubah password');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Update customer profile
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
    String? username,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/mobile/profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        
        // Handle Laravel validation errors
        if (response.statusCode == 422 && error['errors'] != null) {
          final errors = error['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first[0];
          throw Exception(firstError);
        }

        throw Exception(error['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }
}
