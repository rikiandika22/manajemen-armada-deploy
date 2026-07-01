import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/widgets/home_top_bar.dart';
import 'package:mobile/features/home/widgets/home_header.dart';
import 'package:mobile/features/home/widgets/home_search_card.dart';
import 'package:mobile/features/home/widgets/services_grid.dart';
import 'package:mobile/features/home/widgets/home_promo_slider.dart';
import 'package:mobile/features/home/widgets/popular_fleet_section.dart';
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  
  const HomePage({super.key, this.refreshNotifier});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier?.addListener(_onRefreshNotified);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    if (currentOffset > _lastScrollOffset && currentOffset > 60) {
      if (_isHeaderVisible) setState(() => _isHeaderVisible = false);
    } else if (currentOffset < _lastScrollOffset) {
      if (!_isHeaderVisible) setState(() => _isHeaderVisible = true);
    }
    _lastScrollOffset = currentOffset;
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshNotified);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefreshNotified() {
    if (widget.refreshNotifier?.value == 0) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 120), // Extra space for floating bottom nav
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // Enhanced Navy header background
                    Container(
                      height: 280, // Taller to accommodate SafeArea and top bar space
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryNavy,
                            Color.lerp(AppColors.primaryNavy, Colors.white, 0.05)!,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                    ),
                    // Decorative patterns
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                    // Custom curved path pattern
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(
                          size: const Size(double.infinity, 150),
                          painter: _RoutePathPainter(),
                        ),
                      ),
                    ),
                    // Content that sits on top of the background
                    SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 70), // Space for top bar
                          const HomeHeader(), // Transparent, just text
                          const HomeSearchCard(), // Overlaps the navy background
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const ServicesGrid(),
                const SizedBox(height: 24),
                const HomePromoSlider(),
                const SizedBox(height: 32),
                const PopularFleetSection(),
              ],
            ),
          ),
          
          // Animated Top Bar overlapping
          AnimatedPositioned(
             duration: const Duration(milliseconds: 300),
             curve: Curves.easeOutCubic,
             top: _isHeaderVisible ? 0 : -140, 
             left: 0,
             right: 0,
             child: AnimatedOpacity(
               duration: const Duration(milliseconds: 250),
               opacity: _isHeaderVisible ? 1.0 : 0.0,
               child: const HomeTopBar(), 
             ),
          ),
        ],
      ),
    );
  }
}

class _RoutePathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.2, 
      size.width * 0.5, size.height * 0.5
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.8, 
      size.width, size.height * 0.4
    );

    // Draw dashed path
    const dashWidth = 8.0;
    const dashSpace = 8.0;
    double distance = 0.0;
    
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final length = distance + dashWidth < pathMetric.length 
            ? dashWidth 
            : pathMetric.length - distance;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + length),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

