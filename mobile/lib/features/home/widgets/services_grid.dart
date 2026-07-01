import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/armada/armada_page.dart';
import 'package:mobile/features/truck_request/truck_request_page.dart';
import 'package:mobile/features/pesanan/pesanan_page.dart';
import 'package:mobile/features/schedule/pages/schedule_fleet_picker_page.dart';
import 'package:mobile/core/utils/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  final List<Map<String, dynamic>> services = const [
    {
      'icon': Icons.directions_bus_outlined,
      'title': 'Sewa Bus',
    },
    {
      'icon': Icons.airport_shuttle_outlined,
      'title': 'Rental Elf',
    },
    {
      'icon': Icons.local_shipping_outlined,
      'title': 'Truk Logistik',
    },
    {
      'icon': Icons.calendar_today_outlined,
      'title': 'Cek Jadwal',
    },
    {
      'icon': Icons.history_outlined,
      'title': 'Riwayat Pesanan',
    },
    {
      'icon': Icons.help_outline_outlined,
      'title': 'Bantuan',
    },
  ];

  void _handleTap(BuildContext context, String title) async {
    switch (title) {
      case 'Sewa Bus':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ArmadaPage(initialCategory: 'Bus')));
        break;
      case 'Rental Elf':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ArmadaPage(initialCategory: 'Elf')));
        break;
      case 'Truk Logistik':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TruckRequestPage(source: 'service_truck_request')));
        break;
      case 'Cek Jadwal':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleFleetPickerPage()));
        break;
      case 'Riwayat Pesanan':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PesananPage()));
        break;
      case 'Bantuan':
        final url = Uri.parse('https://wa.me/62895412506326?text=Halo%20admin%20Sumber%20Agung%20Trans%2C%20saya%20ingin%20bertanya%20tentang%20layanan%20armada.');
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) AppSnackBar.showError(context, 'Tidak dapat membuka WhatsApp.');
          }
        } catch (e) {
          if (context.mounted) AppSnackBar.showError(context, 'Tidak dapat membuka WhatsApp.');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Layanan Kami',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final service = services[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleTap(context, service['title']),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.borderSoft.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F3F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            service['icon'],
                            color: AppColors.primaryNavy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            service['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
