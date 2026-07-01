import 'package:mobile/core/constants/api_config.dart';

class OrderModel {
  final int id;
  final String orderCode;
  final String serviceType;
  final String fleetName;
  final String fleetType;
  final String origin;
  final String destination;
  final String? departureDate;
  final String? departureTime;
  final String? estimatedFinish;
  final double? totalPrice;
  final String paymentStatus;
  final String orderStatus;
  final String createdAt;
  final String? truckServiceType;
  final int? assignedFleetId;
  final String? assignedFleetCode;
  final String? assignedFleetName;
  final String? assignedFleetPlate;
  final String? assignedFleetImageUrl;
  final String? serviceCoverImageUrl;
  final String? displayImageUrl;

  final String? canceledAt;
  final String? cancelReason;
  
  // Fields related to API response (like dpAmount, remainingPayment, proofPaymentUrl, customerNote)
  // are added here assuming they might be added later, or we just leave them null if absent.
  final double? dpAmount;
  final double? remainingPayment;
  final String? proofPaymentUrl;
  final String? settlementProofUrl;
  final String? customerNote;
  final String? adminNote;
  final String? rejectedReason;
  
  // Price fields for truck
  final String? priceStatus;
  final String? priceNote;
  final String? priceSentAt;

  final String? userArchivedAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.serviceType,
    required this.fleetName,
    required this.fleetType,
    required this.origin,
    required this.destination,
    this.departureDate,
    this.departureTime,
    this.estimatedFinish,
    this.totalPrice,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    this.truckServiceType,
    this.assignedFleetId,
    this.assignedFleetCode,
    this.assignedFleetName,
    this.assignedFleetPlate,
    this.assignedFleetImageUrl,
    this.serviceCoverImageUrl,
    this.displayImageUrl,
    this.canceledAt,
    this.cancelReason,
    this.dpAmount,
    this.remainingPayment,
    this.proofPaymentUrl,
    this.settlementProofUrl,
    this.customerNote,
    this.adminNote,
    this.rejectedReason,
    this.priceStatus,
    this.priceNote,
    this.priceSentAt,
    this.userArchivedAt,
  });

  bool get canCancel {
    final allowed = [
      'Menunggu Konfirmasi',
      'Menunggu Konfirmasi Admin',
      'Menunggu Pembayaran',
      'Menunggu Validasi Pembayaran',
      'Menunggu Validasi DP',
    ];
    return allowed.contains(orderStatus) || allowed.contains(paymentStatus);
  }

  bool get isTruckOrder {
    return fleetType.toLowerCase().contains('truk');
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderCode: json['order_code'] ?? '',
      serviceType: json['service_type'] ?? '',
      fleetName: json['fleet_name'] ?? '',
      fleetType: json['fleet_type'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      departureDate: json['departure_date'],
      departureTime: json['departure_time'],
      estimatedFinish: json['estimated_finish'],
      totalPrice: json['total_price'] != null ? double.tryParse(json['total_price'].toString()) : null,
      paymentStatus: json['payment_status'] ?? 'Menunggu Validasi',
      orderStatus: json['order_status'] ?? 'Menunggu Konfirmasi',
      createdAt: json['created_at'] ?? '',
      truckServiceType: json['truck_service_type'],
      assignedFleetId: json['assigned_fleet_id'],
      assignedFleetCode: json['assigned_fleet_code'],
      assignedFleetName: json['assigned_fleet_name'],
      assignedFleetPlate: json['assigned_fleet_plate'],
      assignedFleetImageUrl: json['assigned_fleet_image_url'],
      serviceCoverImageUrl: json['service_cover_image_url'],
      displayImageUrl: json['display_image_url'],
      canceledAt: json['canceled_at'],
      cancelReason: json['cancel_reason'] ?? json['cancelReason'],
      dpAmount: json['dp_amount'] != null ? double.tryParse(json['dp_amount'].toString()) : null,
      remainingPayment: json['remaining_payment'] != null ? double.tryParse(json['remaining_payment'].toString()) : null,
      proofPaymentUrl: ApiConfig.resolveImageUrl(json['proof_payment_url']),
      settlementProofUrl: ApiConfig.resolveImageUrl(json['settlement_proof_url']),
      customerNote: json['customer_note'] ?? json['customerNote'] ?? json['notes'],
      adminNote: json['admin_note'] ?? json['adminNote'],
      rejectedReason: json['rejected_reason'] ?? json['rejectedReason'],
      priceStatus: json['price_status'] ?? json['priceStatus'],
      priceNote: json['price_note'] ?? json['priceNote'],
      priceSentAt: json['price_sent_at'] ?? json['priceSentAt'],
      userArchivedAt: json['user_archived_at'] ?? json['userArchivedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'service_type': serviceType,
      'fleet_name': fleetName,
      'fleet_type': fleetType,
      'origin': origin,
      'destination': destination,
      'departure_date': departureDate,
      'departure_time': departureTime,
      'estimated_finish': estimatedFinish,
      'total_price': totalPrice,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'created_at': createdAt,
      'truck_service_type': truckServiceType,
      'assigned_fleet_id': assignedFleetId,
      'assigned_fleet_code': assignedFleetCode,
      'assigned_fleet_name': assignedFleetName,
      'assigned_fleet_plate': assignedFleetPlate,
      'assigned_fleet_image_url': assignedFleetImageUrl,
      'service_cover_image_url': serviceCoverImageUrl,
      'display_image_url': displayImageUrl,
      'canceled_at': canceledAt,
      'cancel_reason': cancelReason,
      'dp_amount': dpAmount,
      'remaining_payment': remainingPayment,
      'proof_payment_url': proofPaymentUrl,
      'settlement_proof_url': settlementProofUrl,
      'customer_note': customerNote,
      'admin_note': adminNote,
      'rejected_reason': rejectedReason,
      'price_status': priceStatus,
      'price_note': priceNote,
      'price_sent_at': priceSentAt,
      'user_archived_at': userArchivedAt,
    };
  }
}
