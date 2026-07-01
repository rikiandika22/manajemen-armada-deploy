import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_config.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/features/pesanan/models/order_model.dart';

class OrderService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Fetch all orders for the logged-in user
  Future<List<OrderModel>> getMyOrders() async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mobile/orders'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil pesanan');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Create a new order with optional payment proof
  Future<OrderModel> createOrder(Map<String, dynamic> orderData, {File? paymentProof}) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      if (paymentProof != null) {
        // Use MultipartRequest for file upload
        final uri = Uri.parse('$_baseUrl/mobile/orders');
        final request = http.MultipartRequest('POST', uri);
        
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        // Add text fields
        orderData.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add file
        request.files.add(await http.MultipartFile.fromPath(
          'payment_proof',
          paymentProof.path,
        ));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201 || response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          return OrderModel.fromJson(body['data']);
        } else if (response.statusCode == 401) {
          await AuthState.instance.logout();
          throw Exception('Sesi telah habis, silakan login kembali.');
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Gagal membuat pesanan');
        }
      } else {
        // Regular JSON request if no file
        final response = await http.post(
          Uri.parse('$_baseUrl/mobile/orders'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(orderData),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          return OrderModel.fromJson(body['data']);
        } else if (response.statusCode == 401) {
          await AuthState.instance.logout();
          throw Exception('Sesi telah habis, silakan login kembali.');
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Gagal membuat pesanan');
        }
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Get details of a specific order
  Future<OrderModel> getOrderDetail(int id) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mobile/orders/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return OrderModel.fromJson(body['data']);
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil detail pesanan');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Cancel an order
  Future<OrderModel> cancelOrder(int id, {String? reason}) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    final bodyData = reason != null ? jsonEncode({'reason': reason}) : null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mobile/orders/$id/cancel'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: bodyData,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return OrderModel.fromJson(body['data']);
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal membatalkan pesanan');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Upload payment proof for an existing order (e.g., truck order after admin sets price)
  Future<OrderModel> uploadPaymentProof(int orderId, {required File paymentProof, required int paymentAccountId}) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final uri = Uri.parse('$_baseUrl/mobile/orders/$orderId/upload-payment');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['payment_account_id'] = paymentAccountId.toString();

      request.files.add(await http.MultipartFile.fromPath(
        'payment_proof',
        paymentProof.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return OrderModel.fromJson(body['data']);
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengunggah bukti pembayaran');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Upload settlement proof (Pelunasan)
  Future<OrderModel> uploadSettlementProof(int orderId, {required File paymentProof, required int paymentAccountId}) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final uri = Uri.parse('$_baseUrl/mobile/orders/$orderId/payments/settlement');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['payment_account_id'] = paymentAccountId.toString();

      request.files.add(await http.MultipartFile.fromPath(
        'payment_proof',
        paymentProof.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return OrderModel.fromJson(body['data']);
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengunggah bukti pelunasan');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Archive an order
  Future<void> archiveOrder(int id) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/mobile/orders/$id/archive'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Success
        return;
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengarsipkan pesanan');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Fetch archived orders for the logged-in user
  Future<List<OrderModel>> fetchArchivedOrders() async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mobile/orders/archived'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil pesanan yang diarsipkan');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }

  /// Unarchive an order
  Future<void> unarchiveOrder(int id) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/mobile/orders/$id/unarchive'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal memulihkan pesanan');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      rethrow;
    }
  }
}
