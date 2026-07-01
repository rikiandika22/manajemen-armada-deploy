import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';
import 'package:mobile/shared/widgets/app_date_time_picker.dart';
import 'package:mobile/core/utils/date_time_formatter.dart';

class TruckGoodsForm extends StatefulWidget {
  final VoidCallback onChanged;
  final String? initialOrigin;
  final String? initialDestination;
  final String? initialDate;

  const TruckGoodsForm({
    super.key,
    required this.onChanged,
    this.initialOrigin,
    this.initialDestination,
    this.initialDate,
  });

  @override
  State<TruckGoodsForm> createState() => TruckGoodsFormState();
}

class TruckGoodsFormState extends State<TruckGoodsForm> {
  LocationResult? _lokasiMuat;
  LocationResult? _lokasiBongkar;
  DateTime? _tanggal;
  TimeOfDay? _jam;
  
  final _muatanController = TextEditingController();
  final _beratController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _bantuanBongkarMuat;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrigin != null) {
      _lokasiMuat = LocationResult(text: widget.initialOrigin!, lat: 0, lng: 0);
    }
    if (widget.initialDestination != null) {
      _lokasiBongkar = LocationResult(text: widget.initialDestination!, lat: 0, lng: 0);
    }
    if (widget.initialDate != null) {
      _tanggal = _parseDate(widget.initialDate);
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _muatanController.dispose();
    _beratController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged();
  }

  bool get isValid {
    return _lokasiMuat != null &&
           _lokasiBongkar != null &&
           _tanggal != null &&
           _jam != null &&
           _muatanController.text.trim().isNotEmpty &&
           _beratController.text.trim().isNotEmpty &&
           _bantuanBongkarMuat != null;
  }

  Map<String, dynamic> get data {
    return {
      'lokasiMuat': _lokasiMuat,
      'lokasiBongkar': _lokasiBongkar,
      'tanggal': _tanggal,
      'jam': _jam,
      'muatan': _muatanController.text.trim(),
      'berat': _beratController.text.trim(),
      'bantuanBongkarMuat': _bantuanBongkarMuat,
      'catatan': _catatanController.text.trim(),
    };
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _tanggal = picked;
      });
      _notifyChanged();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _jam ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _jam = picked;
      });
      _notifyChanged();
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
            'Detail Pengangkutan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 16),
          _buildLocationField(
            label: 'Lokasi Muat',
            value: _lokasiMuat?.text,
            onTap: () async {
              final res = await showLocationPickerBottomSheet(context, title: 'Lokasi Muat');
              if (res != null) {
                setState(() => _lokasiMuat = res);
                _notifyChanged();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildLocationField(
            label: 'Lokasi Bongkar',
            value: _lokasiBongkar?.text,
            onTap: () async {
              final res = await showLocationPickerBottomSheet(context, title: 'Lokasi Bongkar');
              if (res != null) {
                setState(() => _lokasiBongkar = res);
                _notifyChanged();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeField(
                  label: 'Tanggal',
                  value: _tanggal != null ? _formatDate(_tanggal!) : null,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeField(
                  label: 'Jam',
                  value: _jam != null ? _formatTime(_jam!) : null,
                  icon: Icons.access_time,
                  onTap: () => _selectTime(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Jenis Muatan',
            controller: _muatanController,
            hint: 'Contoh: Jagung kering, gabah, barang dagangan',
            onChanged: (_) => _notifyChanged(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Estimasi Berat atau Volume',
            controller: _beratController,
            hint: 'Contoh: 3 Ton, 100 karung',
            onChanged: (_) => _notifyChanged(),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Bantuan Bongkar Muat',
            value: _bantuanBongkarMuat,
            items: const ['Ya', 'Tidak', 'Belum pasti'],
            onChanged: (val) {
              setState(() => _bantuanBongkarMuat = val);
              _notifyChanged();
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Catatan Tambahan (Opsional)',
            controller: _catatanController,
            hint: 'Contoh: Hati-hati barang mudah pecah',
            maxLines: 3,
            onChanged: (_) => _notifyChanged(),
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

  Widget _buildDateTimeField({required String label, String? value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: value == null ? AppColors.borderSoft : AppColors.primaryNavy),
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
                Icon(icon, color: AppColors.primaryNavy, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
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
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: value == null ? AppColors.borderSoft : AppColors.primaryNavy),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text('Pilih salah satu', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryNavy),
              items: items.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
