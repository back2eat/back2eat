import '../../../../core/network/api_client.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ApiClient _api;
  BookingRepositoryImpl(this._api);

  BookingEntity _fromJson(Map<String, dynamic> j) {
    // restaurantId can be a string or populated object
    final rest = j['restaurantId'];
    final restaurantId = rest is Map
        ? rest['_id'] as String? ?? ''
        : rest as String? ?? '';
    final restaurantName = rest is Map
        ? (rest['name'] as String?)
        : null;

    // tableId can be string or populated object
    final table = j['tableId'];
    final tableId   = table is Map ? table['_id']  as String? : table as String?;
    final tableName = table is Map ? table['name'] as String? : null;

    // orderId can be string or populated object
    final order = j['orderId'];
    final orderId       = order is Map ? order['_id']           as String? : order as String?;
    final paymentStatus = order is Map ? order['paymentStatus'] as String? : null;

    return BookingEntity(
      id:             j['_id']             as String,
      restaurantId:   restaurantId,
      restaurantName: restaurantName,
      branchId:       j['branchId']        as String?,
      guestCount:     (j['guestCount']     as num?)?.toInt() ?? 1,
      bookingDate:    DateTime.parse(j['bookingDate'] as String),
      timeSlot:       j['startTime']       as String? ??
          j['timeSlot']        as String? ?? '',
      tableId:        tableId,
      tableName:      tableName,
      specialRequests:j['specialRequests'] as String?,
      status:         j['status']          as String? ?? 'PENDING',
      paymentStatus:  paymentStatus,
      orderId:        orderId,
    );
  }

  @override
  Future<BookingEntity> createBooking({
    required String restaurantId,
    required String branchId,
    required int guestCount,
    required DateTime bookingDate,
    required String timeSlot,
    String? tableId,
    String? specialRequests,
  }) async {
    final data = await _api.post('/bookings', {
      'restaurantId': restaurantId,
      'branchId':     branchId,
      'guestCount':   guestCount,
      'bookingDate':  bookingDate.toIso8601String(),
      'timeSlot':     timeSlot,
      if (tableId         != null) 'tableId':         tableId,
      if (specialRequests != null) 'specialRequests': specialRequests,
    });
    return _fromJson(data['booking'] as Map<String, dynamic>);
  }

  @override
  Future<List<BookingEntity>> getMyBookings() async {
    // Backend: GET /bookings/my — returns { bookings: [...] }
    // Each booking is populated with restaurantId, tableId, orderId
    final data = await _api.get('/bookings/my?populate=restaurantId,tableId,orderId');
    final list = data['bookings'] as List<dynamic>? ?? [];
    return list
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _api.patch('/bookings/my/$bookingId/cancel', {});
  }
}