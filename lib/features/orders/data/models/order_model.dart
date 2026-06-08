// 📱 CUSTOMER APP
// lib/features/orders/data/models/order_model.dart

import '../../domain/entities/order.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.restaurantId,
    required super.restaurantName,
    required super.status,
    required super.orderType,
    required super.totalAmount,
    required super.items,
    required super.createdAt,
    super.tableId,
    super.specialInstructions,
    super.branchLatitude,
    super.branchLongitude,
    super.branchAddress,
    super.branchName,
    super.branchPhone,
    super.scheduledTime,
    super.guestCount,
    super.couponCode,
    super.discountAmount,
    super.luckyTicketNumber,
    super.luckyDrawTitle,
    super.luckyPrize,
    super.luckyIsWinner,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // ── Items — every field null-safe, no hard casts ───────────────────────
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{};
      // menuItemId may be an ObjectId string or a nested populated object
      final mid = m['menuItemId'];
      final menuItemId = mid is Map
          ? (mid['_id']?.toString() ?? '')
          : (mid?.toString() ?? m['_id']?.toString() ?? '');
      return OrderItem(
        menuItemId: menuItemId,
        name:       m['name']?.toString()                       ?? '',
        quantity:   (m['quantity'] as num?)?.toInt()            ?? 1,
        price:      (m['price']    as num?)?.toDouble()         ?? 0.0,
      );
    }).toList();

    // ── Restaurant — may be populated object or raw string ─────────────────
    final restaurant = json['restaurantId'];
    final restaurantId = restaurant is Map
        ? (restaurant['_id']?.toString()  ?? '')
        : (restaurant?.toString()         ?? '');
    final restaurantName = restaurant is Map
        ? (restaurant['name']?.toString() ?? '')
        : (json['restaurantName']?.toString() ?? '');

    // ── Branch — may be populated object or raw string ─────────────────────
    final branch        = json['branchId'];
    final branchName    = branch is Map ? branch['name']?.toString()    : null;
    final branchAddress = branch is Map ? branch['address']?.toString() : null;
    final branchPhone   = branch is Map ? branch['phone']?.toString()   : null;
    final branchLat     = branch is Map ? (branch['latitude']  as num?)?.toDouble() : null;
    final branchLng     = branch is Map ? (branch['longitude'] as num?)?.toDouble() : null;

    // ── Status — safe fallback ─────────────────────────────────────────────
    final rawStatus     = json['status']?.toString()        ?? 'CREATED';
    final paymentStatus = json['paymentStatus']?.toString() ?? '';
    final orderType     = json['orderType']?.toString()     ?? 'TAKEAWAY';

    // TABLE_BOOKING with FOOD_PAID → order is live, treat as CREATED so
    // tracking page shows the live progress stepper
    final status = (orderType == 'TABLE_BOOKING' &&
        paymentStatus == 'FOOD_PAID' &&
        rawStatus == 'CREATED')
        ? 'CREATED'
        : rawStatus;

    // ── tableId — may be populated object ─────────────────────────────────
    final tableRaw = json['tableId'];
    final tableId  = tableRaw is Map
        ? tableRaw['_id']?.toString()
        : tableRaw?.toString();

    // ── Lucky ticket ───────────────────────────────────────────────────────
    final lucky = json['luckyTicket'] as Map?;

    return OrderModel(
      id:           json['_id']?.toString()         ?? '',
      orderNumber:  json['orderNumber']?.toString() ?? '',
      restaurantId:  restaurantId,
      restaurantName: restaurantName,
      status:        status,
      orderType:     orderType,
      totalAmount:   (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items:         items,
      createdAt:     DateTime.tryParse(json['createdAt']?.toString() ?? '')
          ?? DateTime.now(),
      tableId:             tableId,
      specialInstructions: json['specialInstructions']?.toString(),
      branchLatitude:      branchLat,
      branchLongitude:     branchLng,
      branchAddress:       branchAddress,
      branchName:          branchName,
      branchPhone:         branchPhone,
      scheduledTime:       json['scheduledTime']?.toString(),
      guestCount:          (json['guestCount'] as num?)?.toInt(),
      couponCode:          json['couponCode']?.toString(),
      discountAmount:      (json['discount']   as num?)?.toDouble(),
      luckyTicketNumber:   lucky?['ticketNumber']?.toString(),
      luckyDrawTitle:      lucky?['drawTitle']?.toString(),
      luckyPrize:          lucky?['prize']?.toString(),
      luckyIsWinner:       (lucky?['isWinner'] as bool?) ?? false,
    );
  }
}