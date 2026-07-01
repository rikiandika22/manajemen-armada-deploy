import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class TruckRequestBottomAction extends StatelessWidget {
  final bool isValid;
  final VoidCallback onSubmit;

  const TruckRequestBottomAction({
    super.key,
    required this.isValid,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isValid ? onSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? AppColors.accentLime : AppColors.borderSoft,
            foregroundColor: isValid ? AppColors.primaryNavy : AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Kirim Permintaan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
