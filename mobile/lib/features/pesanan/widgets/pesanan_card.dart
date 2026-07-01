import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/pesanan/models/order_model.dart';
import 'package:mobile/features/pesanan/order_detail_page.dart';
import 'package:mobile/core/services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class PesananCard extends StatelessWidget {
  final OrderModel pesanan;
  final VoidCallback? onRefresh;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final bool isArchivedView;

  const PesananCard({
    super.key,
    required this.pesanan,
    this.onRefresh,
    this.onArchive,
    this.onUnarchive,
    this.isArchivedView = false,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu Konfirmasi':
        return Colors.orange;
      case 'Diterima':
        return Colors.green;
      case 'Dalam Perjalanan':
        return Colors.blue;
      case 'Selesai':
        return Colors.purple;
      case 'Dibatalkan':
        return Colors.grey;
      case 'Ditolak':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Belum Membayar':
        return Colors.grey;
      case 'Menunggu Validasi':
      case 'Menunggu Validasi Pembayaran':
      case 'Menunggu Validasi DP':
      case 'Menunggu Validasi Pelunasan':
        return Colors.orange;
      case 'DP Diterima':
        return Colors.blue;
      case 'Lunas':
        return AppColors.accentLime;
      case 'Ditolak':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
  
  String _formatCurrency(double? amount) {
    if (amount == null) return 'Menunggu Harga';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    // The admin number
    const adminPhone = '62895412506326'; 

    // Create the message text
    final String message = 
'''Halo Admin Sumber Agung Trans, saya ingin menanyakan pesanan saya.

Kode Pesanan: ${pesanan.orderCode}
Status Pesanan: ${pesanan.orderStatus}
Jenis Armada: ${pesanan.fleetType}
Rute: ${pesanan.origin} ke ${pesanan.destination}

Tolong bantu cek pesanan tersebut.''';

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$adminPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          AppSnackBar.showError(context, 'WhatsApp belum bisa dibuka di perangkat ini.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Gagal membuka WhatsApp.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(pesanan.orderStatus);
    final paymentColor = _getPaymentStatusColor(pesanan.paymentStatus);
    final bool isActive = pesanan.orderStatus != 'Selesai' && pesanan.orderStatus != 'Dibatalkan' && pesanan.orderStatus != 'Ditolak';
    final bool canArchive = pesanan.orderStatus == 'Selesai' || pesanan.orderStatus == 'Dibatalkan';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Slidable(
        key: ValueKey(pesanan.id),
        // Swipe right
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => _launchWhatsApp(context),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.chat,
              label: 'Hubungi',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                bottomLeft: Radius.circular(24.0),
              ),
            ),
          ],
        ),
        // Swipe left
        endActionPane: isArchivedView 
        ? ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) {
                if (onUnarchive != null) {
                  onUnarchive!();
                }
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.unarchive,
              label: 'Pulihkan',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24.0),
                bottomRight: Radius.circular(24.0),
              ),
            ),
          ],
        )
        : (canArchive ? ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) {
                if (onArchive != null) {
                  onArchive!();
                }
              },
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              icon: Icons.archive,
              label: 'Arsipkan',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24.0),
                bottomRight: Radius.circular(24.0),
              ),
            ),
          ],
        ) : null),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.borderSoft),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Order ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pesanan.orderCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pesanan.orderStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Image and Fleet Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 88,
                  height: 88,
                  color: const Color(0xFFF1F3F5),
                  child: pesanan.displayImageUrl != null
                      ? Image.network(
                          pesanan.displayImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            pesanan.fleetType.toLowerCase() == 'truk' ? Icons.local_shipping : Icons.directions_bus, 
                            color: AppColors.textMuted, 
                            size: 28
                          ),
                        )
                      : Icon(
                          pesanan.fleetType.toLowerCase() == 'truk' ? Icons.local_shipping : Icons.directions_bus, 
                          color: AppColors.textMuted, 
                          size: 28
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.fleetType.toLowerCase() == 'truk' 
                          ? (pesanan.assignedFleetId != null 
                              ? '${pesanan.assignedFleetCode ?? ''} · ${pesanan.assignedFleetName ?? ''}'
                              : 'Truk Logistik')
                          : pesanan.fleetName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                        height: 1.3,
                      ),
                    ),
                    if (pesanan.fleetType.toLowerCase() == 'truk' && pesanan.assignedFleetPlate != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.borderSoft),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pesanan.assignedFleetPlate!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      pesanan.fleetType.toLowerCase() == 'truk' ? (pesanan.truckServiceType ?? pesanan.serviceType) : pesanan.serviceType,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Route Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.my_location, size: 14, color: AppColors.textMuted),
                    Container(
                      height: 12,
                      width: 1,
                      color: AppColors.borderSoft,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pesanan.origin,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pesanan.destination,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details Row (Date & Cost)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tanggal Keberangkatan', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('${pesanan.departureDate ?? '-'} ${pesanan.departureTime ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Biaya', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(pesanan.totalPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Payment Status
          Row(
            children: [
              const Text('Status Pembayaran: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: paymentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pesanan.paymentStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: paymentColor == AppColors.accentLime ? AppColors.primaryNavy : paymentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSoft, height: 1),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              if (pesanan.canCancel) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(orderId: pesanan.id),
                      ),
                    ).then((_) {
                      if (onRefresh != null) onRefresh!();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? AppColors.accentLime : AppColors.surface,
                    foregroundColor: isActive ? AppColors.primaryNavy : AppColors.primaryNavy,
                    side: isActive ? BorderSide.none : const BorderSide(color: AppColors.primaryNavy),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
  );
}

  void _showCancelDialog(BuildContext context) {
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
                          setState(() {
                            isSubmitting = true;
                          });
                          try {
                            await OrderService().cancelOrder(pesanan.id, reason: reasonController.text);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              AppSnackBar.showSuccess(context, 'Pesanan berhasil dibatalkan');
                              if (onRefresh != null) onRefresh!();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
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
}
