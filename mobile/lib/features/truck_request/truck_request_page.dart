import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/shared/widgets/custom_input_field.dart';
import 'package:mobile/features/truck_request/truck_request_success_page.dart';
import 'package:mobile/core/services/order_service.dart';
import 'package:mobile/core/utils/app_snackbar.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';
import 'package:mobile/shared/widgets/app_date_time_picker.dart';
import 'package:mobile/core/utils/date_time_formatter.dart';

class TruckRequestPage extends StatefulWidget {
  final String source; // 'home_truck_request' or 'fleet_truck_request'
  final String? initialMuatan;
  final String? origin;
  final String? destination;
  final String? date;
  final String routeMode;
  
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;

  // Fleet Detail if opened from ArmadaDetailPage
  final int? fleetId;
  final String? fleetName;
  final String? fleetCapacity;
  final String? fleetStatus;

  const TruckRequestPage({
    super.key,
    this.source = 'direct_truck_request',
    this.initialMuatan,
    this.origin,
    this.destination,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.date,
    this.routeMode = 'two_points',
    this.fleetId,
    this.fleetName,
    this.fleetCapacity,
    this.fleetStatus,
  });

  @override
  State<TruckRequestPage> createState() => _TruckRequestPageState();
}

class _TruckRequestPageState extends State<TruckRequestPage> {
  final List<String> jenisMuatanOptions = ['Pasir atau Abu', 'Palawija atau Barang', 'Ternak', 'Material', 'Lainnya'];
  final List<String> jenisLayanan = ['Angkut Palawija atau Barang', 'Angkut Ternak', 'Pesan Pasir atau Abu', 'Angkut Material', 'Lainnya'];

  String? _selectedMuatan;
  String _routeMode = 'two_points';
  
  LocationResult? _lokasiAsal;
  LocationResult? _lokasiTujuan;
  
  DateTime? _tanggalPenggunaan;

