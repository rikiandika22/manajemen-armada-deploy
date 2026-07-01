import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/armada/widgets/armada_card.dart';
import 'package:mobile/features/armada/widgets/armada_filter_chips.dart';
import 'package:mobile/features/armada/widgets/armada_header.dart';
import 'package:mobile/features/armada/widgets/armada_recommendation_card.dart';
import 'package:mobile/features/armada/widgets/armada_search_bar.dart';
import 'package:mobile/core/services/fleet_service.dart';
import 'package:mobile/features/fleet/models/fleet_model.dart';

class ArmadaPage extends StatefulWidget {
  final String? source;
  final String? fleetType;
  final String? initialCategory;
  final String? origin;
  final String? destination;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? date;
  final ValueNotifier<int>? refreshNotifier;

  const ArmadaPage({
    super.key,
    this.source,
    this.fleetType,
    this.initialCategory,
    this.origin,
    this.destination,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.date,
    this.refreshNotifier,
  });

  @override
  State<ArmadaPage> createState() => _ArmadaPageState();
}

class _ArmadaPageState extends State<ArmadaPage> {
  final FleetService _fleetService = FleetService();
  bool _isLoading = true;
  String? _error;
  List<FleetModel> _baseFleets = [];
  String _searchQuery = '';
  late String _selectedCategory;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Semua';
    _fetchData();
    widget.refreshNotifier?.addListener(_onRefreshNotified);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshNotified);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefreshNotified() {
    if (widget.refreshNotifier?.value == 1) {
      _fetchData();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  String _normalizeFleetType(String fleetType) {
    final type = fleetType.toLowerCase();
    if (type.contains('bus')) return 'Bus';
    if (type.contains('elf')) return 'Elf';
    if (type.contains('truk') || type.contains('truck') || type.contains('cdd')) return 'Truk';
    return 'Lainnya';
  }

  List<FleetModel> get _filteredBusElfFleets {
    return _baseFleets.where((fleet) {
      if (_normalizeFleetType(fleet.fleetType) == 'Truk') return false;
      
      // 1. Filter by category
      bool categoryMatch = true;
      if (_selectedCategory != 'Semua') {
        final normalizedType = _normalizeFleetType(fleet.fleetType);
        categoryMatch = normalizedType == _selectedCategory;
      }
      
      // 2. Filter by search query
      bool searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        searchMatch = fleet.fleetName.toLowerCase().contains(query) ||
                      fleet.fleetCode.toLowerCase().contains(query) ||
                      fleet.fleetType.toLowerCase().contains(query) ||
                      fleet.licensePlate.toLowerCase().contains(query) ||
                      (fleet.description?.toLowerCase().contains(query) ?? false);
      }
      
      return categoryMatch && searchMatch;
    }).toList();
  }

  bool get _showAggregateTruck {
    if (widget.source == 'home_availability' && widget.fleetType == 'all_passenger') return false;
    if (_selectedCategory == 'Bus' || _selectedCategory == 'Elf') return false;
    
    final truckFleets = _baseFleets.where((f) => _normalizeFleetType(f.fleetType) == 'Truk').toList();
    if (truckFleets.isEmpty) return false;
    
    if (_searchQuery.isEmpty) return true;
    
    final query = _searchQuery.toLowerCase();
    if ('truk logistik'.contains(query) || 'truk'.contains(query) || 
        'palawija'.contains(query) || 'pasir'.contains(query) || 
        'ternak'.contains(query) || 'material'.contains(query)) {
      return true;
    }
    
    for (var fleet in truckFleets) {
      if (fleet.fleetName.toLowerCase().contains(query) ||
          fleet.fleetCode.toLowerCase().contains(query) ||
          fleet.fleetType.toLowerCase().contains(query) ||
          fleet.licensePlate.toLowerCase().contains(query) ||
          (fleet.description?.toLowerCase().contains(query) ?? false)) {
        return true;
      }
    }
    
    return false;
  }

  Map<String, dynamic>? _getAggregateTruckDetails() {
    final truckFleets = _baseFleets.where((f) => _normalizeFleetType(f.fleetType) == 'Truk').toList();
    if (truckFleets.isEmpty) return null;
    
    final totalUnit = truckFleets.length;
    final availableUnit = truckFleets.where((f) => f.status == 'Tersedia').length;
    final scheduledUnit = truckFleets.where((f) => f.status == 'Terjadwal').length;
    
    String status = 'Tidak Tersedia';
    if (availableUnit > 0) {
      status = 'Tersedia';
    } else if (scheduledUnit == totalUnit && totalUnit > 0) {
      status = 'Terjadwal';
    } else {
      status = truckFleets.first.status;
    }
    
    List<double> capacityNumbers = [];
    bool hasInvalidCapacity = false;
    for (var f in truckFleets) {
      if (f.capacity.isEmpty) {
        hasInvalidCapacity = true;
        continue;
      }
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(f.capacity);
      if (match != null) {
        capacityNumbers.add(double.parse(match.group(1)!));
      } else {
        hasInvalidCapacity = true;
      }
    }
    
    String capacityText = 'Kapasitas bervariasi';
    if (!hasInvalidCapacity && capacityNumbers.isNotEmpty) {
      final min = capacityNumbers.reduce((a, b) => a < b ? a : b);
      final max = capacityNumbers.reduce((a, b) => a > b ? a : b);
      if (min == max) {
        capacityText = truckFleets.first.capacity;
      } else {
        bool isTon = truckFleets.any((f) => f.capacity.toLowerCase().contains('ton') || f.capacity.toLowerCase().contains('tons'));
        capacityText = '${min.toInt()} sampai ${max.toInt()} ${isTon ? "Ton" : ""}';
      }
    }
    
    List<String> imageUrls = [];
    for (var f in truckFleets) {
      if (f.imageUrls.isNotEmpty) {
        imageUrls.addAll(f.imageUrls);
      } else if (f.imageUrl != null) {
        imageUrls.add(f.imageUrl!);
      }
    }
    
    return {
      'name': 'Truk Logistik',
      'capacity': '$totalUnit Unit • $capacityText',
      'status': status,
      'description': 'Cocok untuk angkutan palawija, ternak, pasir, abu, material, dan kebutuhan logistik lainnya.',
      'subInfo': '$availableUnit tersedia • $scheduledUnit terjadwal',
      'imageUrls': imageUrls.toSet().toList(),
    };
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fleets = await _fleetService.getFleets();

      setState(() {
        if (widget.source == 'home_availability') {
          if (widget.fleetType == 'all_passenger') {
            _baseFleets = fleets.where((f) => _normalizeFleetType(f.fleetType) == 'Bus' || _normalizeFleetType(f.fleetType) == 'Elf').toList();
          } else if (widget.fleetType == 'Bus') {
            _baseFleets = fleets.where((f) => _normalizeFleetType(f.fleetType) == 'Bus').toList();
          } else if (widget.fleetType == 'Elf') {
            _baseFleets = fleets.where((f) => _normalizeFleetType(f.fleetType) == 'Elf').toList();
          } else {
             _baseFleets = fleets;
          }
        } else {
          _baseFleets = fleets;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.primaryNavy,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.source == 'bottom_nav' ? 120.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (widget.source != 'home_availability') ...[
                  ArmadaHeader(
                    showBackButton: widget.source != 'bottom_nav',
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Pilih armada sesuai kebutuhan perjalanan atau pengangkutan Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ArmadaSearchBar(
                    onSearchChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ArmadaFilterChips(
                    initialCategory: _selectedCategory,
                    onFilterChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const ArmadaRecommendationCard(),
                  const SizedBox(height: 24),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hasil Ketersediaan ${widget.fleetType == 'all_passenger' ? 'Bus & Elf' : widget.fleetType}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.route_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${widget.origin} ke ${widget.destination}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${widget.date}',
                                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildContent(),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentLime),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLime),
              child: const Text('Coba Lagi', style: TextStyle(color: AppColors.primaryNavy)),
            ),
          ],
        ),
      );
    }

    final filteredBusElfFleets = _filteredBusElfFleets;
    final showAggregateTruck = _showAggregateTruck;
    final aggregateTruckDetails = showAggregateTruck ? _getAggregateTruckDetails() : null;

    if (filteredBusElfFleets.isEmpty && !showAggregateTruck) {
      String emptyText = 'Belum ada data armada.';
      if (_searchQuery.isNotEmpty) {
        emptyText = 'Tidak ada armada yang cocok dengan pencarian Anda.';
      } else if (_selectedCategory != 'Semua') {
        if (_selectedCategory == 'Truk') {
          emptyText = 'Belum ada armada truk tersedia.';
        } else {
          emptyText = 'Tidak ada armada $_selectedCategory yang ditemukan.';
        }
      }
      
      if (widget.source == 'home_availability' && _searchQuery.isEmpty) {
        emptyText = 'Tidak ada Bus atau Elf tersedia pada tanggal ini.';
        if (widget.fleetType == 'Bus') emptyText = 'Tidak ada Bus tersedia pada tanggal ini.';
        if (widget.fleetType == 'Elf') emptyText = 'Tidak ada Elf tersedia pada tanggal ini.';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: AppColors.primaryNavy),
                ),
                child: const Text('Kembali ke Home'),
              ),
            ],
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(emptyText, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Render Bus & Elf Filtered Fleets
          ...filteredBusElfFleets.map((armada) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ArmadaCard(
                id: armada.id,
                name: armada.fleetName,
                capacity: armada.capacity,
                status: armada.status,
                description: armada.description ?? '',
                subInfo: armada.priceText,
                imageUrl: armada.imageUrl,
                imageUrls: armada.imageUrls,
                origin: widget.origin,
                originLat: widget.originLat,
                originLng: widget.originLng,
                destination: widget.destination,
                destinationLat: widget.destinationLat,
                destinationLng: widget.destinationLng,
                date: widget.date,
              ),
            );
          }),
          
          // Render Truck Aggregate Card
          if (showAggregateTruck && aggregateTruckDetails != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ArmadaCard(
                name: aggregateTruckDetails['name'],
                capacity: aggregateTruckDetails['capacity'],
                status: aggregateTruckDetails['status'],
                description: aggregateTruckDetails['description'],
                subInfo: aggregateTruckDetails['subInfo'],
                imageUrls: aggregateTruckDetails['imageUrls'],
                origin: widget.origin,
                originLat: widget.originLat,
                originLng: widget.originLng,
                destination: widget.destination,
                destinationLat: widget.destinationLat,
                destinationLng: widget.destinationLng,
                date: widget.date,
              ),
            ),
        ],
      ),
    );
  }
}
