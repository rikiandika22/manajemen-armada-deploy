import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/armada/truck_schedule_page.dart';

import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/features/auth/login_page.dart';
import 'package:mobile/features/truck_request/truck_request_page.dart';
import 'package:mobile/features/armada/widgets/armada_image_carousel.dart';

import 'dart:async';
import 'package:mobile/core/services/fleet_service.dart';
import 'package:mobile/features/fleet/models/fleet_unit_model.dart';
import 'package:intl/intl.dart';

class TruckDetailPage extends StatefulWidget {
  final List<String> imageUrls;
  
  const TruckDetailPage({
    super.key,
    this.imageUrls = const [],
  });

  @override
  State<TruckDetailPage> createState() => _TruckDetailPageState();
}

class _TruckDetailPageState extends State<TruckDetailPage> {
  List<FleetUnitModel> _truckUnits = [];
  bool _isLoadingUnits = true;
  String? _errorUnits;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchTruckUnits();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchTruckUnits(isSilent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTruckUnits({bool isSilent = false}) async {
    if (!isSilent && mounted) {
      setState(() {
        _isLoadingUnits = true;
        _errorUnits = null;
      });
    }

    try {
      final units = await FleetService().getTruckUnits();
      if (mounted) {
        setState(() {
          _truckUnits = units;
          _isLoadingUnits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorUnits = e.toString().replaceAll('Exception: ', '');
          _isLoadingUnits = false;
        });
      }
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'Belum tersedia';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _getAggregatedCapacityText() {
    if (_isLoadingUnits) return 'Menghitung...';
    if (_truckUnits.isEmpty) return 'Kapasitas bervariasi';
    
    List<num> capacities = [];
    String? unitStr;
    for (var unit in _truckUnits) {
      if (unit.capacity != null) {
        final parts = unit.capacity!.split(' ');
        if (parts.isNotEmpty) {
          final val = num.tryParse(parts[0]);
          if (val != null) {
            capacities.add(val);
            if (parts.length > 1) {
              unitStr = parts[1];
            }
          }
        }
      }
    }
    
    if (capacities.isEmpty) return 'Kapasitas bervariasi';
    
    final minCap = capacities.reduce((a, b) => a < b ? a : b);
    final maxCap = capacities.reduce((a, b) => a > b ? a : b);
    final unit = unitStr ?? 'Ton';
    
    String formatNum(num v) => v == v.toInt() ? v.toInt().toString() : v.toString().replaceAll('.', ',');
    
    if (minCap == maxCap) {
      return 'Kapasitas ${formatNum(minCap)} $unit';
    }
    return 'Kapasitas ${formatNum(minCap)} sampai ${formatNum(maxCap)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Truk',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _fetchTruckUnits();
                },
                color: AppColors.primaryNavy,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 16),
                      _buildMainInfoCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Ketersediaan Unit'),
                      const SizedBox(height: 12),
                      _buildUnitAvailability(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Layanan yang Didukung'),
                      const SizedBox(height: 12),
                      _buildSupportedServices(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Fasilitas Truk'),
                      const SizedBox(height: 12),
                      _buildFacilityGrid(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Spesifikasi Unit Truk'),
                      const SizedBox(height: 12),
                      _buildDynamicSpecificationCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Informasi Jadwal'),
                      const SizedBox(height: 12),
                      _buildScheduleInfoCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Tentang Truk'),
                      const SizedBox(height: 12),
                      _buildAboutSection(),
                      const SizedBox(height: 24),
                      _buildNoteSection(),
                      const SizedBox(height: 120), // Spacer for bottom action
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context),
    );
  }

  Widget _buildImageSection() {
    List<String> combinedUrls = _truckUnits.expand((unit) => unit.imageUrls).toList();
    if (combinedUrls.isEmpty) {
      combinedUrls = widget.imageUrls;
    }

    return ArmadaImageCarousel(
      imageUrls: combinedUrls,
      status: 'Tersedia', // dummy
      fallbackIcon: Icons.local_shipping,
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hino 300 Bak Terbuka',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Truk Logistik • Angkutan Barang dan Material',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.scale, size: 16, color: AppColors.primaryNavy),
                    const SizedBox(width: 6),
                    Text(
                      _getAggregatedCapacityText(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Tarif Dasar',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Mulai dari Rp 800.000',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLime,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.0, left: 4.0),
                child: Text(
                  '/rit',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Harga akhir ditentukan admin berdasarkan layanan, jarak, jenis muatan, volume, dan kondisi lokasi.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitAvailability() {
    if (_isLoadingUnits) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
      );
    }
    
    if (_errorUnits != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text('Gagal memuat ketersediaan: $_errorUnits', style: const TextStyle(color: Colors.red, fontSize: 13)),
      );
    }

    if (_truckUnits.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: const Text('Belum ada unit truk yang terdaftar', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: _truckUnits.asMap().entries.map((entry) {
          final isLast = entry.key == _truckUnits.length - 1;
          final unit = entry.value;
          final statusStr = unit.status ?? 'Tersedia';
          final isAvailable = statusStr == 'Tersedia';
          final isScheduled = statusStr == 'Terjadwal';

          Color statusColor;
          Color statusBgColor;

          if (isAvailable) {
            statusColor = Colors.green;
            statusBgColor = Colors.green.withValues(alpha: 0.1);
          } else if (isScheduled) {
            statusColor = Colors.blue;
            statusBgColor = Colors.blue.withValues(alpha: 0.1);
          } else {
            statusColor = Colors.orange;
            statusBgColor = Colors.orange.withValues(alpha: 0.1);
          }
          
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unit.fleetCode ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast) const Divider(height: 24, color: AppColors.borderSoft),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryNavy,
        ),
      ),
    );
  }

  Widget _buildSupportedServices() {
    final services = [
      {'icon': Icons.inventory_2_outlined, 'label': 'Angkut Palawija atau Barang', 'price': 'Mulai dari Rp 800.000 per rit'},
      {'icon': Icons.pets, 'label': 'Angkut Ternak', 'price': 'Mulai dari Rp 1.000.000 per rit'},
      {'icon': Icons.landscape_outlined, 'label': 'Pesan Pasir atau Abu', 'price': 'Tarif menyesuaikan volume dan lokasi'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: services.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Icon(s['icon'] as IconData, color: AppColors.primaryNavy),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['label'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s['price'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFacilityGrid() {
    final facilities = [
      {'icon': Icons.grid_goldenratio, 'label': 'Bak Terbuka'},
      {'icon': Icons.scale, 'label': 'Berbagai Kapasitas'},
      {'icon': Icons.roofing, 'label': 'Terpal'},
      {'icon': Icons.cable, 'label': 'Tali Pengikat'},
      {'icon': Icons.person, 'label': 'Sopir Berpengalaman'},
      {'icon': Icons.check_circle_outline, 'label': 'Cocok untuk Barang dan Material'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          final item = facilities[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, size: 18, color: AppColors.primaryNavy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicSpecificationCard() {
    if (_isLoadingUnits) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
      );
    }
    
    if (_errorUnits != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text('Gagal memuat spesifikasi: $_errorUnits', style: const TextStyle(color: Colors.red, fontSize: 13)),
      );
    }

    if (_truckUnits.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: const Text('Belum ada unit truk yang terdaftar', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: _truckUnits.map((unit) {
          final statusStr = unit.status ?? 'Belum tersedia';
          final isAvailable = statusStr == 'Tersedia';
          final isScheduled = statusStr == 'Terjadwal';

          Color statusColor;
          Color statusBgColor;

          if (isAvailable) {
            statusColor = Colors.green;
            statusBgColor = Colors.green.withValues(alpha: 0.1);
          } else if (isScheduled) {
            statusColor = Colors.blue;
            statusBgColor = Colors.blue.withValues(alpha: 0.1);
          } else {
            statusColor = Colors.orange;
            statusBgColor = Colors.orange.withValues(alpha: 0.1);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  unit.fleetCode ?? '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      unit.fleetName ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                childrenPadding: const EdgeInsets.all(16.0).copyWith(top: 0),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 24, color: AppColors.borderSoft),
                  if (unit.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        unit.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          width: double.infinity,
                          color: const Color(0xFFF1F3F5),
                          child: const Icon(Icons.local_shipping, color: AppColors.textMuted, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSpecRow('Nomor Armada', unit.fleetCode ?? 'Belum tersedia'),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Nama Armada', unit.fleetName ?? 'Belum tersedia'),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Jenis Kendaraan', unit.vehicleType ?? 'Belum tersedia'),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Kapasitas', unit.capacity ?? 'Belum tersedia'),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Plat Nomor', unit.licensePlate ?? 'Belum tersedia'),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Tahun', unit.year ?? 'Belum tersedia'),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Status Operasional', unit.status ?? 'Belum tersedia'),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Kondisi', unit.condition ?? 'Belum tersedia', valueColor: Colors.green),
                  const Divider(height: 16, color: AppColors.borderSoft),
                  _buildSpecRow('Harga Awal', _formatCurrency(unit.price)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.accentLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: AppColors.primaryNavy),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tersedia pada 28 Mei 2026. Admin akan mengonfirmasi jadwal, sopir, dan estimasi biaya setelah permintaan dikirim.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryNavy,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'Hino 300 Bak Terbuka cocok untuk pengangkutan hasil palawija, barang dagangan, material bangunan, pasir, abu batu, dan kebutuhan logistik ringan hingga menengah. Armada ini dapat digunakan dari pasar, depo, gudang, pabrik, atau lokasi pelanggan sesuai konfirmasi admin.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Catatan Layanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          SizedBox(height: 12),
          _NoteItem(text: 'Harga akhir akan dikonfirmasi oleh admin.'),
          _NoteItem(text: 'Ketersediaan truk bergantung pada jadwal dan kondisi operasional.'),
          _NoteItem(text: 'Pastikan lokasi muat dan bongkar dapat diakses truk.'),
          _NoteItem(text: 'Untuk ternak atau material tertentu, admin dapat menghubungi pelanggan untuk konfirmasi tambahan.'),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TruckSchedulePage(
                    fleetGroup: 'all_trucks',
                  )),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: AppColors.primaryNavy),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Lihat Jadwal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (!AuthState.instance.isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(
                        onLoginSuccess: () {
                          Navigator.pop(context); // close login
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TruckRequestPage(source: 'fleet_truck_request')),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TruckRequestPage(source: 'fleet_truck_request')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentLime,
                foregroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Ajukan Permintaan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _NoteItem extends StatelessWidget {
  final String text;
  const _NoteItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
