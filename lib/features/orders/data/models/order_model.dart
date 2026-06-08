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
    // ── Items ──────────────────────────────────────────────────────────────
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      return OrderItem(
        menuItemId: m['menuItemId'] as String? ?? m['_id'] as String? ?? '',
        name:       m['name']       as String? ?? '',
        quantity:   (m['quantity']  as num?)?.toInt()    ?? 1,
        price:      (m['price']     as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    // ── Restaurant — may be populated object or raw string ID ──────────────
    final restaurant     = json['restaurantId'];
    final restaurantId   = restaurant is Map
        ? (restaurant['_id']  as String? ?? '')
        : (restaurant          as String? ?? '');
    final restaurantName = restaurant is Map
        ? (restaurant['name'] as String? ?? '')
        : (json['restaurantName'] as String? ?? '');

    // ── Branch — may be populated object or raw string ID ─────────────────
    final branch        = json['branchId'];
    final branchName    = branch is Map ? branch['name']      as String? : null;
    final branchAddress = branch is Map ? branch['address']   as String? : null;
    final branchPhone   = branch is Map ? branch['phone']     as String? : null;
    final branchLat     = branch is Map ? (branch['latitude']  as num?)?.toDouble() : null;
    final branchLng     = branch is Map ? (branch['longitude'] as num?)?.toDouble() : null;

    // ── Status — safe fallback ─────────────────────────────────────────────
    // paymentStatus FOOD_PAID means order is active (CREATED/ACCEPTED)
    // Use paymentStatus to derive a display status for TABLE_BOOKING orders
    final rawStatus      = json['status']        as String? ?? 'CREATED';
    final paymentStatus  = json['paymentStatus'] as String? ?? '';
    final orderType      = json['orderType']     as String? ?? 'TAKEAWAY';

    // For TABLE_BOOKING with FOOD_PAID, treat as CREATED so tracking shows correctly
    final status = (orderType == 'TABLE_BOOKING' && paymentStatus == 'FOOD_PAID' && rawStatus == 'CREATED')
        ? 'CREATED'
        : rawStatus;

    // ── Lucky ticket ───────────────────────────────────────────────────────
    final lucky = json['luckyTicket'] as Map?;

    return OrderModel(
      id:                  json['_id']          as String? ?? '',
      orderNumber:         json['orderNumber']  as String? ?? '',
      restaurantId:        restaurantId,
      restaurantName:      restaurantName,
      status:              status,
      orderType:           orderType,
      totalAmount:         (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items:               items,
      createdAt:           DateTime.tryParse(json['createdAt'] as String? ?? '')
          ?? DateTime.now(),
      tableId:             json['tableId']              as String?,
      specialInstructions: json['specialInstructions']  as String?,
      branchLatitude:      branchLat,
      branchLongitude:     branchLng,
      branchAddress:       branchAddress,
      branchName:          branchName,
      branchPhone:         branchPhone,
      scheduledTime:       json['scheduledTime']  as String?,
      guestCount:          (json['guestCount']    as num?)?.toInt(),
      couponCode:          json['couponCode']     as String?,
      discountAmount:      (json['discount']      as num?)?.toDouble(),
      luckyTicketNumber:   lucky?['ticketNumber'] as String?,
      luckyDrawTitle:      lucky?['drawTitle']    as String?,
      luckyPrize:          lucky?['prize']        as String?,
      luckyIsWinner:       (lucky?['isWinner']    as bool?) ?? false,
    );
  }
}