  final TextEditingController _jamController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _catatanMuatanController = TextEditingController();
  final TextEditingController _catatanLokasiController = TextEditingController();
  final TextEditingController _kebutuhanKhususController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.source == 'home_truck_request') {
      _selectedMuatan = widget.initialMuatan;
      _routeMode = widget.routeMode;
      
      if (widget.origin != null && widget.origin != 'Ditentukan Admin' && widget.origin!.isNotEmpty) {
        _lokasiAsal = LocationResult(
          text: widget.origin!,
          lat: widget.originLat,
          lng: widget.originLng,
        );
      }
      if (widget.destination != null && widget.destination!.isNotEmpty) {
        _lokasiTujuan = LocationResult(
          text: widget.destination!,
          lat: widget.destinationLat,
          lng: widget.destinationLng,
        );
      }
      
      if (widget.date != null && widget.date!.isNotEmpty) {
        try {
          final parts = widget.date!.split(' ');
          if (parts.length == 3) {
            // It's likely an Indonesian date like "2 Juni 2026"
            final day = int.parse(parts[0]);
            final monthStr = parts[1].toLowerCase();
            final year = int.parse(parts[2]);
            
            int month = 1;
            if (monthStr == 'januari') month = 1;
            if (monthStr == 'februari') month = 2;
            if (monthStr == 'maret') month = 3;
            if (monthStr == 'april') month = 4;
            if (monthStr == 'mei') month = 5;
            if (monthStr == 'juni') month = 6;
            if (monthStr == 'juli') month = 7;
            if (monthStr == 'agustus') month = 8;
            if (monthStr == 'september') month = 9;
            if (monthStr == 'oktober') month = 10;
            if (monthStr == 'november') month = 11;
            if (monthStr == 'desember') month = 12;
            
            _tanggalPenggunaan = DateTime(year, month, day);
          } else if (widget.date!.contains('/')) {
            final splitDate = widget.date!.split('/');
            if (splitDate.length == 3) {
              final y = int.parse(splitDate[2]);
              final m = int.parse(splitDate[1]);
              final d = int.parse(splitDate[0]);
              _tanggalPenggunaan = DateTime(y, m, d);
            }
          } else {
             // Try standard ISO
             _tanggalPenggunaan = DateTime.parse(widget.date!);
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _jamController.dispose();
    _beratController.dispose();
    _volumeController.dispose();
    _catatanMuatanController.dispose();
    _catatanLokasiController.dispose();
    _kebutuhanKhususController.dispose();
    super.dispose();
  }
  
  String _getRouteMode(String muatan) {
    if (muatan == 'Pasir atau Abu' || muatan == 'Material') {
      return 'destination_only';
    }
    return 'two_points';
  }

  void _onMuatanChanged(String? newMuatan) {
    if (newMuatan == null || newMuatan == _selectedMuatan) return;
    
    setState(() {
      _selectedMuatan = newMuatan;
      _routeMode = _getRouteMode(newMuatan);
      if (_routeMode == 'destination_only') {
        _lokasiAsal = null;
      }
    });
  }

  void _submitRequest() async {
    // Validations
    if (_selectedMuatan == null || _selectedMuatan!.isEmpty) {
      AppSnackBar.showWarning(context, 'Pilih jenis muatan terlebih dahulu.');
      return;
    }
    
    if (_routeMode == 'destination_only') {
      if (_lokasiTujuan == null) {
        AppSnackBar.showWarning(context, 'Pilih lokasi tujuan pengiriman terlebih dahulu.');
        return;
      }
    } else {
      if (_lokasiAsal == null || _lokasiTujuan == null) {
        AppSnackBar.showWarning(context, 'Lengkapi rute pengangkutan terlebih dahulu.');
        return;
      }
    }

    if (_tanggalPenggunaan == null) {
      AppSnackBar.showWarning(context, 'Pilih tanggal penggunaan terlebih dahulu.');
      return;
    }

    if (_jamController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Lengkapi data jam penggunaan terlebih dahulu.');
      return;
    }

    if (_beratController.text.isNotEmpty) {
      final val = double.tryParse(_beratController.text.replaceAll(',', '.'));
      if (val == null || val <= 0) {
        AppSnackBar.showWarning(context, 'Estimasi berat harus berupa angka yang valid.');
        return;
      }
    }
    
    if (_volumeController.text.isNotEmpty) {
      final val = double.tryParse(_volumeController.text.replaceAll(',', '.'));
      if (val == null || val <= 0) {
        AppSnackBar.showWarning(context, 'Estimasi volume atau jumlah harus berupa angka yang valid.');
        return;
      }
    }
    
    if (_catatanMuatanController.text.isEmpty) {
      if (_selectedMuatan == 'Lainnya') {
          AppSnackBar.showWarning(context, 'Lengkapi catatan muatan minimal singkat.');
          return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final originText = _routeMode == 'destination_only' ? 'Ditentukan Admin' : (_lokasiAsal?.text ?? '-');
      final destinationText = _lokasiTujuan?.text ?? '-';
      
      // Parse numbers from strings to avoid sending '2 ton'
      final rawWeight = _beratController.text;
      final numericWeight = rawWeight.replaceAll(RegExp(r'[^0-9.]'), '');
      
      final rawVolume = _volumeController.text;
      final numericVolume = rawVolume.replaceAll(RegExp(r'[^0-9.]'), '');
      
      // Format time to HH:mm:ss for backend
      String formattedTime = _jamController.text;
      final timeRegex = RegExp(r'(\d{1,2})[\.:](\d{2})');
      final timeMatch = timeRegex.firstMatch(formattedTime);
      if (timeMatch != null) {
          final h = timeMatch.group(1)?.padLeft(2, '0') ?? '00';
          final m = timeMatch.group(2)?.padLeft(2, '0') ?? '00';
          formattedTime = '$h:$m:00';
      }

      final requestData = {
        'service_type': 'Truk Logistik',
        'truck_service_type': _selectedMuatan,
        'fleet_name': widget.fleetName ?? 'Menunggu Penetapan Admin',
        'fleet_type': 'Truk',
        if (widget.fleetId != null) 'selected_fleet_id': widget.fleetId,
        'origin': originText,
        'destination': destinationText,
        if (_lokasiAsal?.lat != null) 'origin_latitude': _lokasiAsal!.lat,
        if (_lokasiAsal?.lng != null) 'origin_longitude': _lokasiAsal!.lng,
        if (_lokasiTujuan?.lat != null) 'destination_latitude': _lokasiTujuan!.lat,
        if (_lokasiTujuan?.lng != null) 'destination_longitude': _lokasiTujuan!.lng,
        'departure_date': DateTimeFormatter.formatBackendDate(_tanggalPenggunaan!),
        'departure_time': formattedTime,
        'notes': 'Kebutuhan Khusus: ${_kebutuhanKhususController.text}',
        'truck_load_type': _selectedMuatan,
        'truck_load_description': _catatanMuatanController.text,
        if (numericWeight.isNotEmpty) 'truck_load_weight': numericWeight,
        if (numericWeight.isNotEmpty) 'truck_load_weight_unit': 'ton', // default safe unit
        if (numericVolume.isNotEmpty) 'truck_load_quantity': numericVolume,
        if (numericVolume.isNotEmpty) 'truck_load_quantity_unit': '',
        'truck_access_note': _catatanLokasiController.text,
        'truck_additional_note': _kebutuhanKhususController.text,
      };

      final createdOrder = await OrderService().createOrder(requestData);

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TruckRequestSuccessPage(orderId: createdOrder.id)),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _tanggalPenggunaan ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _tanggalPenggunaan = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _jamController.text = DateTimeFormatter.formatIndonesianTime(picked);
      });
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
          'Permintaan Truk',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Lengkapi detail pengangkutan agar admin dapat menentukan unit dan harga yang sesuai.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    if (widget.fleetId != null && widget.fleetName != null) ...[
                      _buildSelectedFleetCard(),
                      const SizedBox(height: 24),
                    ],

                    _buildSectionTitle('Detail Pengangkutan'),
                    const SizedBox(height: 12),
                    _buildPengangkutanCard(),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Detail Muatan'),
                    const SizedBox(height: 12),
                    _buildMuatanCard(),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Detail Lokasi & Waktu'),
                    const SizedBox(height: 12),
                    _buildLokasiWaktuCard(),
                    const SizedBox(height: 24),

                    _buildInfoHargaCard(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildSelectedFleetCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping, color: AppColors.surface, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Armada Dipilih', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  widget.fleetName!,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (widget.fleetCapacity != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.fleetCapacity!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
    );
  }

  Widget _buildPengangkutanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownField(
            label: 'Jenis Muatan',
            value: _selectedMuatan,
            hint: 'Pilih jenis muatan',
            options: jenisMuatanOptions,
            onChanged: _onMuatanChanged,
          ),
          const SizedBox(height: 16),
          
          if (_selectedMuatan == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Pilih jenis muatan terlebih dahulu.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            )
          else ...[
            if (_routeMode == 'destination_only') ...[
              _buildLocationField(
                label: 'Lokasi Tujuan Pengiriman',
                value: _lokasiTujuan?.text,
                onTap: () async {
                  final res = await showLocationPickerBottomSheet(context, title: 'Lokasi Tujuan Pengiriman');
                  if (res != null) setState(() => _lokasiTujuan = res);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Lokasi asal pengambilan akan ditentukan oleh admin. Silakan isi lokasi tujuan pengiriman.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ] else ...[
              _buildLocationField(
                label: _selectedMuatan == 'Ternak' ? 'Lokasi Jemput Ternak' : (_selectedMuatan == 'Palawija atau Barang' ? 'Lokasi Muat' : 'Lokasi Asal'),
                value: _lokasiAsal?.text,
                onTap: () async {
                  final res = await showLocationPickerBottomSheet(context, title: 'Pilih Lokasi');
                  if (res != null) setState(() => _lokasiAsal = res);
                },
              ),
              const SizedBox(height: 16),
              _buildLocationField(
                label: 'Lokasi Tujuan',
                value: _lokasiTujuan?.text,
                onTap: () async {
                  final res = await showLocationPickerBottomSheet(context, title: 'Lokasi Tujuan');
                  if (res != null) setState(() => _lokasiTujuan = res);
                },
              ),
            ],
          ],
          
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Tanggal Penggunaan',
            value: _tanggalPenggunaan != null ? DateTimeFormatter.formatIndonesianDate(_tanggalPenggunaan!) : null,
            onTap: _pickDate,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              builder: (context) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pilih jenis muatan',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Pilih kategori muatan agar admin dapat menentukan unit truk yang sesuai.',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textSecondary),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // List options
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: options.map((opt) {
                                final isSelected = value == opt;
                                IconData iconData;
                                String subtitle;
                                switch (opt) {
                                  case 'Pasir atau Abu':
                                    iconData = Icons.terrain;
                                    subtitle = 'Untuk pasir, abu, dan material curah.';
                                    break;
                                  case 'Palawija atau Barang':
                                    iconData = Icons.inventory_2;
                                    subtitle = 'Untuk hasil panen, karung, atau barang umum.';
                                    break;
                                  case 'Ternak':
                                    iconData = Icons.pets;
                                    subtitle = 'Untuk sapi, kambing, dan hewan ternak.';
                                    break;
                                  case 'Material':
                                    iconData = Icons.construction;
                                    subtitle = 'Untuk bahan bangunan dan kebutuhan proyek.';
                                    break;
                                  default:
                                    iconData = Icons.category;
                                    subtitle = 'Untuk muatan di luar kategori utama.';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: InkWell(
                                    onTap: () {
                                      onChanged(opt);
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.accentLime.withValues(alpha: 0.1) : AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? AppColors.accentLime : AppColors.borderSoft,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.accentLime.withValues(alpha: 0.2) : AppColors.background,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              iconData,
                                              color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  opt,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                    color: AppColors.primaryNavy,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  subtitle,
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle, color: AppColors.accentLime, size: 24)
                                          else
                                            const Icon(Icons.chevron_right, color: AppColors.borderSoft, size: 24),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: value == null ? AppColors.borderSoft : AppColors.primaryNavy),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.background,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField({required String label, String? value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: value == null ? AppColors.borderSoft : AppColors.primaryNavy),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.background,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Pilih $label',
                    style: TextStyle(
                      fontSize: 14,
                      color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.location_on_outlined, color: AppColors.primaryNavy, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({required String label, String? value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: value == null ? AppColors.borderSoft : AppColors.primaryNavy),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.background,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Pilih $label',
                    style: TextStyle(
                      fontSize: 14,
                      color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, color: AppColors.primaryNavy, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuatanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          CustomInputField(
            label: 'Estimasi Berat (Opsional)',
            hintText: 'Contoh: 2',
            controller: _beratController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomInputField(
            label: 'Estimasi Volume atau Jumlah (Opsional)',
            hintText: 'Contoh: 5',
            controller: _volumeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomInputField(
            label: 'Catatan Muatan',
            hintText: 'Contoh: Sapi 2 ekor, jagung kering, pasir urug',
            controller: _catatanMuatanController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiWaktuCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          CustomInputField(
            label: 'Jam Penggunaan',
            hintText: 'Pilih jam',
            prefixIcon: Icons.access_time,
            controller: _jamController,
            readOnly: true,
            onTap: _pickTime,
          ),
          const SizedBox(height: 16),
          CustomInputField(
            label: 'Catatan Lokasi',
            hintText: 'Contoh jalan sempit, masuk gang, area sawah',
            controller: _catatanLokasiController,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          CustomInputField(
            label: 'Kebutuhan Khusus (Opsional)',
            hintText: 'Contoh butuh tenaga bongkar muat',
            controller: _kebutuhanKhususController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHargaCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: AppColors.primaryNavy, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Harga akhir ditentukan admin berdasarkan layanan, jarak, jenis muatan, volume, dan kondisi lokasi.',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                    ),
                  )
                : const Text(
                    'Kirim Permintaan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
