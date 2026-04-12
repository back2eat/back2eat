import '../entities/booking.dart';

abstract class BookingRepository {
  Future<BookingEntity> createBooking({
    required String restaurantId,
    required String branchId,
    required int guestCount,
    required DateTime bookingDate,
    required String timeSlot,
    String? tableId,
    String? specialRequests,
  });

  Future<List<BookingEntity>> getMyBookings();

  Future<void> cancelBooking(String bookingId);
}