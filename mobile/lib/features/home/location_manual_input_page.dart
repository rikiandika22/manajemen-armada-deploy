import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/widgets/location_picker_bottom_sheet.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class LocationManualInputPage extends StatefulWidget {
  final String title;

  const LocationManualInputPage({super.key, required this.title});

  @override
  State<LocationManualInputPage> createState() => _LocationManualInputPageState();
}

class _LocationManualInputPageState extends State<LocationManualInputPage> {
  final _searchController = TextEditingController();
  String _query = '';

  // Dummy suggestion data
  final List<Map<String, dynamic>> _allSuggestions = const [
    {'name': 'Grobogan, Jawa Tengah', 'icon': Icons.history, 'lat': -7.0193, 'lng': 110.8982},
    {'name': 'Semarang, Jawa Tengah', 'icon': Icons.location_on_outlined, 'lat': -6.9666, 'lng': 110.4196},
    {'name': 'Yogyakarta', 'icon': Icons.location_on_outlined, 'lat': -7.7956, 'lng': 110.3695},
    {'name': 'Solo, Jawa Tengah', 'icon': Icons.location_on_outlined, 'lat': -7.5755, 'lng': 110.8243},
    {'name': 'Klaten, Jawa Tengah', 'icon': Icons.location_on_outlined, 'lat': -7.7056, 'lng': 110.6038},
    {'name': 'Purwodadi, Grobogan', 'icon': Icons.location_on_outlined, 'lat': -7.0862, 'lng': 110.9158},
    {'name': 'Magelang, Jawa Tengah', 'icon': Icons.location_on_outlined, 'lat': -7.4797, 'lng': 110.2177},
    {'name': 'Salatiga, Jawa Tengah', 'icon': Icons.location_on_outlined, 'lat': -7.3305, 'lng': 110.5084},
  ];

  List<Map<String, dynamic>> get _filteredSuggestions {
    if (_query.isEmpty) return _allSuggestions.take(3).toList();
    return _allSuggestions
        .where((s) => s['name'].toString().toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    Navigator.pop(
      context,
      LocationResult(
        text: suggestion['name'],
        lat: suggestion['lat'],
        lng: suggestion['lng'],
      ),
    );
  }

  void _saveManualLocation() {
    if (_searchController.text.trim().isEmpty) {
      AppSnackBar.showWarning(context, 'Masukkan nama lokasi terlebih dahulu');
      return;
    }
    Navigator.pop(
      context,
      LocationResult(text: _searchController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input Lokasi Manual',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              style: const TextStyle(fontSize: 14, color: AppColors.primaryNavy),
              decoration: InputDecoration(
                hintText: 'Contoh: Grobogan, Semarang, Klaten',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                suffixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 22),
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
          ),

          // Suggestions list
          Expanded(
            child: _filteredSuggestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Lokasi tidak ditemukan',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _filteredSuggestions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F5),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.5)),
                            ),
                            child: Icon(suggestion['icon'], color: AppColors.textSecondary, size: 20),
                          ),
                          title: Text(
                            suggestion['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                          onTap: () => _selectSuggestion(suggestion),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveManualLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLime,
                    foregroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Lokasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
