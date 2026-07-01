import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/shared/widgets/custom_input_field.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';
import 'package:mobile/features/armada/armada_page.dart';
import 'package:mobile/features/truck_request/truck_request_page.dart';
import 'package:mobile/shared/widgets/app_date_time_picker.dart';
import 'package:mobile/core/utils/date_time_formatter.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class HomeSearchCard extends StatefulWidget {
  const HomeSearchCard({super.key});

  @override
  State<HomeSearchCard> createState() => _HomeSearchCardState();
}

class _HomeSearchCardState extends State<HomeSearchCard> {
  final List<String> tabs = ['Semua', 'Bus', 'Elf', 'Truk'];
  final List<String> armadaTypes = ['Bus', 'Elf', 'Truk'];
  int selectedCategoryIndex = 0;

  final TextEditingController _asalController = TextEditingController();
  final TextEditingController _tujuanController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _armadaController = TextEditingController();
  final TextEditingController _muatanController = TextEditingController();

  String? _asalError;
  String? _tujuanError;
  String? _tanggalError;
  String? _muatanError;

  final List<String> muatanTypes = [
    'Palawija atau Barang',
    'Ternak',
    'Pasir atau Abu',
    'Material',
    'Lainnya'
  ];

  // Location coordinates (will be used for booking API)
  // ignore: unused_field
  double? _asalLat;
  // ignore: unused_field
  double? _asalLng;
  // ignore: unused_field
  double? _tujuanLat;
  // ignore: unused_field
  double? _tujuanLng;

  String _getRouteMode(String muatan) {
    if (muatan == 'Pasir atau Abu' || muatan == 'Material') {
      return 'destination_only';
    }
    return 'two_points';
  }

  String _getOriginLabel(String muatan) {
    if (muatan == 'Ternak') return 'Pilih Lokasi Jemput Ternak';
    if (muatan == 'Palawija atau Barang') return 'Pilih Lokasi Muat';
    return 'Pilih Lokasi Asal';
  }

  String _getOriginTitle(String muatan) {
    if (muatan == 'Ternak') return 'Lokasi Jemput Ternak';
    if (muatan == 'Palawija atau Barang') return 'Lokasi Muat';
    return 'Lokasi Asal';
  }

