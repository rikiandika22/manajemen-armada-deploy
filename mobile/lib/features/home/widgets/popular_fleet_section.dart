import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/services/fleet_service.dart';
import 'package:mobile/features/fleet/models/fleet_model.dart';
import 'package:mobile/features/armada/armada_detail_page.dart';
import 'package:mobile/features/armada/truck_detail_page.dart';

class PopularFleetSection extends StatefulWidget {
  const PopularFleetSection({super.key});

  @override
  State<PopularFleetSection> createState() => _PopularFleetSectionState();
}

class _PopularFleetSectionState extends State<PopularFleetSection> {
  final FleetService _fleetService = FleetService();
  List<FleetModel> _fleets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFleets();
  }

  Future<void> _fetchFleets() async {
    try {
      final fleets = await _fleetService.getFleets();
      setState(() {
        _fleets = fleets.take(3).toList(); // Ambil 3 teratas sebagai populer
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentLime),
        ),
      );
    }

    if (_fleets.isEmpty) {
      return const SizedBox.shrink(); // Hide if no data
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Armada Populer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: _fleets.length,
            itemBuilder: (context, index) {
              final fleet = _fleets[index];
              final isAvailable = fleet.status == 'Tersedia';

              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderSoft.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with overlay status badge
                      Stack(
                        children: [
                          Container(
                            height: 130,
                            width: double.infinity,
                            color: AppColors.softNavy,
                            child: fleet.imageUrl != null && fleet.imageUrl!.isNotEmpty
                                ? Image.network(
                                    fleet.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.directions_bus, size: 40, color: AppColors.surface),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.directions_bus, size: 40, color: AppColors.surface),
                                  ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? AppColors.accentLime
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fleet.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isAvailable
                                      ? AppColors.primaryNavy
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Details
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fleet.fleetName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    fleet.capacity,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Secondary Outline Detail Button
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () {
                                  final isTruck = fleet.fleetType.toLowerCase().contains('truk');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => isTruck ? const TruckDetailPage() : ArmadaDetailPage(fleetId: fleet.id),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.borderSoft,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Detail',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
