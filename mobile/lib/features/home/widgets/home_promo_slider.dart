import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/armada/armada_page.dart';
import 'package:mobile/features/pesanan/pesanan_page.dart';
import 'package:mobile/features/schedule/pages/schedule_fleet_picker_page.dart';
import 'package:mobile/features/truck_request/truck_request_page.dart';

class HomePromoSlider extends StatefulWidget {
  const HomePromoSlider({super.key});

  @override
  State<HomePromoSlider> createState() => _HomePromoSliderState();
}

class _HomePromoSliderState extends State<HomePromoSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Cek Jadwal Lebih Mudah',
      'description': 'Lihat ketersediaan armada sebelum melakukan pemesanan.',
      'icon': Icons.calendar_month_outlined,
      'actionText': 'Selengkapnya',
      'color': AppColors.primaryNavy,
      'action': (BuildContext context) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleFleetPickerPage()));
      }
    },
    {
      'title': 'Sewa Bus dan Elf',
      'description': 'Pilihan armada penumpang untuk keluarga, sekolah, kantor, dan rombongan.',
      'icon': Icons.directions_bus_outlined,
      'actionText': 'Cari Armada',
      'color': const Color(0xFF1E293B),
      'action': (BuildContext context) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ArmadaPage(
          source: 'banner',
          fleetType: 'all_passenger',
          initialCategory: 'Semua',
        )));
      }
    },
    {
      'title': 'Truk Logistik',
      'description': 'Ajukan kebutuhan angkut barang, ternak, pasir, abu, atau material.',
      'icon': Icons.local_shipping_outlined,
      'actionText': 'Ajukan Permintaan',
      'color': const Color(0xFF0F172A),
      'action': (BuildContext context) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TruckRequestPage(source: 'home_banner')));
      }
    },
    {
      'title': 'Pantau Pesanan',
      'description': 'Lihat status reservasi, pembayaran, dan riwayat pesanan Anda.',
      'icon': Icons.security_outlined,
      'actionText': 'Lihat Riwayat',
      'color': const Color(0xFF263238),
      'action': (BuildContext context) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PesananPage()));
      }
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => banner['action'](context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            banner['color'],
                            Color.lerp(banner['color'] as Color, Colors.black, 0.3)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: banner['color'].withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.accentLime.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  banner['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      banner['actionText'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentLime,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward, size: 14, color: AppColors.accentLime),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentLime.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              banner['icon'],
                              color: AppColors.accentLime,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentLime : AppColors.borderSoft,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