  Future<void> _pickLocation({required bool isAsal, String? customTitle}) async {
    final title = customTitle ?? (isAsal ? 'Pilih Lokasi Asal' : 'Pilih Lokasi Tujuan');
    final result = await showLocationPickerBottomSheet(context, title: title);
    if (result != null) {
      setState(() {
        if (isAsal) {
          _asalController.text = result.text;
          _asalLat = result.lat;
          _asalLng = result.lng;
          _asalError = null;
        } else {
          _tujuanController.text = result.text;
          _tujuanLat = result.lat;
          _tujuanLng = result.lng;
          _tujuanError = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _asalController.dispose();
    _tujuanController.dispose();
    _tanggalController.dispose();
    _armadaController.dispose();
    _muatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showAppDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formattedDate = DateTimeFormatter.formatIndonesianDate(picked);

      setState(() {
        _tanggalController.text = formattedDate;
        _tanggalError = null;
      });
    }
  }

  void _handleSearch() {
    bool isTruk = selectedCategoryIndex == 3;
    String routeMode = isTruk ? _getRouteMode(_muatanController.text) : 'two_points';
    
    setState(() {
      _tanggalError = _tanggalController.text.isEmpty ? 'Tanggal penggunaan belum dipilih' : null;
      _muatanError = (isTruk && _muatanController.text.isEmpty) ? 'Pilih jenis muatan terlebih dahulu' : null;

      if (isTruk && _muatanController.text.isEmpty) {
        _asalError = null;
        _tujuanError = null;
      } else {
        if (routeMode == 'destination_only') {
          _asalError = null; // Ignore origin for destination_only
          _tujuanError = _tujuanController.text.isEmpty ? 'Lokasi tujuan belum dipilih' : null;
        } else {
          _asalError = _asalController.text.isEmpty ? 'Lokasi asal belum dipilih' : null;
          _tujuanError = _tujuanController.text.isEmpty ? 'Lokasi tujuan belum dipilih' : null;
        }
      }
    });

    if (isTruk && _muatanController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Pilih jenis muatan terlebih dahulu.');
      return;
    }

    if (_tanggalError != null) {
      AppSnackBar.showWarning(context, 'Pilih tanggal penggunaan terlebih dahulu.');
      return;
    }

    if (routeMode == 'destination_only' && _tujuanError != null) {
      AppSnackBar.showWarning(context, 'Pilih lokasi tujuan pengiriman terlebih dahulu.');
      return;
    }

    if (routeMode == 'two_points' && _asalError != null) {
      AppSnackBar.showWarning(context, 'Pilih lokasi asal terlebih dahulu.');
      return;
    }

    if (routeMode == 'two_points' && _tujuanError != null) {
      AppSnackBar.showWarning(context, 'Pilih lokasi tujuan terlebih dahulu.');
      return;
    }

    if (_asalError == null &&
        _tujuanError == null &&
        _tanggalError == null &&
        _muatanError == null) {
      
      final origin = routeMode == 'destination_only' ? 'Ditentukan Admin' : _asalController.text;
      final destination = _tujuanController.text;
      final date = _tanggalController.text;
      final armadaType = _armadaController.text;
      final muatan = _muatanController.text;

      if (armadaType == 'Bus' || armadaType == 'Elf' || armadaType.isEmpty) {
        String fleetTypeFilter = 'all_passenger';
        if (armadaType == 'Bus') fleetTypeFilter = 'Bus';
        if (armadaType == 'Elf') fleetTypeFilter = 'Elf';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArmadaPage(
              source: 'home_availability',
              fleetType: fleetTypeFilter,
              initialCategory: armadaType.isEmpty ? 'Semua' : armadaType,
              origin: origin,
              destination: destination,
              date: date,
            ),
          ),
        );
      } else if (armadaType == 'Truk') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TruckRequestPage(
              source: 'home_truck_request',
              origin: origin,
              destination: destination,
              originLat: _asalLat,
              originLng: _asalLng,
              destinationLat: _tujuanLat,
              destinationLng: _tujuanLng,
              date: date,
              initialMuatan: muatan,
              routeMode: routeMode,
            ),
          ),
        );
      }
    }
  }

  void _handleCategoryTap(int index) {
    setState(() {
      selectedCategoryIndex = index;
      if (index == 0) {
        _armadaController.text = ''; // Clear when switching to Semua
      } else {
        _armadaController.text = tabs[index];
      }
      _muatanError = null;
      _asalError = null;
      _tujuanError = null;
      _tanggalError = null;
    });
  }

  String _getButtonLabel() {
    final armada = _armadaController.text;
    if (armada == 'Bus') return 'Cek Ketersediaan Bus';
    if (armada == 'Elf') return 'Cek Ketersediaan Elf';
    if (armada == 'Truk') return 'Ajukan Permintaan Truk';
    return 'Cari Armada';
  }

  Widget _buildTrukRouteSection() {
    if (_muatanController.text.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Pilih jenis muatan terlebih dahulu',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    String mode = _getRouteMode(_muatanController.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text('Rute Pengangkutan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          ),
          
          if (mode == 'two_points') ...[
            _buildRouteLocationItem(
              title: _getOriginTitle(_muatanController.text),
              value: _asalController.text.isEmpty ? _getOriginLabel(_muatanController.text) : _asalController.text,
              icon: Icons.my_location,
              iconColor: AppColors.primaryNavy,
              onTap: () => _pickLocation(isAsal: true, customTitle: 'Pilih ${_getOriginTitle(_muatanController.text)}'),
              isPlaceholder: _asalController.text.isEmpty,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Container(
                width: 2,
                height: 16,
                color: AppColors.borderSoft,
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Expanded(child: Text('Lokasi asal pengambilan akan ditentukan oleh admin. Silakan isi lokasi tujuan pengiriman.', style: TextStyle(fontSize: 11, color: AppColors.textPrimary))),
                  ],
                ),
              ),
            ),
          ],

          _buildRouteLocationItem(
            title: mode == 'destination_only' ? 'Lokasi Tujuan Pengiriman' : 'Lokasi Tujuan',
            value: _tujuanController.text.isEmpty ? 'Pilih Lokasi Tujuan' : _tujuanController.text,
            icon: Icons.location_on_outlined,
            iconColor: Colors.orange,
            onTap: () => _pickLocation(isAsal: false, customTitle: mode == 'destination_only' ? 'Pilih Lokasi Tujuan Pengiriman' : 'Pilih Lokasi Tujuan'),
            isPlaceholder: _tujuanController.text.isEmpty,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRouteLocationItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isPlaceholder,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600, 
                      color: isPlaceholder ? AppColors.textMuted : AppColors.textPrimary
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('Ubah', style: TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppColors.borderSoft.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category selector tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = index == selectedCategoryIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _handleCategoryTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentLime : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Fields
          if (selectedCategoryIndex == 3) ...[
            CustomInputField(
              label: 'Jenis Muatan',
              hintText: 'Pilih Jenis Muatan',
              prefixIcon: Icons.category_outlined,
              controller: _muatanController,
              errorText: _muatanError,
              readOnly: true,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Pilih Jenis Muatan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          ...muatanTypes.map((muatan) => ListTile(
                                title: Text(muatan),
                                onTap: () {
                                  setState(() {
                                    // Reset origin route if switching modes
                                    if (_muatanController.text != muatan) {
                                      String oldMode = _getRouteMode(_muatanController.text);
                                      String newMode = _getRouteMode(muatan);
                                      if (oldMode != newMode) {
                                        _asalController.clear();
                                      }
                                    }
                                    _muatanController.text = muatan;
                                    _muatanError = null;
                                  });
                                  Navigator.pop(context);
                                },
                              )),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            _buildTrukRouteSection(),
          ] else ...[
            CustomInputField(
              label: 'Lokasi Asal',
              hintText: 'Pilih Lokasi Asal',
              prefixIcon: Icons.my_location,
              controller: _asalController,
              errorText: _asalError,
              readOnly: true,
              onTap: () => _pickLocation(isAsal: true),
            ),
            const SizedBox(height: 12),
            CustomInputField(
              label: 'Lokasi Tujuan',
              hintText: 'Pilih Lokasi Tujuan',
              prefixIcon: Icons.location_on_outlined,
              controller: _tujuanController,
              errorText: _tujuanError,
              readOnly: true,
              onTap: () => _pickLocation(isAsal: false),
            ),
            const SizedBox(height: 12),
          ],
          
          CustomInputField(
            label: 'Tanggal Penggunaan',
            hintText: 'Pilih Tanggal',
            prefixIcon: Icons.calendar_today_outlined,
            controller: _tanggalController,
            errorText: _tanggalError,
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 20),

          // Search CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentLime,
                foregroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedCategoryIndex == 3 ? Icons.local_shipping : Icons.search,
                    size: 20,
                    color: AppColors.primaryNavy,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getButtonLabel(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
