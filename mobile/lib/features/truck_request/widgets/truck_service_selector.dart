import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

enum TruckServiceType {
  palawija,
  ternak,
  material,
}

class TruckServiceSelector extends StatelessWidget {
  final TruckServiceType? selectedService;
  final ValueChanged<TruckServiceType> onServiceSelected;

  const TruckServiceSelector({
    super.key,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOption(
          type: TruckServiceType.palawija,
          icon: Icons.inventory_2_outlined,
          title: 'Angkut Palawija atau Barang',
          description: 'Untuk hasil panen, barang dagangan, atau muatan umum.',
        ),
        const SizedBox(height: 12),
        _buildOption(
          type: TruckServiceType.ternak,
          icon: Icons.pets,
          title: 'Angkut Ternak',
          description: 'Untuk pengangkutan sapi, kambing, atau ternak dari pasar ke lokasi tujuan.',
        ),
        const SizedBox(height: 12),
        _buildOption(
          type: TruckServiceType.material,
          icon: Icons.landscape_outlined,
          title: 'Pesan Pasir atau Abu',
          description: 'Untuk pemesanan material dari depo ke rumah atau lokasi proyek.',
        ),
      ],
    );
  }

  Widget _buildOption({
    required TruckServiceType type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = selectedService == type;

    return InkWell(
      onTap: () => onServiceSelected(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLime.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.accentLime : AppColors.borderSoft,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentLime.withValues(alpha: 0.2) : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: AppColors.accentLime,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
