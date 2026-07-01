import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_config.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/features/payment/models/payment_account_model.dart';

class PaymentAccountService {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<List<PaymentAccount>> fetchPaymentAccounts() async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw Exception('Unauthenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mobile/payment_accounts'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => PaymentAccount.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await AuthState.instance.logout();
        throw Exception('Sesi telah habis, silakan login kembali.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil data rekening');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
