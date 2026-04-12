import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiClient    _api;
  final TokenStorage _storage;

  OrderRepositoryImpl(this._api, this._storage);

  @override
  Future<OrderEntity> placeOrder({
    required String restaurantId,
    required String branchId,
    required String orderType,
    required List<Map<String, dynamic>> items,
    String? tableId,
    String? specialInstructions,
    String  paymentMethod    = 'UPI',
    String? scheduledTime,
    int?    guestCount,
    String? couponCode,
    int?    pointsRedeemed,
    double? subtotal,
    double? commissionAmount,
    double? bookingFee,
    double? totalAmount,
  }) async {
    double sub = subtotal ?? 0;
    if (sub == 0) {
      for (final item in items) {
        sub += ((item['price'] as num?)?.toDouble() ?? 0) *
            ((item['quantity'] as num?)?.toInt() ?? 1);
      }
    }

    final commission = commissionAmount ?? double.parse((sub * 2 / 100).toStringAsFixed(2));
    final bFee       = bookingFee       ?? 0.0;
    final total      = totalAmount      ?? double.parse((sub + commission + bFee).toStringAsFixed(2));

    final body = <String, dynamic>{
      'branchId':         branchId,
      'orderType':        orderType,
      'items':            items,
      'subtotal':         sub,
      'taxAmount':        0,
      'taxPercent':       0,
      'commissionAmount': commission,
      'bookingFee':       bFee,
      'totalAmount':      total,
      'paymentMethod':    paymentMethod,
      if (tableId             != null) 'tableId':             tableId,
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      if (scheduledTime       != null) 'scheduledTime':       scheduledTime,
      if (guestCount         != null) 'guestCount':          guestCount,
      if (couponCode        != null) 'couponCode':          couponCode,
      if (pointsRedeemed    != null && pointsRedeemed > 0) 'pointsRedeemed': pointsRedeemed,
    };

    final data = await _api.post('/orders', body, restaurantId: restaurantId);
    return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
  }

  @override
  Future<List<OrderEntity>> getMyOrders({int page = 1}) async {
    final data = await _api.get('/orders/my?page=$page&limit=20');
    final list = data['orders'] as List<dynamic>? ?? [];
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderEntity> getOrderById(String orderId) async {
    final data = await _api.get('/orders/my/$orderId');
    // Merge luckyTicket into the order JSON so OrderModel.fromJson can parse it
    final orderJson = Map<String, dynamic>.from(data['order'] as Map<String, dynamic>);
    if (data['luckyTicket'] != null) {
      orderJson['luckyTicket'] = data['luckyTicket'];
    }
    return OrderModel.fromJson(orderJson);
  }

  @override
  Future<OrderEntity> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      if (reason != null) 'reason': reason,
    };
    final data = await _api.patch('/orders/my/$orderId/cancel', body);
    return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
  }
}