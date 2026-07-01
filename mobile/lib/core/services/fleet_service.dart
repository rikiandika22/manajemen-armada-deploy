import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_config.dart';
import 'package:mobile/features/fleet/models/fleet_model.dart';
import 'package:mobile/features/fleet/models/fleet_summary_model.dart';
import 'package:mobile/features/fleet/models/fleet_unit_model.dart';

class FleetService {
  final Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<FleetModel>> getFleets() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/fleets'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => FleetModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fleets');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data armada belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      throw Exception('Gagal memuat data armada: $e');
    }
  }

  Future<FleetModel> getFleetDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/fleets/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        return FleetModel.fromJson(body['data']);
      } else {
        throw Exception('Failed to load fleet detail');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data armada belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      throw Exception('Gagal memuat detail armada: $e');
    }
  }

  Future<FleetSummaryModel> getFleetSummary() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/fleet-summary'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        return FleetSummaryModel.fromJson(body['data']);
      } else {
        throw Exception('Failed to load fleet summary');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data armada belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      throw Exception('Gagal memuat ringkasan armada: $e');
    }
  }

  Future<List<FleetUnitModel>> getTruckUnits() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/truck-units'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => FleetUnitModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load truck units');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data armada belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      throw Exception('Gagal memuat unit truk: $e');
    }
  }

  Future<Map<String, dynamic>> getAvailability(String id, int month, int year, {String? unitId}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mobile/fleets/$id/availability').replace(queryParameters: {
        'month': month.toString(),
        'year': year.toString(),
        if (unitId != null && unitId.isNotEmpty) 'unit_id': unitId,
      });

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load availability');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Data armada belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
      throw Exception('Gagal memuat jadwal armada: $e');
    }
  }
}
