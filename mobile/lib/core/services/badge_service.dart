import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/services/order_service.dart';
import 'package:mobile/features/pesanan/models/order_model.dart';
import 'package:mobile/core/auth/auth_state.dart';

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();

  factory BadgeService() {
    return _instance;
  }

  BadgeService._internal();

  // Define statuses that require attention
  bool _requiresAttention(OrderModel order) {
    final os = order.orderStatus;
    final ps = order.paymentStatus;
    
    // DP or Settlement logic
    if (ps == 'Belum Membayar' && order.totalPrice != null) return true;
    if (ps == 'DP Diterima') return true;
    if (ps == 'Ditolak') return true;
    if (ps == 'Lunas') return true;
    
    // Order logic
    if (os == 'Selesai') return true;
    if (os == 'Dibatalkan') return true;
    if (os == 'Ditolak') return true;
    
    // For trucks where price is sent (totalPrice is not null but paymentStatus is Belum Membayar)
    if (order.isTruckOrder && order.totalPrice != null && ps == 'Belum Membayar') return true;
    
    return false;
  }

  Future<int> getUnreadCount() async {
    try {
      final isLoggedIn = AuthState.instance.isLoggedIn;
      if (!isLoggedIn) return 0; // Not logged in

      final orders = await OrderService().getMyOrders();
      final prefs = await SharedPreferences.getInstance();
      
      int count = 0;
      
      for (var order in orders) {
        if (_requiresAttention(order)) {
          // Generate a unique key based on both order ID and its current significant status combination
          // This way, if status changes, it becomes unread again.
          final key = 'read_order_${order.id}_${order.orderStatus}_${order.paymentStatus}';
          if (!prefs.containsKey(key)) {
            count++;
          }
        }
      }
      
      return count;
    } catch (e) {
      return 0; // Silently fail and return 0 for badges
    }
  }

  Future<void> markAsRead(int orderId, String orderStatus, String paymentStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'read_order_${orderId}_${orderStatus}_$paymentStatus';
      await prefs.setBool(key, true);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> clearUserBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('read_order_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Ignore
    }
  }
}
