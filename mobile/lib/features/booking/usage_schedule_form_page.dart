import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';
import 'package:mobile/features/booking/booking_page.dart';
import 'package:mobile/shared/widgets/app_date_time_picker.dart';
import 'package:mobile/core/utils/date_time_formatter.dart';

class UsageScheduleFormPage extends StatefulWidget {
  final String armadaName;
  final String armadaType;
  final String capacity;
  final String price;
  final String? initialDate;
  final String? initialOrigin;
  final double? initialOriginLat;
  final double? initialOriginLng;
  final String? initialDestination;
  final double? initialDestinationLat;
  final double? initialDestinationLng;

  const UsageScheduleFormPage({
    super.key,
    required this.armadaName,
    required this.armadaType,
    required this.capacity,
    required this.price,
    this.initialDate,
    this.initialOrigin,
    this.initialOriginLat,
    this.initialOriginLng,
    this.initialDestination,
    this.initialDestinationLat,
    this.initialDestinationLng,
  });

  @override
  State<UsageScheduleFormPage> createState() => _UsageScheduleFormPageState();
}

class _UsageScheduleFormPageState extends State<UsageScheduleFormPage> {
  LocationResult? _lokasiJemput;
  LocationResult? _lokasiTujuan;
  
  DateTime? _tanggalBerangkat;
  TimeOfDay? _jamBerangkat;
  DateTime? _tanggalSelesai;
  TimeOfDay? _jamSelesai;
  
  final TextEditingController _catatanController = TextEditingController();

