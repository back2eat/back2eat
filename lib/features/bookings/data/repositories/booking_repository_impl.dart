import '../../../../core/network/api_client.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ApiClient _api;
  BookingRepositoryImpl(this._api);

  BookingEntity _fromJson(Map<String, dynamic> j) {
    // restaurantId
    final rest = j['restaurantId'];
    final restaurantId   = rest is Map ? rest['_id']  as String? ?? '' : rest as String? ?? '';
    final restaurantName = rest is Map ? rest['name'] as String? : null;

    // tableId
    final table = j['tableId'];
    final tableId   = table is Map ? table['_id']  as String? : table as String?;
    final tableName = table is Map ? table['name'] as String? : null;

    // branchId — can be populated Map or plain String
    final branch   = j['branchId'];
    final branchId = branch is Map ? branch['_id'] as String? : branch as String?;

    // orderId
    final order = j['orderId'];
    final orderId       = order is Map ? order['_id']           as String? : order as String?;
    final paymentStatus = order is Map ? order['paymentStatus'] as String? : null;

    final startTime = j['startTime'] as String? ?? '';
    final endTime   = j['endTime']   as String? ?? '';
    final timeSlot  = endTime.isNotEmpty ? '$startTime – $endTime' : startTime;

    return BookingEntity(
      id:              j['_id']             as String,
      restaurantId:    restaurantId,
      restaurantName:  restaurantName,
      branchId:        branchId,
      guestCount:      (j['guestCount']     as num?)?.toInt() ?? 1,
      bookingDate:     DateTime.parse(j['bookingDate'] as String),
      timeSlot:        timeSlot,
      tableId:         tableId,
      tableName:       tableName,
      specialRequests: j['specialRequests'] as String?,
      status:          j['status']          as String? ?? 'BOOKED',
      paymentStatus:   paymentStatus,
      orderId:         orderId,
    );
  }
  @override
  Future<BookingEntity> createBooking({
    required String   restaurantId,
    required String   branchId,
    required int      guestCount,
    required DateTime bookingDate,
    required String   timeSlot,
    String? tableId,
    String? specialRequests,
  }) async {
    // Parse timeSlot "HH:MM AM/PM" → 24h startTime, derive endTime +1h
    final startTime = _to24h(timeSlot);
    final endTime   = _addHour(startTime);

    final data = await _api.post('/bookings', {
      'restaurantId':    restaurantId,
      'branchId':        branchId,
      'guestCount':      guestCount,
      'bookingDate':     bookingDate.toIso8601String(),
      'startTime':       startTime,
      'endTime':         endTime,
      if (tableId         != null) 'tableId':         tableId,
      if (specialRequests != null) 'specialRequests': specialRequests,
    });
    return _fromJson(data['booking'] as Map<String, dynamic>);
  }

  @override
  Future<List<BookingEntity>> getMyBookings() async {
    final data = await _api.get('/bookings/my');
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Convert "02:30 PM" → "14:30"
  String _to24h(String slot) {
    try {
      final parts  = slot.trim().split(' ');
      final time   = parts[0].split(':');
      final ampm   = parts[1].toUpperCase();
      int hour     = int.parse(time[0]);
      final minute = time[1];
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour  = 0;
      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (_) {
      return slot;
    }
  }

  /// Add 1 hour to "14:30" → "15:30"
  String _addHour(String time24) {
    try {
      final parts  = time24.split(':');
      int hour     = int.parse(parts[0]) + 1;
      if (hour > 23) hour = 23;
      return '${hour.toString().padLeft(2, '0')}:${parts[1]}';
    } catch (_) {
      return time24;
    }
  }
}