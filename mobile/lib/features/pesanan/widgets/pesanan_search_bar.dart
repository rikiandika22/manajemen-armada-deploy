import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class PesananSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const PesananSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: 'Cari pesanan',
            hintStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textMuted,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
