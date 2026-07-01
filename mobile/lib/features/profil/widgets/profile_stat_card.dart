import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isPrimary;
  final Color? iconColor;

  const ProfileStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isPrimary = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primaryNavy : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: AppColors.borderSoft),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.accentLime.withValues(alpha: 0.2)
                  : (iconColor?.withValues(alpha: 0.1) ?? const Color(0xFFF1F3F5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPrimary
                  ? AppColors.accentLime
                  : (iconColor ?? AppColors.primaryNavy),
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppColors.surface : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isPrimary
                  ? AppColors.surface.withValues(alpha: 0.8)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
