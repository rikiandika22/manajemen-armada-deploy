class FleetSummaryItem {
  final int totalUnit;
  final int availableUnit;
  final int bookedUnit;
  final int maintenanceUnit;
  final int inactiveUnit;
  final String status;
  final num? minCapacity;
  final num? maxCapacity;
  final String? capacityUnit;

  FleetSummaryItem({
    required this.totalUnit,
    required this.availableUnit,
    required this.bookedUnit,
    required this.maintenanceUnit,
    required this.inactiveUnit,
    required this.status,
    this.minCapacity,
    this.maxCapacity,
    this.capacityUnit,
  });

  factory FleetSummaryItem.fromJson(Map<String, dynamic> json) {
    return FleetSummaryItem(
      totalUnit: _parseInt(json['total_unit']),
      availableUnit: _parseInt(json['available_unit']),
      bookedUnit: _parseInt(json['booked_unit']),
      maintenanceUnit: _parseInt(json['maintenance_unit']),
      inactiveUnit: _parseInt(json['inactive_unit']),
      status: json['status']?.toString() ?? 'Tersedia',
      minCapacity: _parseNum(json['min_capacity']),
      maxCapacity: _parseNum(json['max_capacity']),
      capacityUnit: json['capacity_unit']?.toString(),
    );
  }

  String _formatNumber(num val) {
    if (val == val.toInt()) return val.toInt().toString();
    return val.toString().replaceAll('.', ',');
  }

  String get capacityText {
    if (minCapacity == null && maxCapacity == null) return 'Kapasitas belum diisi';
    
    final unit = capacityUnit ?? 'ton';
    final unitLower = unit.toLowerCase() == 'ton' ? 'ton' : unit;
    
    if (minCapacity != null && maxCapacity != null) {
      if (minCapacity == maxCapacity) {
        return 'Kapasitas ${_formatNumber(minCapacity!)} $unitLower';
      }
      return 'Kapasitas ${_formatNumber(minCapacity!)} sampai ${_formatNumber(maxCapacity!)} $unitLower';
    }
    
    if (maxCapacity != null) {
      return 'Kapasitas ${_formatNumber(maxCapacity!)} $unitLower';
    }
    
    return 'Kapasitas belum diisi';
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}

class FleetSummaryModel {
  final FleetSummaryItem bus;
  final FleetSummaryItem elf;
  final FleetSummaryItem truck;

  FleetSummaryModel({
    required this.bus,
    required this.elf,
    required this.truck,
  });

  factory FleetSummaryModel.fromJson(Map<String, dynamic> json) {
    return FleetSummaryModel(
      bus: FleetSummaryItem.fromJson(json['bus'] ?? {}),
      elf: FleetSummaryItem.fromJson(json['elf'] ?? {}),
      truck: FleetSummaryItem.fromJson(json['truck'] ?? {}),
    );
  }
}
