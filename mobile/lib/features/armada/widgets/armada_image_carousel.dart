import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ArmadaImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final String status;
  final IconData fallbackIcon;

  const ArmadaImageCarousel({
    super.key,
    required this.imageUrls,
    required this.status,
    this.fallbackIcon = Icons.directions_bus,
  });

  @override
  State<ArmadaImageCarousel> createState() => _ArmadaImageCarouselState();
}

class _ArmadaImageCarouselState extends State<ArmadaImageCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.softNavy,
              borderRadius: BorderRadius.circular(24.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.imageUrls.isEmpty
                ? Center(
                    child: Icon(
                      widget.fallbackIcon,
                      size: 80,
                      color: AppColors.surface,
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.imageUrls[index],
                        key: ValueKey(widget.imageUrls[index]),
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            widget.fallbackIcon,
                            size: 80,
                            color: AppColors.surface,
                          ),
                        ),
                      );
                    },
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
                      color: widget.status == 'Tersedia' 
                          ? Colors.green 
                          : widget.status == 'Dipesan' ? Colors.grey : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.status,
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
          
          // Dot Indicators
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => _buildDotIndicator(index == _currentIndex),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentLime : AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
