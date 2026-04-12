import '../entities/order.dart';

abstract class OrderRepository {
  Future<OrderEntity> placeOrder({
    required String restaurantId,
    required String branchId,
    required String orderType,
    required List<Map<String, dynamic>> items,
    String? tableId,
    String? specialInstructions,
    String  paymentMethod = 'UPI',
    String? scheduledTime,
    int?    guestCount,
    String? couponCode,
    int?    pointsRedeemed,
    double? subtotal,
    double? commissionAmount,
    double? bookingFee,
    double? totalAmount,
  });

  Future<List<OrderEntity>> getMyOrders({int page = 1});

  Future<OrderEntity> getOrderById(String orderId);

  Future<OrderEntity> cancelOrder({
    required String orderId,
    String? reason,
  });
}