  String? _dateError;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(widget.initialDate!);
        _tanggalBerangkat = parsed;
        _tanggalSelesai = parsed;
      } catch (e) {
        // ignore
      }
    }
    
    if (widget.initialOrigin != null && widget.initialOrigin!.isNotEmpty) {
      _lokasiJemput = LocationResult(
        text: widget.initialOrigin!,
        lat: widget.initialOriginLat,
        lng: widget.initialOriginLng,
      );
    }
    
    if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
      _lokasiTujuan = LocationResult(
        text: widget.initialDestination!,
        lat: widget.initialDestinationLat,
        lng: widget.initialDestinationLng,
      );
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_lokasiJemput == null || _lokasiTujuan == null) return false;
    if (_tanggalBerangkat == null || _jamBerangkat == null) return false;
    if (_tanggalSelesai == null || _jamSelesai == null) return false;
    if (_dateError != null) return false;
    return true;
  }

  void _validateDates() {
    if (_tanggalBerangkat != null && _jamBerangkat != null && 
        _tanggalSelesai != null && _jamSelesai != null) {
      final start = DateTime(
        _tanggalBerangkat!.year, _tanggalBerangkat!.month, _tanggalBerangkat!.day,
        _jamBerangkat!.hour, _jamBerangkat!.minute,
      );
      final end = DateTime(
        _tanggalSelesai!.year, _tanggalSelesai!.month, _tanggalSelesai!.day,
        _jamSelesai!.hour, _jamSelesai!.minute,
      );

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        setState(() {
          _dateError = 'Perkiraan selesai tidak boleh lebih awal dari waktu berangkat.';
        });
      } else {
        setState(() {
          _dateError = null;
        });
      }
    } else {
      setState(() {
        _dateError = null;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart 
        ? (_tanggalBerangkat ?? DateTime.now()) 
        : (_tanggalSelesai ?? _tanggalBerangkat ?? DateTime.now());
        
    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _tanggalBerangkat = picked;
          if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(picked)) {
            _tanggalSelesai = picked;
          }
        } else {
          _tanggalSelesai = picked;
        }
      });
      _validateDates();
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = isStart 
        ? (_jamBerangkat ?? TimeOfDay.now()) 
        : (_jamSelesai ?? _jamBerangkat ?? TimeOfDay.now());
        
    final picked = await showAppTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _jamBerangkat = picked;
        } else {
          _jamSelesai = picked;
        }
      });
      _validateDates();
    }
  }

  String _formatDate(DateTime date) {
    return DateTimeFormatter.formatIndonesianDate(date);
  }

  String _formatTime(TimeOfDay time) {
    return DateTimeFormatter.formatIndonesianTime(time);
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
          'Jadwal Pemakaian',
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFleetSummary(),
                      const SizedBox(height: 24),
                      _buildLocationCard(),
                      const SizedBox(height: 24),
                      _buildTimeCard(),
                      const SizedBox(height: 24),
                      _buildNotesCard(),
                      if (_isValid) ...[
                        const SizedBox(height: 24),
                        _buildSummaryMiniCard(),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildFleetSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
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
            child: const Icon(Icons.directions_bus, color: AppColors.surface, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.armadaName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.armadaType} • ${widget.capacity}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.price} / hari',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentLime),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi Perjalanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 16),
          _buildLocationField(
            label: 'Lokasi Jemput',
            value: _lokasiJemput?.text,
            onTap: () async {
              final res = await showLocationPickerBottomSheet(context, title: 'Lokasi Jemput');
              if (res != null) {
                setState(() => _lokasiJemput = res);
                _validateDates();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildLocationField(
            label: 'Lokasi Tujuan',
            value: _lokasiTujuan?.text,
            onTap: () async {
              final res = await showLocationPickerBottomSheet(context, title: 'Lokasi Tujuan');
              if (res != null) {
                setState(() => _lokasiTujuan = res);
                _validateDates();
              }
            },
          ),
        ],
      ),
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

  Widget _buildTimeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Pemakaian',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Perkiraan selesai digunakan untuk mengecek ketersediaan armada agar tidak bertabrakan dengan jadwal lain.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeField(
                  label: 'Tanggal Berangkat',
                  value: _tanggalBerangkat != null ? _formatDate(_tanggalBerangkat!) : null,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeField(
                  label: 'Jam Berangkat',
                  value: _jamBerangkat != null ? _formatTime(_jamBerangkat!) : null,
                  icon: Icons.access_time,
                  onTap: () => _selectTime(context, true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeField(
                  label: 'Perkiraan Tanggal Selesai',
                  value: _tanggalSelesai != null ? _formatDate(_tanggalSelesai!) : null,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _selectDate(context, false),
                  hasError: _dateError != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeField(
                  label: 'Perkiraan Jam Selesai',
                  value: _jamSelesai != null ? _formatTime(_jamSelesai!) : null,
                  icon: Icons.access_time,
                  onTap: () => _selectTime(context, false),
                  hasError: _dateError != null,
                ),
              ),
            ],
          ),
          if (_dateError != null) ...[
            const SizedBox(height: 8),
            Text(
              _dateError!,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: hasError ? Colors.red : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError
                    ? Colors.red.withValues(alpha: 0.5)
                    : (value == null ? AppColors.borderSoft : AppColors.primaryNavy),
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.background,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(icon, color: hasError ? Colors.red : AppColors.primaryNavy, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Perjalanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: Rombongan keluarga, jemput di depan rumah, membawa barang bawaan',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryNavy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard() {
    final tglBerangkat = _formatDate(_tanggalBerangkat!);
    final jamB = _formatTime(_jamBerangkat!);
    final tglSelesai = _formatDate(_tanggalSelesai!);
    final jamS = _formatTime(_jamSelesai!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.accentLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_lokasiJemput!.text} ke ${_lokasiTujuan!.text}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai: $tglBerangkat, $jamB WIB\nSelesai: $tglSelesai, $jamS WIB',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isValid ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingPage(
                  bookingData: {
                    'armadaName': widget.armadaName,
                    'armadaType': widget.armadaType,
                    'capacity': widget.capacity,
                    'price': widget.price,
                    'lokasiJemputText': _lokasiJemput!.text,
                    'lokasiJemputLat': _lokasiJemput!.lat,
                    'lokasiJemputLng': _lokasiJemput!.lng,
                    'lokasiTujuanText': _lokasiTujuan!.text,
                    'lokasiTujuanLat': _lokasiTujuan!.lat,
                    'lokasiTujuanLng': _lokasiTujuan!.lng,
                    'tanggalBerangkat': _formatDate(_tanggalBerangkat!),
                    'jamBerangkat': _formatTime(_jamBerangkat!),
                    'tanggalSelesai': _formatDate(_tanggalSelesai!),
                    'jamSelesai': _formatTime(_jamSelesai!),
                    'tanggalBerangkatRaw': DateTimeFormatter.formatBackendDate(_tanggalBerangkat!),
                    'jamBerangkatRaw': DateTimeFormatter.formatBackendTime(_jamBerangkat!),
                    'tanggalSelesaiRaw': DateTimeFormatter.formatBackendDate(_tanggalSelesai!),
                    'jamSelesaiRaw': DateTimeFormatter.formatBackendTime(_jamSelesai!),
                    'catatanPerjalanan': _catatanController.text,
                  },
                ),
              ),
            );
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isValid ? AppColors.accentLime : AppColors.borderSoft,
            foregroundColor: _isValid ? AppColors.primaryNavy : AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Lanjut ke Booking',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
