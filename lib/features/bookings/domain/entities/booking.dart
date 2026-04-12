class BookingEntity {
  final String   id;
  final String   restaurantId;
  final String?  restaurantName;
  final String?  branchId;
  final int      guestCount;
  final DateTime bookingDate;
  final String   timeSlot;
  final String?  tableId;
  final String?  tableName;
  final String?  specialRequests;
  final String   status;          // PENDING | CONFIRMED | CANCELLED | COMPLETED
  final String?  paymentStatus;   // PENDING | PAID — for TABLE_BOOKING orders
  final String?  orderId;         // linked order _id for payment

  const BookingEntity({
    required this.id,
    required this.restaurantId,
    this.restaurantName,
    this.branchId,
    required this.guestCount,
    required this.bookingDate,
    required this.timeSlot,
    this.tableId,
    this.tableName,
    this.specialRequests,
    required this.status,
    this.paymentStatus,
    this.orderId,
  });

  /// True when the restaurant has confirmed but the ₹19 fee hasn't been paid yet
  bool get needsPayment =>
      status == 'CONFIRMED' && paymentStatus == 'PENDING';
}