import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/armada/armada_schedule_page.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/features/auth/login_page.dart';
import 'package:mobile/features/booking/booking_page.dart';
import 'package:mobile/features/booking/usage_schedule_form_page.dart';
import 'package:mobile/features/armada/widgets/armada_image_carousel.dart';
import 'package:mobile/core/services/fleet_service.dart';
import 'package:mobile/features/fleet/models/fleet_model.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class ArmadaDetailPage extends StatefulWidget {
  final bool showScheduleSummary;
  final List<String> imageUrls;
  final int? fleetId;
  final String? origin;
  final double? originLat;
  final double? originLng;
  final String? destination;
  final double? destinationLat;
  final double? destinationLng;
  final String? date;
  
  const ArmadaDetailPage({
    super.key, 
    this.showScheduleSummary = false,
    this.imageUrls = const [],
    this.fleetId,
    this.origin,
    this.originLat,
    this.originLng,
    this.destination,
    this.destinationLat,
    this.destinationLng,
    this.date,
  });

  @override
  State<ArmadaDetailPage> createState() => _ArmadaDetailPageState();
}

class _ArmadaDetailPageState extends State<ArmadaDetailPage> {
  final FleetService _fleetService = FleetService();
  FleetModel? _fleet;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.fleetId != null) {
      _isLoading = true;
      _fetchDetail();
    }
  }

  Future<void> _fetchDetail() async {
    if (widget.fleetId == null) return;
    
    try {
      final fleet = await _fleetService.getFleetDetail(widget.fleetId!);
      if (mounted) {
        setState(() {
          _fleet = fleet;
          _error = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        AppSnackBar.showError(context, 'Gagal memuat ulang data armada. Coba lagi.');
      }
    }
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
          'Detail Armada',
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
        child: _buildBody(),
      ),
      bottomSheet: _buildBottomAction(context),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _fleet == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentLime));
    }
    
    if (_error != null && _fleet == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchDetail();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLime),
              child: const Text('Coba Lagi', style: TextStyle(color: AppColors.primaryNavy)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: AppColors.accentLime,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  _buildMainInfoCard(),
                  if (widget.showScheduleSummary) ...[
                    const SizedBox(height: 16),
                    _buildScheduleRouteCard(context),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionTitle('Fasilitas Armada'),
                  const SizedBox(height: 12),
                  _buildFacilityGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Spesifikasi'),
                  const SizedBox(height: 12),
                  _buildSpecificationCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Informasi Jadwal'),
                  const SizedBox(height: 12),
                  _buildScheduleInfoCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Tentang Armada'),
                  const SizedBox(height: 12),
                  _buildAboutSection(),
                  const SizedBox(height: 120), // Spacer for bottom action
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final images = _fleet?.imageUrls.isNotEmpty == true 
      ? _fleet!.imageUrls 
      : widget.imageUrls;
    
    return ArmadaImageCarousel(
      imageUrls: images,
      status: _fleet?.status ?? 'Tersedia',
      fallbackIcon: Icons.directions_bus,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fleet?.fleetName ?? 'Bus Executive 40 Seat',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fleet?.fleetType ?? 'Bus Pariwisata'} • Sewa Full Armada',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
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
                    const Icon(Icons.airline_seat_recline_normal, size: 16, color: AppColors.primaryNavy),
                    const SizedBox(width: 6),
                    Text(
                      _fleet?.capacity ?? '40 Kursi',
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
            'Harga Sewa',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fleet?.priceText ?? 'Rp 2.500.000',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLime,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4.0, left: 4.0),
                child: Text(
                  '/hari',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRouteCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.route_outlined, color: AppColors.primaryNavy),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grobogan → Semarang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '28 Mei 2026 • Bus',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              AppSnackBar.showInfo(context, 'Fitur ubah rute belum tersedia');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Ubah',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

  Widget _buildFacilityGrid() {
    final facilities = [
      {'icon': Icons.ac_unit, 'label': 'AC'},
      {'icon': Icons.chair, 'label': 'Reclining Seat'},
      {'icon': Icons.speaker, 'label': 'Audio'},
      {'icon': Icons.luggage, 'label': 'Bagasi'},
      {'icon': Icons.tv, 'label': 'TV'},
      {'icon': Icons.electrical_services, 'label': 'USB Charger'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.5,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: const TextStyle(
                      fontSize: 13,
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

  Widget _buildSpecificationCard() {
    final Color statusColor = (_fleet?.status == 'Tersedia' || _fleet == null)
        ? Colors.green
        : (_fleet?.status == 'Dipesan' || _fleet?.status == 'Terjadwal')
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          _buildSpecRow('Nomor Armada', _fleet?.fleetCode ?? 'ARM 001'),
          const Divider(height: 24, color: AppColors.borderSoft),
          _buildSpecRow('Tahun', '2020'), // Hardcoded as placeholder
          const Divider(height: 24, color: AppColors.borderSoft),
          _buildSpecRow('Plat Nomor', _fleet?.licensePlate ?? 'K 1234 XX'),
          const Divider(height: 24, color: AppColors.borderSoft),
          _buildSpecRow('Kondisi', _fleet?.status ?? 'Siap Operasional', valueColor: statusColor),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
              'Tersedia untuk disewa. Silakan buat pesanan dengan mengisi jadwal penggunaan.',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        _fleet?.description ?? 'Bus/Elf cocok untuk perjalanan rombongan, wisata keluarga, atau kegiatan sekolah dengan fasilitas lengkap dan nyaman.',
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
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
                  MaterialPageRoute(builder: (context) => ArmadaSchedulePage(
                    fleetId: _fleet?.id ?? 0,
                    fleetName: _fleet?.fleetName ?? 'Bus/Elf',
                    fleetPlate: _fleet?.licensePlate ?? '',
                    fleetType: _fleet?.fleetType ?? '-',
                    capacity: _fleet?.capacity ?? '',
                    priceText: _fleet?.priceText ?? '-',
                  )),
                ).then((_) {
                  // Re-fetch detail after coming back
                  _fetchDetail();
                });
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
                          if (!widget.showScheduleSummary) {
                            AppSnackBar.showWarning(context, 'Isi jadwal armada terlebih dahulu');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UsageScheduleFormPage(
                                  armadaName: _fleet?.fleetName ?? 'Bus/Elf',
                                  armadaType: _fleet?.fleetType ?? 'Armada',
                                  capacity: _fleet?.capacity ?? '-',
                                  price: _fleet?.priceText ?? '-',
                                  initialOrigin: widget.origin,
                                  initialOriginLat: widget.originLat,
                                  initialOriginLng: widget.originLng,
                                  initialDestination: widget.destination,
                                  initialDestinationLat: widget.destinationLat,
                                  initialDestinationLng: widget.destinationLng,
                                  initialDate: widget.date,
                                ),
                              ),
                            ).then((_) => _fetchDetail());
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingPage(),
                              ),
                            ).then((_) => _fetchDetail());
                          }
                        },
                      ),
                    ),
                  );
                  return;
                }

                if (!widget.showScheduleSummary) {
                  AppSnackBar.showWarning(context, 'Isi jadwal armada terlebih dahulu');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsageScheduleFormPage(
                        armadaName: _fleet?.fleetName ?? 'Bus/Elf',
                        armadaType: _fleet?.fleetType ?? 'Armada',
                        capacity: _fleet?.capacity ?? '-',
                        price: _fleet?.priceText ?? '-',
                        initialOrigin: widget.origin,
                        initialOriginLat: widget.originLat,
                        initialOriginLng: widget.originLng,
                        initialDestination: widget.destination,
                        initialDestinationLat: widget.destinationLat,
                        initialDestinationLng: widget.destinationLng,
                        initialDate: widget.date,
                      ),
                    ),
                  ).then((_) => _fetchDetail());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookingPage()),
                  ).then((_) => _fetchDetail());
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
                'Booking Sekarang',
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
