import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';

/// Handles the "Gunakan Lokasi Saya" flow:
/// 1. Check if location services are enabled
/// 2. Check/request permission
/// 3. Get current position
/// Returns a [LocationResult] or null.
Future<LocationResult?> handleUseMyLocation(BuildContext context) async {
  // Show bottom-sheet-style loading/permission dialog
  return showModalBottomSheet<LocationResult>(
    context: context,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _MyLocationSheet(),
  );
}

class _MyLocationSheet extends StatefulWidget {
  const _MyLocationSheet();

  @override
  State<_MyLocationSheet> createState() => _MyLocationSheetState();
}

enum _LocationStep { checkingPermission, needsPermission, fetching, error }

class _MyLocationSheetState extends State<_MyLocationSheet> {
  _LocationStep _step = _LocationStep.checkingPermission;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _checkAndFetch();
  }

  Future<void> _checkAndFetch() async {
    setState(() => _step = _LocationStep.checkingPermission);

    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _step = _LocationStep.error;
        _errorMsg = 'Layanan lokasi dimatikan. Aktifkan GPS terlebih dahulu.';
      });
      return;
    }

    // 2. Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      setState(() => _step = _LocationStep.needsPermission);
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _step = _LocationStep.error;
        _errorMsg = 'Izin lokasi ditolak secara permanen. Buka Pengaturan untuk mengaktifkan.';
      });
      return;
    }

    // Permission granted → fetch location
    _fetchLocation();
  }

  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      setState(() {
        _step = _LocationStep.error;
        _errorMsg = 'Izin lokasi ditolak.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _step = _LocationStep.error;
        _errorMsg = 'Izin lokasi ditolak secara permanen. Buka Pengaturan untuk mengaktifkan.';
      });
      return;
    }

    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _step = _LocationStep.fetching);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      String addressText = 'Lokasi Anda saat ini';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final street = place.street ?? '';
          final locality = place.locality ?? '';
          final subLocality = place.subLocality ?? '';
          final adminArea = place.administrativeArea ?? '';
          
          List<String> parts = [];
          if (street.isNotEmpty) parts.add(street);
          if (subLocality.isNotEmpty && subLocality != street) parts.add(subLocality);
          if (locality.isNotEmpty) parts.add(locality);
          if (adminArea.isNotEmpty) parts.add(adminArea);
          
          if (parts.isNotEmpty) {
            addressText = parts.join(', ');
          }
        }
      } catch (e) {
        debugPrint('[Location] Reverse geocoding failed: $e');
      }

      if (!mounted) return;

      debugPrint('[Location] Fetch success: ${position.latitude}, ${position.longitude}, $addressText');

      Navigator.pop(
        context,
        LocationResult(
          text: addressText,
          lat: position.latitude,
          lng: position.longitude,
        ),
      );
    } catch (e) {
      debugPrint('[Location] Error fetching position: $e');
      if (!mounted) return;
      setState(() {
        _step = _LocationStep.error;
        _errorMsg = 'Gagal mengambil lokasi. Pastikan GPS aktif dan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _LocationStep.checkingPermission:
      case _LocationStep.fetching:
        return _buildFetchingState();
      case _LocationStep.needsPermission:
        return _buildPermissionState();
      case _LocationStep.error:
        return _buildErrorState();
    }
  }

  Widget _buildFetchingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.accentLime.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.my_location, color: AppColors.primaryNavy, size: 30),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mengambil lokasi Anda...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: AppColors.accentLime,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPermissionState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.location_disabled, color: Colors.red.shade400, size: 30),
        ),
        const SizedBox(height: 20),
        const Text(
          'Izin Lokasi Diperlukan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aktifkan izin lokasi agar aplikasi dapat mengambil posisi Anda saat ini.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text(
              'Aktifkan Izin Lokasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: Colors.red.shade400, size: 30),
        ),
        const SizedBox(height: 20),
        const Text(
          'Gagal Mendapatkan Lokasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMsg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: AppColors.primaryNavy),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _checkAndFetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLime,
                  foregroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
