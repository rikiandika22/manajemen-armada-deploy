import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/features/auth/login_page.dart';
import 'package:mobile/features/truck_request/truck_request_page.dart';
import 'package:mobile/core/services/fleet_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class TruckSchedulePage extends StatefulWidget {
  final String mode;
  final String source;
  final String fleetGroup;
  final int? fleetId;
  final String? fleetCode;
  final String? fleetName;
  final String? capacity;
  final String? priceText;

  const TruckSchedulePage({
    super.key,
    this.mode = 'request_enabled',
    this.source = 'fleet_detail',
    this.fleetGroup = 'single_unit',
    this.fleetId,
    this.fleetCode,
    this.fleetName,
    this.capacity,
    this.priceText,
  });

  @override
  State<TruckSchedulePage> createState() => _TruckSchedulePageState();
}

class _TruckSchedulePageState extends State<TruckSchedulePage> {
  int _selectedDay = DateTime.now().day;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  bool _isLoading = false;
  String? _error;
  
  Map<int, int> _statusData = {};
  String _mainStatus = 'Tersedia';
  
  List<dynamic> _units = [];
  String _selectedUnitId = 'all';

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // If fleetId is provided, we fetch for that specific truck. 
      // Otherwise, we fetch 'truck-all'.
      final String idToFetch = widget.fleetId != null ? widget.fleetId.toString() : 'truck-all';
      
      final res = await FleetService().getAvailability(
        idToFetch, 
        _currentMonth, 
        _currentYear, 
        unitId: _selectedUnitId
      );
      
      final dates = res['dates'] as List<dynamic>;
      final Map<int, int> newStatus = {};
      
      for (var d in dates) {
        final dateStr = d['date'];
        final day = int.parse(dateStr.split('-')[2]);
        final st = d['status'];
        if (st == 'Tersedia') newStatus[day] = 1;
        else if (st == 'Dipesan') newStatus[day] = 2;
      }
      
      setState(() {
        _statusData = newStatus;
        _mainStatus = res['status_operasional'];
        _units = res['units'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        AppSnackBar.showError(context, 'Jadwal belum bisa dimuat. Silakan coba lagi beberapa saat.');
      }
    }
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
      _selectedDay = 1;
    });
    _fetchAvailability();
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
      _selectedDay = 1;
    });
    _fetchAvailability();
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
          'Jadwal Armada',
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
                      _buildFleetInfo(),
                      const SizedBox(height: 16),
                      if (widget.fleetGroup == 'all_trucks' && _units.isNotEmpty) _buildUnitFilter(),
                      if (widget.fleetGroup == 'all_trucks' && _units.isNotEmpty) const SizedBox(height: 16),
                      _buildCalendarCard(),
                      const SizedBox(height: 16),
                      _buildLegend(),
                      const SizedBox(height: 24),
                      _buildStatusCard(),
                      const SizedBox(height: 120), // Spacer for bottom action
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: widget.mode == 'view_only' ? null : _buildBottomAction(context),
    );
  }

  Widget _buildFleetInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentLime.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping, color: AppColors.primaryNavy, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fleetGroup == 'single_unit' && widget.fleetName != null
                      ? (widget.fleetCode != null && widget.fleetCode!.isNotEmpty ? '${widget.fleetCode} - ${widget.fleetName}' : widget.fleetName!)
                      : 'Semua Unit Truk',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.fleetGroup == 'single_unit' && widget.capacity != null
                      ? 'Truk Logistik • ${widget.capacity}'
                      : 'Truk Logistik',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedUnitId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryNavy),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Semua Unit', style: TextStyle(fontSize: 14))),
              ..._units.map((u) => DropdownMenuItem(
                value: u['id'].toString(), 
                child: Text('${u['code']} - ${u['name']}', style: const TextStyle(fontSize: 14))
              )).toList(),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedUnitId = val);
                _fetchAvailability();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    final daysInMonth = DateUtils.getDaysInMonth(_currentYear, _currentMonth);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.primaryNavy), onPressed: _prevMonth),
              Text(
                '${DateFormat('MMMM yyyy', 'id_ID').format(DateTime(_currentYear, _currentMonth))}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)
              ),
              IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.primaryNavy), onPressed: _nextMonth),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB']
                .map((day) => Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)))
                .toList(),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = _selectedDay == day;
                final status = _statusData[day];
                
                Color? dotColor;
                if (status == 1) dotColor = Colors.green;
                if (status == 2) dotColor = Colors.red;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentLime : Colors.transparent,
                      shape: BoxShape.circle,
                      border: !isSelected && status != null ? Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.1)) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primaryNavy : AppColors.textPrimary,
                          ),
                        ),
                        if (dotColor != null)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                          )
                      ],
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.green, 'Tersedia'),
          _buildLegendItem(Colors.red, 'Dipesan'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatusCard() {
    if (_mainStatus.toLowerCase() == 'perawatan') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.build_circle_outlined, color: Colors.orange, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Armada Sedang Perawatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                  SizedBox(height: 4),
                  Text('Armada ini belum tersedia untuk reservasi. Silakan pilih armada lain atau hubungi admin.', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            )
          ],
        ),
      );
    }
    
    if (_mainStatus.toLowerCase() == 'tidak aktif' || _mainStatus.toLowerCase() == 'tidak_aktif') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.not_interested, color: Colors.grey, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Armada Tidak Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Armada ini belum tersedia untuk reservasi.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      );
    }

    final status = _statusData[_selectedDay];
    
    IconData icon = Icons.info_outline;
    Color color = AppColors.primaryNavy;
    String title = 'Belum Ada Jadwal';
    String desc = 'Belum ada jadwal pada tanggal ini. Silakan pilih tanggal lain.';
    
    if (status == 1) {
      icon = Icons.check_circle_outline;
      color = Colors.green;
      title = 'Tersedia untuk Pengangkutan';
      desc = widget.mode == 'view_only'
          ? 'Tersedia pada tanggal ini.'
          : 'Admin akan mengonfirmasi unit, jadwal, dan estimasi biaya setelah permintaan dikirim.';
    } else if (status == 2) {
      icon = Icons.cancel_outlined;
      color = Colors.red;
      title = 'Tanggal Tidak Tersedia';
      desc = 'Armada sudah memiliki jadwal pada tanggal ini. Pilih tanggal lain.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final status = _statusData[_selectedDay];
    
    bool isAvailable = false;
    String text = 'Pilih Tanggal Lain';
    
    if (_mainStatus.toLowerCase() == 'perawatan' || _mainStatus.toLowerCase() == 'tidak aktif' || _mainStatus.toLowerCase() == 'tidak_aktif') {
      text = 'Armada Tidak Tersedia';
      isAvailable = false;
    } else if (status == 1) {
      text = 'Ajukan Permintaan';
      isAvailable = true;
    }

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
          onPressed: isAvailable ? () {
            if (!AuthState.instance.isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    onLoginSuccess: () {
                      Navigator.pop(context); // close login
                      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_currentYear, _currentMonth, _selectedDay));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TruckRequestPage(date: dateStr)),
                      );
                    },
                  ),
                ),
              );
              return;
            }
            final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_currentYear, _currentMonth, _selectedDay));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TruckRequestPage(date: dateStr)),
            );
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isAvailable ? AppColors.accentLime : AppColors.borderSoft,
            foregroundColor: isAvailable ? AppColors.primaryNavy : AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
