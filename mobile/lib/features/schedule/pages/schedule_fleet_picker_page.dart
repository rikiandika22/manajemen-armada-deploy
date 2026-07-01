import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/services/fleet_service.dart';
import 'package:mobile/features/fleet/models/fleet_model.dart';
import 'package:mobile/features/armada/armada_schedule_page.dart';
import 'package:mobile/features/armada/truck_schedule_page.dart';

class ScheduleFleetPickerPage extends StatefulWidget {
  const ScheduleFleetPickerPage({super.key});

  @override
  State<ScheduleFleetPickerPage> createState() => _ScheduleFleetPickerPageState();
}

class _ScheduleFleetPickerPageState extends State<ScheduleFleetPickerPage> {
  final FleetService _fleetService = FleetService();
  bool _isLoading = true;
  String? _error;
  
  List<FleetModel> _fleets = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fleets = await _fleetService.getFleets();
      setState(() {
        _fleets = fleets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _navigateToSchedule(FleetModel fleet) {
    if (fleet.fleetType.toLowerCase().contains('truk') || fleet.fleetType.toLowerCase().contains('truck')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TruckSchedulePage(
            mode: 'view_only',
            source: 'schedule_check',
            fleetGroup: 'single_unit',
            fleetId: fleet.id,
            fleetCode: fleet.fleetCode,
            fleetName: fleet.fleetName,
            capacity: fleet.capacity,
            priceText: fleet.priceText,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArmadaSchedulePage(
            mode: 'view_only',
            source: 'schedule_check',
            fleetId: fleet.id,
            fleetName: fleet.fleetName,
            fleetPlate: fleet.licensePlate,
            fleetType: fleet.fleetType,
            capacity: fleet.capacity,
            priceText: fleet.priceText,
          ),
        ),
      );
    }
  }
  
  void _navigateToAllTrucks() {
    // If user selects "Semua Unit Truk", we open TruckSchedulePage without a specific fleet ID, 
    // it handles fetching the fleetGroup all_trucks
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TruckSchedulePage(
          mode: 'view_only',
          source: 'schedule_check',
          fleetGroup: 'all_trucks',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Armada',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_fleets.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada armada yang tersedia untuk dicek.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final passengerFleets = _fleets.where((f) => !f.fleetType.toLowerCase().contains('truk') && !f.fleetType.toLowerCase().contains('truck')).toList();
    final truckFleets = _fleets.where((f) => f.fleetType.toLowerCase().contains('truk') || f.fleetType.toLowerCase().contains('truck')).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih armada yang ingin Anda cek ketersediaannya.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          if (passengerFleets.isNotEmpty) ...[
            const Text(
              'Armada Penumpang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            ...passengerFleets.map((fleet) => _buildFleetCard(fleet)).toList(),
            const SizedBox(height: 24),
          ],
          
          if (truckFleets.isNotEmpty) ...[
            const Text(
              'Armada Truk Logistik',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            _buildAllTrucksCard(),
            ...truckFleets.map((fleet) => _buildFleetCard(fleet)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildFleetCard(FleetModel fleet) {
    IconData iconData = Icons.directions_bus;
    if (fleet.fleetType.toLowerCase().contains('elf')) {
      iconData = Icons.airport_shuttle;
    } else if (fleet.fleetType.toLowerCase().contains('truk') || fleet.fleetType.toLowerCase().contains('truck')) {
      iconData = Icons.local_shipping;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderSoft.withValues(alpha: 0.5)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _navigateToSchedule(fleet),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F3F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: AppColors.primaryNavy),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fleet.fleetCode.isNotEmpty && (fleet.fleetType.toLowerCase().contains('truk') || fleet.fleetType.toLowerCase().contains('truck')) 
                          ? '${fleet.fleetCode} - ${fleet.fleetName}' 
                          : fleet.fleetName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fleet.fleetType} • ${fleet.capacity}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cek jadwal unit ini',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentLime,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAllTrucksCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderSoft.withValues(alpha: 0.5)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: _navigateToAllTrucks,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping, color: AppColors.accentLime),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semua Unit Truk',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Truk Logistik',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cek jadwal semua unit truk',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentLime,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
