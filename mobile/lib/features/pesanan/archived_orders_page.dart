import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/services/order_service.dart';
import 'package:mobile/features/pesanan/models/order_model.dart';
import 'package:mobile/features/pesanan/widgets/pesanan_card.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class ArchivedOrdersPage extends StatefulWidget {
  const ArchivedOrdersPage({super.key});

  @override
  State<ArchivedOrdersPage> createState() => _ArchivedOrdersPageState();
}

class _ArchivedOrdersPageState extends State<ArchivedOrdersPage> {
  List<OrderModel> _archivedOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchArchivedOrders();
  }

  Future<void> _fetchArchivedOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await OrderService().fetchArchivedOrders();
      if (mounted) {
        setState(() {
          _archivedOrders = orders;
          _isLoading = false;
        });
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

  Future<void> _handleUnarchiveOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryNavy)),
        content: const Text('Pesanan ini akan ditampilkan kembali di daftar utama.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await OrderService().unarchiveOrder(orderId);
      
      if (mounted) {
        setState(() {
          _archivedOrders.removeWhere((o) => o.id == orderId);
        });
        AppSnackBar.showSuccess(context, 'Pesanan berhasil dipulihkan');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Diarsipkan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryNavy),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchArchivedOrders,
        color: AppColors.primaryNavy,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryNavy),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Gagal memuat pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchArchivedOrders,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_archivedOrders.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.archive_outlined, size: 64, color: AppColors.primaryNavy.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum Ada Pesanan Diarsipkan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pesanan yang kamu arsipkan akan muncul di sini.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _archivedOrders.length,
      itemBuilder: (context, index) {
        return PesananCard(
          pesanan: _archivedOrders[index],
          onRefresh: _fetchArchivedOrders,
          isArchivedView: true,
          onUnarchive: () => _handleUnarchiveOrder(_archivedOrders[index].id),
        );
      },
    );
  }
}
