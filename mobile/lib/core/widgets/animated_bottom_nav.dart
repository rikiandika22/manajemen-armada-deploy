import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class AnimatedBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = constraints.maxWidth / 4;
            const double selectorWidth = 72;
            const double selectorHeight = 44;
            
            return Stack(
              children: [
                // Active Selector Background
                AnimatedPositioned(
                  left: (widget.currentIndex * itemWidth) + ((itemWidth - selectorWidth) / 2),
                  top: (constraints.maxHeight - selectorHeight) / 2,
                  width: selectorWidth,
                  height: selectorHeight,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentLime,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                // Navigation Items
                Row(
                  children: [
                    _buildNavItem(0, Icons.home_filled, Icons.home_outlined, itemWidth),
                    _buildNavItem(1, Icons.directions_bus, Icons.directions_bus_outlined, itemWidth),
                    _buildNavItem(2, Icons.receipt_long, Icons.receipt_long_outlined, itemWidth, showBadge: true),
                    _buildNavItem(3, Icons.person, Icons.person_outline, itemWidth),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, double width, {bool showBadge = false}) {
    final bool isSelected = widget.currentIndex == index;
    final bool isPressed = _pressedIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) {
        setState(() => _pressedIndex = null);
        widget.onTap(index);
      },
      onTapCancel: () => setState(() => _pressedIndex = null),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 56,
        child: Center(
          child: AnimatedScale(
            scale: isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 72,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected ? AppColors.primaryNavy : AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                  if (showBadge && widget.badgeCount > 0)
                    Positioned(
                      top: 4,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            widget.badgeCount > 9 ? '9+' : widget.badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

