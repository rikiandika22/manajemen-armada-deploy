import 'package:mobile/core/constants/api_config.dart';

class FleetUnitModel {
  final int id;
  final String? fleetCode;
  final String? fleetName;
  final String? fleetType;
  final String? vehicleType;
  final String? capacity;
  final String? licensePlate;
  final String? year;
  final String? status;
  final String? condition;
  final double? price;
  final String? imageUrl;
  final List<String> imageUrls;

  FleetUnitModel({
    required this.id,
    this.fleetCode,
    this.fleetName,
    this.fleetType,
    this.vehicleType,
    this.capacity,
    this.licensePlate,
    this.year,
    this.status,
    this.condition,
    this.price,
    this.imageUrl,
    this.imageUrls = const [],
  });

  factory FleetUnitModel.fromJson(Map<String, dynamic> json) {
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

    return FleetUnitModel(
      id: json['id'],
      fleetCode: json['fleet_code'],
      fleetName: json['fleet_name'],
      fleetType: json['fleet_type'],
      vehicleType: json['vehicle_type'],
      capacity: json['capacity'],
      licensePlate: json['license_plate'],
      year: json['year'],
      status: json['status'],
      condition: json['condition'],
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      imageUrl: parsedImageUrl,
      imageUrls: parsedImageUrls,
    );
  }
}
