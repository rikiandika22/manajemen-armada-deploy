import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ArmadaRecommendationCard extends StatelessWidget {
  const ArmadaRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryNavy,
            AppColors.deepNavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.star,
                color: AppColors.accentLime,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Rekomendasi Armada',
                style: TextStyle(
                  color: AppColors.accentLime,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Bus Medium cocok untuk perjalanan rombongan keluarga atau wisata.',
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
