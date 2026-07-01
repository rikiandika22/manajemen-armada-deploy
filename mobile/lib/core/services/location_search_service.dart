import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';

/// Service untuk mencari lokasi menggunakan OpenStreetMap Nominatim API.
/// Nominatim digunakan untuk prototipe dan harus memakai debounce serta limit request
/// untuk mematuhi Acceptable Use Policy.
class LocationSearchService {
  // Simple in-memory cache to avoid redundant network requests
  final Map<String, List<LocationResult>> _cache = {};

  Future<List<LocationResult>> searchLocation(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) {
      return [];
    }

    if (_cache.containsKey(trimmedQuery)) {
      return _cache[trimmedQuery]!;
    }

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmedQuery)}&format=jsonv2&addressdetails=1&limit=5&countrycodes=id');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'SumberAgungTransMobile/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) {
          final displayName = item['display_name'] as String? ?? '';
          final latStr = item['lat'] as String?;
          final lonStr = item['lon'] as String?;
          final address = item['address'] as Map<String, dynamic>?;
          
          final lat = latStr != null ? double.tryParse(latStr) : null;
          final lon = lonStr != null ? double.tryParse(lonStr) : null;
          final placeId = item['place_id']?.toString();

          // Construct a short label
          String label = '';
          if (item['name'] != null && item['name'].toString().isNotEmpty) {
            label = item['name'].toString();
          } else {
            // Fallback to the first part of display_name
            label = displayName.split(',').first.trim();
          }

          return LocationResult(
            text: label,
            address: displayName,
            lat: lat,
            lng: lon,
            placeId: placeId,
          );
        }).toList();

        _cache[trimmedQuery] = results;
        return results;
      } else {
        throw Exception('Gagal memuat data dari Nominatim: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mencari lokasi.');
    }
  }
}
