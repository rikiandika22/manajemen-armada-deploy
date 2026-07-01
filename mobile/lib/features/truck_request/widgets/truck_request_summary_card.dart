import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/truck_request/widgets/truck_service_selector.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';

class TruckRequestSummaryCard extends StatelessWidget {
  final TruckServiceType serviceType;
  final Map<String, dynamic> data;

  const TruckRequestSummaryCard({
    super.key,
    required this.serviceType,
    required this.data,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '-';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getLocationText(dynamic location) {
    if (location is LocationResult) {
      return location.text;
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Permintaan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Layanan', _getServiceName()),
          const Divider(height: 16, color: AppColors.borderSoft),
          if (serviceType == TruckServiceType.palawija) ..._buildGoodsSummary(),
          if (serviceType == TruckServiceType.ternak) ..._buildLivestockSummary(),
          if (serviceType == TruckServiceType.material) ..._buildMaterialSummary(),
        ],
      ),
    );
  }

  String _getServiceName() {
    switch (serviceType) {
      case TruckServiceType.palawija:
        return 'Angkut Palawija atau Barang';
      case TruckServiceType.ternak:
        return 'Angkut Ternak';
      case TruckServiceType.material:
        return 'Pesan Pasir atau Abu';
    }
  }

  List<Widget> _buildGoodsSummary() {
    return [
      _buildSummaryRow('Rute', '${_getLocationText(data['lokasiMuat'])} -> ${_getLocationText(data['lokasiBongkar'])}'),
      const SizedBox(height: 8),
      _buildSummaryRow('Jadwal', '${_formatDate(data['tanggal'])}, ${_formatTime(data['jam'])} WIB'),
      const SizedBox(height: 8),
      _buildSummaryRow('Muatan', '${data['muatan'] ?? '-'} (${data['berat'] ?? '-'})'),
    ];
  }

  List<Widget> _buildLivestockSummary() {
    return [
      _buildSummaryRow('Rute', '${_getLocationText(data['lokasiJemput'])} -> ${_getLocationText(data['lokasiTujuan'])}'),
      const SizedBox(height: 8),
      _buildSummaryRow('Jadwal', '${_formatDate(data['tanggal'])}, ${_formatTime(data['jam'])} WIB'),
      const SizedBox(height: 8),
      _buildSummaryRow('Ternak', '${data['jenisTernak'] ?? '-'} (${data['jumlahTernak'] ?? '-'})'),
    ];
  }

  List<Widget> _buildMaterialSummary() {
    return [
      _buildSummaryRow('Tujuan', _getLocationText(data['lokasiKirim'])),
      const SizedBox(height: 8),
      _buildSummaryRow('Jadwal', '${_formatDate(data['tanggal'])}, ${_formatTime(data['jam'])} WIB'),
      const SizedBox(height: 8),
      _buildSummaryRow('Material', '${data['jenisMaterial'] ?? '-'} (${data['jumlahMuatan'] ?? '-'})'),
    ];
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
