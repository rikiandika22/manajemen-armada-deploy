import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ArmadaHeader extends StatelessWidget {
  final bool showBackButton;

  const ArmadaHeader({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppColors.textPrimary,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            )
          else
            const SizedBox(width: 48),
          const Text(
            'Armada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // Sized box to balance the back button on the left
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
