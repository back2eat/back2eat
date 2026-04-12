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
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      return OrderItem(
        menuItemId: m['menuItemId'] as String? ?? '',
        name:       m['name']       as String? ?? '',
        quantity:   (m['quantity']  as num?)?.toInt()    ?? 1,
        price:      (m['price']     as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    // Restaurant
    final restaurant     = json['restaurantId'];
    final restaurantId   = restaurant is Map
        ? restaurant['_id']  as String? ?? ''
        : restaurant          as String? ?? '';
    final restaurantName = restaurant is Map
        ? restaurant['name'] as String? ?? ''
        : '';

    // Branch — populated by backend as branchId object
    final branch        = json['branchId'];
    final branchName    = branch is Map ? branch['name']    as String? : null;
    final branchAddress = branch is Map ? branch['address'] as String? : null;
    final branchPhone   = branch is Map ? branch['phone']   as String? : null;
    final branchLat     = branch is Map ? (branch['latitude']  as num?)?.toDouble() : null;
    final branchLng     = branch is Map ? (branch['longitude'] as num?)?.toDouble() : null;

    return OrderModel(
      id:                 json['_id']         as String,
      orderNumber:        json['orderNumber'] as String? ?? '',
      restaurantId:       restaurantId,
      restaurantName:     restaurantName,
      status:             json['status']      as String,
      orderType:          json['orderType']   as String? ?? 'TAKEAWAY',
      totalAmount:        (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items:              items,
      createdAt:          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      tableId:            json['tableId']             as String?,
      specialInstructions: json['specialInstructions'] as String?,
      branchLatitude:     branchLat,
      branchLongitude:    branchLng,
      branchAddress:      branchAddress,
      branchName:         branchName,
      branchPhone:        branchPhone,
      scheduledTime:      json['scheduledTime'] as String?,
      guestCount:         (json['guestCount']    as num?)?.toInt(),
      couponCode:         json['couponCode']     as String?,
      discountAmount:     (json['discount']      as num?)?.toDouble(),
      // luckyTicket is nested under 'luckyTicket' key in the order response
      luckyTicketNumber:  (json['luckyTicket'] as Map?)?['ticketNumber'] as String?,
      luckyDrawTitle:     (json['luckyTicket'] as Map?)?['drawTitle']    as String?,
      luckyPrize:         (json['luckyTicket'] as Map?)?['prize']        as String?,
      luckyIsWinner:      ((json['luckyTicket'] as Map?)?['isWinner']    as bool?) ?? false,
    );
  }
}