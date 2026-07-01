import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/pesanan/widgets/pesanan_header.dart';
import 'package:mobile/features/pesanan/widgets/pesanan_search_bar.dart';
import 'package:mobile/features/pesanan/widgets/pesanan_filter_chips.dart';
import 'package:mobile/features/pesanan/widgets/pesanan_summary_cards.dart';
import 'package:mobile/features/pesanan/widgets/pesanan_card.dart';
import 'package:mobile/features/pesanan/widgets/pesanan_empty_state.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/shared/widgets/login_required_view.dart';
import 'package:mobile/core/services/order_service.dart';
import 'package:mobile/features/pesanan/models/order_model.dart';
import 'package:mobile/features/pesanan/archived_orders_page.dart' as mobile_archived;
import 'package:mobile/core/utils/app_snackbar.dart';

class PesananPage extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  final VoidCallback? onBadgeUpdateNeeded;

  const PesananPage({
    super.key,
    this.refreshNotifier,
    this.onBadgeUpdateNeeded,
  });

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  final List<String> statuses = [
    'Semua',
    'Menunggu Konfirmasi',
    'Diterima',
    'Dalam Perjalanan',
    'Selesai',
    'Dibatalkan'
  ];
  String _selectedStatus = 'Semua';
  String _searchQuery = '';

  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _error;

  int? _currentUserId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthState.instance.user?['id'];
    AuthState.instance.addListener(_onAuthChanged);
    widget.refreshNotifier?.addListener(_onRefreshNotified);
    _fetchOrders();
  }

  @override
  void dispose() {
    AuthState.instance.removeListener(_onAuthChanged);
    widget.refreshNotifier?.removeListener(_onRefreshNotified);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefreshNotified() {
    if (widget.refreshNotifier?.value == 2) {
      _fetchOrders();
      widget.onBadgeUpdateNeeded?.call();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    
    final newUserId = AuthState.instance.user?['id'];
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      if (newUserId == null) {
        // Logged out
        setState(() {
          _allOrders = [];
          _error = null;
        });
      } else {
        // Logged in as new user
        _fetchOrders();
      }
    }
  }
  
  void _fetchOrders() async {
    if (!AuthState.instance.isLoggedIn) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await OrderService().getMyOrders();
      if (mounted) {
        setState(() {
          _allOrders = orders;
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

  List<OrderModel> get _filteredOrders {
    return _allOrders.where((order) {
      // Filter by status
      if (_selectedStatus != 'Semua') {
        if (_selectedStatus == 'Dibatalkan' && (order.orderStatus == 'Dibatalkan' || order.orderStatus == 'Ditolak')) {
          // Pass
        } else if (order.orderStatus != _selectedStatus) {
          return false;
        }
      }
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return order.orderCode.toLowerCase().contains(query) ||
            order.fleetName.toLowerCase().contains(query) ||
            order.origin.toLowerCase().contains(query) ||
            order.destination.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  void _resetFilter() {
    setState(() {
      _selectedStatus = 'Semua';
      _searchQuery = '';
    });
  }

  Future<void> _handleArchiveOrder(int orderId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryNavy)),
        content: const Text('Pesanan ini akan disembunyikan dari daftar utama, tetapi tetap tersimpan sebagai riwayat.'),
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Call service
      await OrderService().archiveOrder(orderId);
      
      // Remove from list locally
      if (mounted) {
        setState(() {
          _allOrders.removeWhere((o) => o.id == orderId);
        });
        AppSnackBar.showSuccess(context, 'Pesanan berhasil diarsipkan');
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
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AuthState.instance,
          builder: (context, _) {
            if (!AuthState.instance.isLoggedIn) {
              return const LoginRequiredView();
            }

            final filteredOrders = _filteredOrders;
            
            final totalPesanan = _allOrders.length;
            final pesananAktif = _allOrders.where((o) => o.orderStatus == 'Diterima' || o.orderStatus == 'Dalam Perjalanan').length;
            final menungguKonfirmasi = _allOrders.where((o) => o.orderStatus == 'Menunggu Konfirmasi').length;

            return RefreshIndicator(
              onRefresh: () async {
                _fetchOrders();
              },
              color: AppColors.primaryNavy,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PesananHeader(
                      onArchiveTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const mobile_archived.ArchivedOrdersPage(),
                          ),
                        );
                        // Refresh when coming back
                        _fetchOrders();
                      },
                    ),
                    PesananSearchBar(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    PesananFilterChips(
                      statuses: statuses,
                      selectedStatus: _selectedStatus,
                      onSelected: (status) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    PesananSummaryCards(
                      totalPesanan: totalPesanan,
                      pesananAktif: pesananAktif,
                      menungguKonfirmasi: menungguKonfirmasi,
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.primaryNavy),
                        ),
                      )
                    else if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Gagal memuat pesanan', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchOrders,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (filteredOrders.isEmpty)
                      PesananEmptyState(onReset: _resetFilter)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          return PesananCard(
                            pesanan: filteredOrders[index],
                            onRefresh: _fetchOrders,
                            onArchive: () => _handleArchiveOrder(filteredOrders[index].id),
                          );
                        },
                      ),
                      
                    // Add padding at bottom so navbar doesn't cover the last item
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
