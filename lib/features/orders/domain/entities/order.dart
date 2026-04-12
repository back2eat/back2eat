class OrderItem {
  final String menuItemId;
  final String name;
  final int    quantity;
  final double price;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class OrderEntity {
  final String  id;
  final String  orderNumber;
  final String  restaurantId;
  final String  restaurantName;
  final String  status;
  final String  orderType;
  final double  totalAmount;
  final List<OrderItem> items;
  final DateTime createdAt;
  final String? tableId;
  final String? specialInstructions;

  // Branch location — used for "Reach to Restaurant" map button
  final double? branchLatitude;
  final double? branchLongitude;
  final String? branchAddress;
  final String? branchName;
  final String? branchPhone;  // branch contact number for call button

  // Scheduled time slot e.g. "02:30 PM"
  final String? scheduledTime;

  // Number of guests (for DINE_IN and TABLE_BOOKING)
  final int? guestCount;

  // Coupon
  final String? couponCode;
  final double? discountAmount;

  // Lucky draw ticket issued for this order
  final String? luckyTicketNumber;
  final String? luckyDrawTitle;
  final String? luckyPrize;
  final bool    luckyIsWinner;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.restaurantId,
    required this.restaurantName,
    required this.status,
    required this.orderType,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
    this.tableId,
    this.specialInstructions,
    this.branchLatitude,
    this.branchLongitude,
    this.branchAddress,
    this.branchName,
    this.branchPhone,
    this.scheduledTime,
    this.guestCount,
    this.couponCode,
    this.discountAmount,
    this.luckyTicketNumber,
    this.luckyDrawTitle,
    this.luckyPrize,
    this.luckyIsWinner = false,
  });
}