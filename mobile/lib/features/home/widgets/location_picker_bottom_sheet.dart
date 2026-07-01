import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/services/location_search_service.dart';
import 'package:mobile/features/home/location_map_picker_page.dart';
import 'package:mobile/features/home/widgets/location_permission_handler.dart';

/// Result from the location picker flow.
class LocationResult {
  final String text;      // Label pendek
  final String? address;  // Alamat panjang
  final double? lat;
  final double? lng;
  final String? placeId;

  const LocationResult({
    required this.text,
    this.address,
    this.lat,
    this.lng,
    this.placeId,
  });
}

/// Shows the location picker bottom sheet and returns the result.
Future<LocationResult?> showLocationPickerBottomSheet(
  BuildContext context, {
  required String title,
}) async {
  return showModalBottomSheet<LocationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LocationPickerSheet(title: title),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  final String title;

  const _LocationPickerSheet({required this.title});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _searchController = TextEditingController();
  final _searchService = LocationSearchService();
  Timer? _debounce;
  
  List<LocationResult> _results = [];
  bool _isLoading = false;
  String _error = '';
  bool _showInstruction = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() {
        _results = [];
        _showInstruction = true;
        _error = '';
      });
      return;
    }

    setState(() {
      _showInstruction = false;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await _searchService.searchLocation(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal mencari lokasi. Coba lagi.';
          _isLoading = false;
        });
      }
    }
  }

  void _selectResult(LocationResult result) {
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
        minHeight: 400,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (_isSearching)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.arrow_back, color: AppColors.primaryNavy),
                            ),
                          ),
                        Text(
                          _isSearching ? 'Cari Lokasi' : widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.borderSoft.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!_isSearching)
                _buildOptionsList()
              else ...[
                // Search Input
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14, color: AppColors.primaryNavy),
                  decoration: InputDecoration(
                    hintText: 'Cari lokasi (contoh: Semarang)',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 20),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F3F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accentLime, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildResultsArea(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOptionItem(
          icon: Icons.search,
          title: 'Cari Lokasi',
          subtitle: 'Cari lokasi dengan mengetik nama tempat atau alamat',
          onTap: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildOptionItem(
          icon: Icons.map_outlined,
          title: 'Pilih Titik dari Maps',
          subtitle: 'Tentukan lokasi akurat lewat peta',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationMapPickerPage(title: widget.title),
              ),
            );
            if (result != null && mounted) {
              Navigator.pop(context, result);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildOptionItem(
          icon: Icons.my_location,
          title: 'Gunakan Lokasi Saat Ini',
          subtitle: 'Gunakan GPS untuk menemukan lokasi Anda',
          onTap: () async {
            final result = await handleUseMyLocation(context);
            if (result != null && mounted) {
              Navigator.pop(context, result);
            }
          },
        ),
      ],
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
              child: Icon(icon, color: AppColors.primaryNavy),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryNavy),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_showInstruction) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              'Ketik minimal 3 karakter untuk mencari lokasi.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'Lokasi tidak ditemukan.\nCoba gunakan kata kunci lain.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Fallback manual input if user really can't find it
            OutlinedButton.icon(
              onPressed: () {
                final manualResult = LocationResult(
                  text: _searchController.text.trim(),
                  address: _searchController.text.trim(),
                );
                _selectResult(manualResult);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Gunakan Teks Ini'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: AppColors.primaryNavy),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.borderSoft.withValues(alpha: 0.5), height: 1),
      itemBuilder: (context, index) {
        final result = _results[index];
        return InkWell(
          onTap: () => _selectResult(result),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.primaryNavy, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result.address != null && result.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          result.address!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
