import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class LocationMapPickerPage extends StatefulWidget {
  final String title;

  const LocationMapPickerPage({super.key, required this.title});

  @override
  State<LocationMapPickerPage> createState() => _LocationMapPickerPageState();
}

class _LocationMapPickerPageState extends State<LocationMapPickerPage> {
  final MapController _mapController = MapController();
  Timer? _debounceTimer;
  
  String _address = 'Mengambil alamat...';
  double _lat = -7.0193; // Default to Grobogan
  double _lng = 110.8982;
  bool _isMoving = false;
  bool _isLocating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    setState(() => _isLocating = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Aktifkan layanan lokasi untuk menggunakan lokasi saat ini.');
      _finishLocating();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _finishLocating();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Izin lokasi ditolak permanen. Anda dapat memasukkan manual.');
      _finishLocating();
      return;
    }

    await _fetchAndMoveToCurrentLocation();
  }

  Future<void> _fetchAndMoveToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      
      _lat = position.latitude;
      _lng = position.longitude;
      
      if (_mapReady) {
        _mapController.move(LatLng(_lat, _lng), 15.0);
      }
      _finishLocating();
    } catch (e) {
      _showSnackBar('Lokasi saat ini belum bisa didapatkan.');
      _finishLocating();
    }
  }

  void _finishLocating() {
    if (!mounted) return;
    setState(() => _isLocating = false);
    _onCameraIdle(); // Fetch address for whatever lat/lng we have
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    AppSnackBar.showInfo(context, message);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _lat = camera.center.latitude;
    _lng = camera.center.longitude;
    
    if (hasGesture) {
      if (!_isMoving) {
        setState(() {
          _isMoving = true;
          _address = 'Mengambil alamat...';
        });
      }
      
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 800), _onCameraIdle);
    }
  }

  Future<void> _onCameraIdle() async {
    if (!mounted) return;
    setState(() {
      _isMoving = false;
      _address = 'Mengambil alamat...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lng);
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
        
        setState(() {
          _address = parts.isNotEmpty ? parts.join(', ') : 'Lokasi dipilih dari maps';
        });
      } else {
        setState(() {
          _address = 'Lokasi dipilih dari maps';
        });
      }
    } catch (e) {
      debugPrint('[MapPicker] Reverse geocoding failed: $e');
      if (mounted) {
        setState(() {
          _address = 'Lokasi dipilih dari maps';
        });
      }
    }
  }

  void _confirmLocation() {
    if (_lat == 0.0 && _lng == 0.0) {
      _showSnackBar('Titik lokasi belum valid. Coba geser peta atau gunakan lokasi saat ini.');
      return;
    }
    if (_address.isEmpty || _address == 'Mengambil alamat...' || _address == 'Lokasi dipilih dari maps') {
      _showSnackBar('Alamat belum ditemukan, geser peta sedikit lalu coba lagi.');
      return;
    }

    debugPrint('[MapPicker] Confirm location: $_lat, $_lng, $_address');
    Navigator.pop(
      context,
      LocationResult(text: _address, lat: _lat, lng: _lng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // OpenStreetMap
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_lat, _lng),
                initialZoom: 15.0,
                onPositionChanged: _onPositionChanged,
                onMapReady: () {
                  _mapReady = true;
                  if (!_isLocating) {
                    _mapController.move(LatLng(_lat, _lng), 15.0);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mobile',
                ),
              ],
            ),
          ),

          // AppBar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back, color: AppColors.primaryNavy, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Location',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                ),
                // Pin shadow
                Container(
                  width: 12,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // My Location Button
          Positioned(
            right: 16,
            bottom: 270,
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              mini: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primaryNavy,
              onPressed: () async {
                bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  _showSnackBar('Aktifkan layanan lokasi terlebih dahulu.');
                  return;
                }
                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                   _showSnackBar('Izin lokasi belum diberikan.');
                   return;
                }
                _fetchAndMoveToCurrentLocation();
              },
              child: _isLocating 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentLime))
                  : const Icon(Icons.my_location, size: 20),
            ),
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Address row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: _isLocating 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy))
                                : const Icon(Icons.map_outlined, color: AppColors.primaryNavy, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _address,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Geser peta untuk menyesuaikan titik lokasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirmLocation,
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text(
                            'Gunakan Lokasi Ini',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentLime,
                            foregroundColor: AppColors.primaryNavy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

