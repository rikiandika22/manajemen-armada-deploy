import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class PesananSummaryCards extends StatelessWidget {
  final int totalPesanan;
  final int pesananAktif;
  final int menungguKonfirmasi;

  const PesananSummaryCards({
    super.key,
    required this.totalPesanan,
    required this.pesananAktif,
    required this.menungguKonfirmasi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // If screen is extremely small, use Wrap, otherwise use Row with Expanded
          if (constraints.maxWidth < 280) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCard(
                  title: 'Total Pesanan',
                  value: totalPesanan.toString(),
                  icon: Icons.receipt_long,
                  isPrimary: true,
                  fixedWidth: constraints.maxWidth,
                ),
                _buildCard(
                  title: 'Pesanan Aktif',
                  value: pesananAktif.toString(),
                  icon: Icons.directions_bus_outlined,
                  isPrimary: false,
                  fixedWidth: (constraints.maxWidth - 8) / 2,
                ),
                _buildCard(
                  title: 'Menunggu Konfirmasi',
                  value: menungguKonfirmasi.toString(),
                  icon: Icons.access_time,
                  isPrimary: false,
                  fixedWidth: (constraints.maxWidth - 8) / 2,
                ),
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildCard(
                    title: 'Total Pesanan',
                    value: totalPesanan.toString(),
                    icon: Icons.receipt_long,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCard(
                    title: 'Pesanan Aktif',
                    value: pesananAktif.toString(),
                    icon: Icons.directions_bus_outlined,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCard(
                    title: 'Menunggu Konfirmasi',
                    value: menungguKonfirmasi.toString(),
                    icon: Icons.access_time,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isPrimary,
    double? fixedWidth,
  }) {
    return Container(
      width: fixedWidth,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primaryNavy : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.accentLime.withValues(alpha: 0.2) : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isPrimary ? AppColors.accentLime : AppColors.primaryNavy,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? AppColors.surface : AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: isPrimary ? AppColors.surface.withValues(alpha: 0.8) : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
