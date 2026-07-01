import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/services/order_service.dart';
import 'package:mobile/core/services/badge_service.dart';
import 'package:mobile/features/pesanan/models/order_model.dart';
import 'package:mobile/shared/widgets/payment_proof_preview_page.dart';
import 'package:mobile/core/services/payment_account_service.dart';
import 'package:mobile/features/payment/models/payment_account_model.dart';
import 'package:mobile/features/payment/widgets/payment_account_selector.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isLoading = true;
  String? _error;
  OrderModel? _order;
  bool _isUploading = false;
  File? _selectedProofFile;
  int? _selectedAccountId;
  List<PaymentAccount> _accounts = [];
  bool _isLoadingAccounts = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoadingAccounts = true);
    try {
      final service = PaymentAccountService();
      final accounts = await service.fetchPaymentAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          if (accounts.isNotEmpty) {
            _selectedAccountId = accounts.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load accounts: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await OrderService().getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
        // Mark this order as read for badge purposes
        BadgeService().markAsRead(order.id, order.orderStatus, order.paymentStatus);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'Menunggu Harga';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu Konfirmasi': return Colors.orange;
      case 'Menunggu Konfirmasi Admin': return Colors.orange;
      case 'Diterima': return Colors.green;
      case 'Dalam Perjalanan': return Colors.blue;
      case 'Selesai': return Colors.purple;
      case 'Dibatalkan': return Colors.grey;
      case 'Ditolak': return Colors.red;
      default: return AppColors.textSecondary;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Belum Membayar': return Colors.grey;
      case 'Menunggu Validasi': return Colors.orange;
      case 'Menunggu Validasi Pembayaran': return Colors.orange;
      case 'DP Diterima': return Colors.blue;
      case 'Lunas': return AppColors.accentLime;
      case 'Ditolak': return Colors.red;
      default: return AppColors.textSecondary;
    }
  }

  void _showCancelDialog() {
    if (_order == null) return;
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesanan yang dibatalkan tidak dapat diproses lebih lanjut. Pastikan Anda ingin membatalkan pesanan ini.', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'Alasan pembatalan (opsional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() { isSubmitting = true; });
                          try {
                            await OrderService().cancelOrder(_order!.id, reason: reasonController.text);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              AppSnackBar.showSuccess(context, 'Pesanan berhasil dibatalkan');
                              _fetchDetail();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() { isSubmitting = false; });
                              AppSnackBar.showError(context, e.toString());
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
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
          'Detail Pesanan',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _buildDetailContent(),
      ),
    );
  }

  Widget _buildDetailContent() {
    final order = _order!;
    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: AppColors.primaryNavy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(order),
            const SizedBox(height: 16),
            _buildArmadaCard(order),
            const SizedBox(height: 16),
            _buildJadwalCard(order),
            const SizedBox(height: 16),
            _buildPaymentCard(order),
            const SizedBox(height: 16),
            if ((order.customerNote != null && order.customerNote!.trim().isNotEmpty) || 
                (order.adminNote != null && order.adminNote!.trim().isNotEmpty) || 
                (order.cancelReason != null && order.cancelReason!.trim().isNotEmpty) ||
                (order.priceNote != null && order.priceNote!.trim().isNotEmpty)) 
              _buildNotesCard(order),
            const SizedBox(height: 16),
            _buildUploadPaymentSection(order),
            
            if (order.canCancel) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _showCancelDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 48),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kode Pesanan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(order.orderCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSoft, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status Pesanan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              _buildBadge(order.orderStatus, _getStatusColor(order.orderStatus)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status Pembayaran', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              _buildBadge(order.paymentStatus, _getPaymentStatusColor(order.paymentStatus)),
            ],
          ),
          if (order.canceledAt != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dibatalkan Pada', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(order.canceledAt!.split('T')[0], style: const TextStyle(fontSize: 13, color: Colors.red)),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildArmadaCard(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Armada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF1F3F5),
                  child: order.displayImageUrl != null
                      ? Image.network(
                          order.displayImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            order.fleetType.toLowerCase() == 'truk' ? Icons.local_shipping : Icons.directions_bus, 
                            color: AppColors.textMuted, 
                            size: 24
                          ),
                        )
                      : Icon(
                          order.fleetType.toLowerCase() == 'truk' ? Icons.local_shipping : Icons.directions_bus, 
                          color: AppColors.textMuted, 
                          size: 24
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.isTruckOrder 
                          ? (order.assignedFleetId != null 
                              ? '${order.assignedFleetCode ?? ''} · ${order.assignedFleetName ?? ''}'
                              : 'Truk Logistik')
                          : order.fleetName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    if (order.isTruckOrder && order.assignedFleetPlate != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.borderSoft),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.assignedFleetPlate!,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      order.isTruckOrder ? (order.truckServiceType ?? order.serviceType) : order.serviceType,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.isTruckOrder && order.assignedFleetId == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Unit truk belum ditetapkan. Admin akan menentukan unit truk setelah mengecek jadwal dan kebutuhan pengangkutan.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildJadwalCard(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jadwal & Rute', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          const SizedBox(height: 16),
          _buildInfoRow('Lokasi Asal', order.origin),
          const SizedBox(height: 12),
          _buildInfoRow('Lokasi Tujuan', order.destination),
          const SizedBox(height: 12),
          _buildInfoRow('Tanggal Berangkat', order.departureDate ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Jam Berangkat', order.departureTime ?? '-'),
          if (order.estimatedFinish != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Perkiraan Selesai', order.estimatedFinish!),
          ]
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.priceStatus == 'Estimasi Harga' ? 'Estimasi Biaya' : 'Total Biaya', 
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)
              ),
              Text(
                order.totalPrice == null ? 'Menunggu Harga' : _formatCurrency(order.totalPrice), 
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold, 
                  color: order.totalPrice == null ? Colors.orange : AppColors.primaryNavy
                )
              ),
            ],
          ),
          if (order.dpAmount != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DP / Uang Muka', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(_formatCurrency(order.dpAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
              ],
            ),
          ],
          if (order.remainingPayment != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sisa Pembayaran', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(_formatCurrency(order.remainingPayment), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
              ],
            ),
          ],
          if (order.totalPrice == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Admin sedang mengecek estimasi harga berdasarkan lokasi, jenis muatan, dan unit truk yang tersedia.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSoft, height: 1),
          const SizedBox(height: 12),
          const Text('Bukti Pembayaran DP', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (order.proofPaymentUrl != null && order.proofPaymentUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProofPreviewPage(
                      imageUrl: order.proofPaymentUrl!,
                      title: 'Preview Bukti DP',
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      order.proofPaymentUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Text('Bukti pembayaran gagal dimuat', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text('Bukti DP belum tersedia', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSoft, height: 1),
          const SizedBox(height: 12),
          const Text('Bukti Pelunasan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (order.settlementProofUrl != null && order.settlementProofUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProofPreviewPage(
                      imageUrl: order.settlementProofUrl!,
                      title: 'Preview Bukti Pelunasan',
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      order.settlementProofUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Text('Bukti pembayaran gagal dimuat', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text('Bukti pelunasan belum tersedia', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  /// Upload payment proof section for truck orders where price has been set, and for pelunasan
  Widget _buildUploadPaymentSection(OrderModel order) {
    // Only show if price is set
    final hasPriceSet = order.totalPrice != null;
    
    // DP Upload condition
    final isPaymentRejected = order.paymentStatus == 'Ditolak';
    final canUploadDP = hasPriceSet && 
      (order.paymentStatus == 'Belum Membayar' || 
       order.paymentStatus == 'Menunggu Pembayaran' ||
       (isPaymentRejected && order.proofPaymentUrl == null));
       
    // Settlement Upload condition
    // Note: If settlement is rejected, paymentStatus reverts to 'DP Diterima' in backend,
    // so it naturally allows re-uploading settlement.
    final canUploadSettlement = order.paymentStatus == 'DP Diterima' && (order.remainingPayment != null && order.remainingPayment! > 0);

    if (!canUploadDP && !canUploadSettlement) return const SizedBox.shrink();
    if (order.orderStatus == 'Selesai' || order.orderStatus == 'Dibatalkan' || order.paymentStatus == 'Lunas') return const SizedBox.shrink();

    final isPelunasan = canUploadSettlement;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPelunasan ? 'Upload Pelunasan' : (isPaymentRejected ? 'Upload Ulang Bukti DP' : 'Upload Bukti DP'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          Text(
            isPelunasan
                ? 'Silakan transfer sisa pelunasan lalu upload bukti pembayaran.'
                : (isPaymentRejected
                    ? 'Pembayaran sebelumnya ditolak. Silakan upload ulang bukti transfer yang benar.'
                    : 'Silakan transfer sesuai nominal DP lalu upload bukti pembayaran.'),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Bank selector
          PaymentAccountSelector(
            accounts: _accounts,
            selectedAccountId: _selectedAccountId,
            isLoading: _isLoadingAccounts,
            onSelected: (id) {
              setState(() {
                _selectedAccountId = id;
              });
            },
          ),
          const SizedBox(height: 16),

          // File picker
          GestureDetector(
            onTap: _pickProofFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft, style: BorderStyle.solid),
              ),
              child: _selectedProofFile != null
                  ? Column(
                      children: [
                        const Icon(Icons.check_circle, size: 36, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(
                          _selectedProofFile!.path.split('/').last,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text('Tap untuk ganti file', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )
                  : const Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Pilih File Bukti Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('JPG, PNG, atau PDF (maks 5MB)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedAccountId != null && _selectedProofFile != null && !_isUploading)
                  ? () => _handleUploadPayment(isPelunasan)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: AppColors.borderSoft,
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isPelunasan ? 'Kirim Bukti Pelunasan' : 'Kirim Bukti DP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _pickProofFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedProofFile = File(result.files.single.path!);
      });
    }
  }

  void _handleUploadPayment(bool isPelunasan) async {
    if (_selectedAccountId == null || _selectedProofFile == null || _order == null) return;

    setState(() => _isUploading = true);

    try {
      if (isPelunasan) {
        await OrderService().uploadSettlementProof(
          _order!.id,
          paymentProof: _selectedProofFile!,
          paymentAccountId: _selectedAccountId!,
        );
      } else {
        await OrderService().uploadPaymentProof(
          _order!.id,
          paymentProof: _selectedProofFile!,
          paymentAccountId: _selectedAccountId!,
        );
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, isPelunasan ? 'Bukti pelunasan berhasil dikirim' : 'Bukti pembayaran berhasil diunggah');
        setState(() {
          _selectedProofFile = null;
        });
        _fetchDetail();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildNotesCard(OrderModel order) {
    bool hasCustomerNote = order.customerNote != null && order.customerNote!.trim().isNotEmpty;
    bool hasAdminNote = order.adminNote != null && order.adminNote!.trim().isNotEmpty;
    bool hasCancelReason = order.cancelReason != null && order.cancelReason!.trim().isNotEmpty;
    bool hasRejectedReason = order.rejectedReason != null && order.rejectedReason!.trim().isNotEmpty;
    bool hasPriceNote = order.priceNote != null && order.priceNote!.trim().isNotEmpty;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          const SizedBox(height: 16),
          if (hasCustomerNote) ...[
            _buildNoteItem('Dari Anda:', order.customerNote!),
            if (hasAdminNote || hasCancelReason || hasRejectedReason || hasPriceNote) const SizedBox(height: 12),
          ],
          if (hasPriceNote) ...[
            _buildNoteItem('Catatan Harga:', order.priceNote!),
            if (hasAdminNote || hasCancelReason || hasRejectedReason) const SizedBox(height: 12),
          ],
          if (hasAdminNote) ...[
            const Text('Catatan Admin:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(order.adminNote!, style: const TextStyle(fontSize: 13, color: AppColors.primaryNavy)),
          ],
          if (hasCancelReason) ...[
            const SizedBox(height: 12),
            const Text('Alasan Pembatalan:', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(order.cancelReason!, style: const TextStyle(fontSize: 13, color: Colors.red)),
          ],
          if (hasRejectedReason) ...[
            const SizedBox(height: 12),
            const Text('Alasan Penolakan Pembayaran:', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(order.rejectedReason!, style: const TextStyle(fontSize: 13, color: Colors.orange)),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteItem(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(fontSize: 13, color: AppColors.primaryNavy)),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: child,
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
