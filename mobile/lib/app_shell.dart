import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/animated_bottom_nav.dart';
import 'package:mobile/features/armada/armada_page.dart';
import 'package:mobile/features/home/home_page.dart';
import 'package:mobile/features/pesanan/pesanan_page.dart';
import 'package:mobile/features/profil/profil_page.dart';
import 'package:mobile/core/services/badge_service.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late int _currentIndex;
  int _badgeCount = 0;
  final ValueNotifier<int> _tabRefreshNotifier = ValueNotifier(-1);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _fetchBadgeCount();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabRefreshNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchBadgeCount();
    }
  }

  Future<void> _fetchBadgeCount() async {
    final count = await BadgeService().getUnreadCount();
    if (mounted) {
      setState(() {
        _badgeCount = count;
      });
    }
  }

  // Use a PageController if you want swipe animations between pages,
  // but IndexedStack is usually better for preserving state without rebuilding.
  // We'll use IndexedStack for instant, state-preserving tab switching.
  late final List<Widget> _pages = [
    HomePage(refreshNotifier: _tabRefreshNotifier),
    ArmadaPage(source: 'bottom_nav', refreshNotifier: _tabRefreshNotifier),
    PesananPage(
      refreshNotifier: _tabRefreshNotifier,
      onBadgeUpdateNeeded: _fetchBadgeCount,
    ),
    ProfilPage(refreshNotifier: _tabRefreshNotifier),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Trigger refresh
      _tabRefreshNotifier.value = -1;
      _tabRefreshNotifier.value = index;
      return;
    }
    
    setState(() {
      _currentIndex = index;
    });
    // Also fetch badge count when switching tabs just in case
    _fetchBadgeCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // The main content area
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          
          // Floating Bottom Navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBottomNav(
              currentIndex: _currentIndex,
              badgeCount: _badgeCount,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}
