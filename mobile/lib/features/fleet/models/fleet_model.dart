import 'package:mobile/core/constants/api_config.dart';

class FleetModel {
  final int id;
  final String fleetCode;
  final String fleetName;
  final String fleetType;
  final String capacity;
  final String licensePlate;
  final String status;
  final num price;
  final String? description;
  final String? imageUrl;
  final List<String> imageUrls;

  FleetModel({
    required this.id,
    required this.fleetCode,
    required this.fleetName,
    required this.fleetType,
    required this.capacity,
    required this.licensePlate,
    required this.status,
    required this.price,
    this.description,
    this.imageUrl,
    this.imageUrls = const [],
  });

  factory FleetModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImageUrls = [];
    if (json['images'] != null && json['images'] is List) {
      parsedImageUrls = (json['images'] as List)
          .map((img) => ApiConfig.resolveImageUrl(img['url']?.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }

    String? parsedImageUrl = ApiConfig.resolveImageUrl(json['image_url']?.toString());
    
    // Fallback: If images array is empty but we have an image_url, put it in imageUrls
    if (parsedImageUrls.isEmpty && parsedImageUrl != null) {
      parsedImageUrls.add(parsedImageUrl);
    }

    return FleetModel(
      id: _parseInt(json['id']),
      fleetCode: json['fleet_code']?.toString() ?? '',
      fleetName: json['fleet_name']?.toString() ?? '',
      fleetType: json['fleet_type']?.toString() ?? '',
      capacity: json['capacity']?.toString() ?? '',
      licensePlate: json['license_plate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Tersedia',
      price: _parseNum(json['price']),
      description: json['description']?.toString(),
      imageUrl: parsedImageUrl,
      imageUrls: parsedImageUrls,
    );
  }

  String get priceText {
    if (price == 0) return 'Rp -';
    
    // Format to IDR format e.g. Rp 2.500.000
    String result = price.toInt().toString();
    String formatted = '';
    for (int i = 0; i < result.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = result[result.length - 1 - i] + formatted;
    }
    return 'Rp $formatted';
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}
