import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/armada/armada_detail_page.dart';
import 'package:mobile/features/armada/truck_detail_page.dart';

class ArmadaCard extends StatelessWidget {
  final String name;
  final String capacity;
  final String status;
  final String description;
  final String? subInfo;
  final String? imageUrl;
  final List<String> imageUrls;
  final int? id;
  final String? origin;
  final double? originLat;
  final double? originLng;
  final String? destination;
  final double? destinationLat;
  final double? destinationLng;
  final String? date;

  const ArmadaCard({
    super.key,
    this.id,
    required this.name,
    required this.capacity,
    required this.status,
    required this.description,
    this.subInfo,
    this.imageUrl,
    this.imageUrls = const [],
    this.origin,
    this.originLat,
    this.originLng,
    this.destination,
    this.destinationLat,
    this.destinationLng,
    this.date,
  });

  String? get _displayImageUrl {
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return imageUrl;
  }

  String get _displayDescription {
    if (description.trim().isNotEmpty) return description;
    
    final lowerName = name.toLowerCase();
    if (lowerName.contains('bus')) {
      return 'Cocok untuk perjalanan rombongan dan wisata.';
    } else if (lowerName.contains('elf')) {
      return 'Cocok untuk perjalanan keluarga dan rombongan kecil.';
    } else if (lowerName.contains('truk') || lowerName.contains('truck') || lowerName.contains('cdd') || lowerName.contains('hino')) {
      return 'Cocok untuk kebutuhan pengangkutan barang dan material.';
    }
    return 'Tersedia untuk disewa dengan harga terbaik.';
  }

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = status == 'Tersedia';
    final Color statusColor = status == 'Tersedia'
        ? Colors.green
        : status == 'Dipesan'
            ? Colors.grey
            : Colors.orange;

    return GestureDetector(
      onTap: () {
        final isTruck = name.toLowerCase().contains('truk') || name.toLowerCase().contains('hino');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isTruck 
              ? TruckDetailPage(imageUrls: imageUrls) 
              : ArmadaDetailPage(
                  fleetId: id, 
                  imageUrls: imageUrls,
                  origin: origin,
                  originLat: originLat,
                  originLng: originLng,
                  destination: destination,
                  destinationLat: destinationLat,
                  destinationLng: destinationLng,
                  date: date,
                ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Stack(
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  color: AppColors.softNavy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _displayImageUrl != null && _displayImageUrl!.isNotEmpty
                    ? Image.network(
                        _displayImageUrl!,
                        key: ValueKey(_displayImageUrl!),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.directions_bus,
                            size: 64,
                            color: AppColors.surface,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.directions_bus,
                          size: 64,
                          color: AppColors.surface,
                        ),
                      ),
              ),
              // Status Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Info Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          capacity,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _displayDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (subInfo != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        subInfo!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final isTruck = name.toLowerCase().contains('truk') || name.toLowerCase().contains('hino');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => isTruck 
                            ? TruckDetailPage(imageUrls: imageUrls) 
                            : ArmadaDetailPage(
                                fleetId: id, 
                                imageUrls: imageUrls,
                                origin: origin,
                                destination: destination,
                                date: date,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable ? AppColors.accentLime : AppColors.background,
                      foregroundColor: isAvailable ? AppColors.primaryNavy : AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
