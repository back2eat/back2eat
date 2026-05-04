import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../bookings/presentation/bloc/booking_bloc.dart';

/// Step 1 of Table Booking:
/// Customer pays ₹19 FIRST, then booking is created automatically.
/// After restaurant confirms → customer gets notification → goes to checkout.
class BookingPrePaymentPage extends StatefulWidget {
  final String restaurantId;
  final String branchId;

  const BookingPrePaymentPage({
    super.key,
    required this.restaurantId,
    required this.branchId,
  });

  @override
  State<BookingPrePaymentPage> createState() => _BookingPrePaymentPageState();
}

class _BookingPrePaymentPageState extends State<BookingPrePaymentPage> {
  // Guest & time state
  int     _guestCount   = 1;
  String? _selectedTime;
  late List<String> _timeSlots;

  // Payment state
  String  _selectedMethod = 'UPI';
  bool    _paying         = false;
  bool    _paid           = false;
  String? _error;

  final _methods = [
    ('UPI',         Icons.account_balance_wallet_outlined, 'Pay via UPI'),
    ('CARD',        Icons.credit_card_outlined,            'Credit / Debit Card'),
    ('NET_BANKING', Icons.account_balance_outlined,        'Net Banking'),
  ];

  @override
  void initState() {
    super.initState();
    _timeSlots = _buildTimeSlots();
  }

  List<String> _buildTimeSlots() {
    final now    = DateTime.now();
    final buffer = now.add(const Duration(minutes: 30));
    var m = ((buffer.minute / 15).ceil() * 15) % 60;
    var h = buffer.minute >= 45 ? buffer.hour + 1 : buffer.hour;
    final slots = <String>[];
    while (h < 22 || (h == 22 && m == 0)) {
      final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      final ampm   = h >= 12 ? 'PM' : 'AM';
      final minStr = m.toString().padLeft(2, '0');
      slots.add('${h12.toString().padLeft(2, '0')}:$minStr $ampm');
      m += 15;
      if (m >= 60) { m = 0; h++; }
    }
    if (!slots.contains('10:00 PM')) slots.add('10:00 PM');
    return slots;
  }

  Future<void> _payAndBook() async {
    if (_selectedTime == null) {
      setState(() => _error = 'Please select a time slot');
      return;
    }
    setState(() { _paying = true; _error = null; });

    try {
      // ── MOCK payment: create a dummy payment order for ₹19 ──────────────
      // In production: open Razorpay SDK here with the razorpayOrderId

      // Simulate payment processing
      await Future.delayed(const Duration(milliseconds: 1500));

      // ── Create booking after payment success ─────────────────────────────
      if (!mounted) return;
      context.read<BookingBloc>().add(CreateBookingEvent(
        restaurantId:    widget.restaurantId,
        branchId:        widget.branchId,
        guestCount:      _guestCount,
        bookingDate:     DateTime.now(),
        timeSlot:        _selectedTime!,
        specialRequests: null,
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error  = e.toString().replaceAll('Exception: ', '');
          _paying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingBloc>(),
      child: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            setState(() { _paid = true; _paying = false; });
          }
          if (state is BookingError) {
            setState(() { _error = state.message; _paying = false; });
          }
        },
        child: _paid
            ? _SuccessView(onDone: () => context.go('/bookings'))
            : _buildPaymentUI(),
      ),
    );
  }

  Widget _buildPaymentUI() {
    final needsTimeSlot = _selectedTime == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Reserve Your Table'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Amount card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE53935)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(children: [
                Icon(Icons.event_seat_rounded,
                    color: Colors.white.withOpacity(0.9), size: 36.sp),
                SizedBox(height: 10.h),
                Text('Table Booking Fee',
                    style: TextStyle(fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700)),
                SizedBox(height: 6.h),
                Text('₹19.00',
                    style: TextStyle(fontSize: 36.sp, color: Colors.white, fontWeight: FontWeight.w900)),
                SizedBox(height: 4.h),
                Text('Refundable if restaurant cancels · Non-refundable if you cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.sp,
                        color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600)),
              ]),
            ),

            SizedBox(height: 20.h),

            // ── Time Slot ────────────────────────────────────────────────
            Text('Preferred Time Slot',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('When would you like to arrive?',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
                SizedBox(height: 12.h),
                _timeSlots.isEmpty
                    ? Text('No slots available today',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.danger, fontWeight: FontWeight.w700))
                    : SizedBox(
                  height: 40.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _timeSlots.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, i) {
                      final slot     = _timeSlots[i];
                      final selected = _selectedTime == slot;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.soft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(slot,
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800,
                                  color: selected ? Colors.white : AppColors.text)),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedTime != null) ...[
                  SizedBox(height: 10.h),
                  Row(children: [
                    Icon(Icons.check_circle_rounded, size: 14.sp, color: AppColors.success),
                    SizedBox(width: 4.w),
                    Text('Selected: $_selectedTime',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.success, fontWeight: FontWeight.w800)),
                  ]),
                ],
              ]),
            ),

            SizedBox(height: 16.h),

            // ── Guest Count ──────────────────────────────────────────────
            Text('Number of Guests',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () { if (_guestCount > 1) setState(() => _guestCount--); },
                  child: Container(
                    width: 40.w, height: 40.w,
                    decoration: BoxDecoration(
                      color: _guestCount > 1 ? AppColors.primary : AppColors.soft,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.remove,
                        color: _guestCount > 1 ? Colors.white : AppColors.muted, size: 20.sp),
                  ),
                ),
                SizedBox(width: 28.w),
                Column(children: [
                  Text('$_guestCount',
                      style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900)),
                  Text(_guestCount == 1 ? 'person' : 'people',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ]),
                SizedBox(width: 28.w),
                GestureDetector(
                  onTap: () { if (_guestCount < 20) setState(() => _guestCount++); },
                  child: Container(
                    width: 40.w, height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary, borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 20.sp),
                  ),
                ),
              ]),
            ),

            SizedBox(height: 20.h),

            // ── Payment Method ───────────────────────────────────────────
            Text('Payment Method',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 10.h),

            ..._methods.map((m) {
              final selected = _selectedMethod == m.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = m.$1),
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.black.withOpacity(0.06),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(m.$2, color: selected ? AppColors.primary : AppColors.muted, size: 22.sp),
                    SizedBox(width: 12.w),
                    Expanded(child: Text(m.$3,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700))),
                    if (selected)
                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20.sp),
                  ]),
                ),
              );
            }),

            // ── Error ────────────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                    color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(10.r)),
                child: Row(children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(_error!,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.danger, fontWeight: FontWeight.w700))),
                ]),
              ),
              SizedBox(height: 12.h),
            ],

            // ── Info box ─────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.infoSoft, borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(child: Text(
                  'After paying, your table request is sent to the restaurant. '
                      'Once confirmed, you\'ll get a notification to place your food order.',
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.info,
                      fontWeight: FontWeight.w600, height: 1.4),
                )),
              ]),
            ),

            SizedBox(height: 28.h),

            // ── Pay Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52.h,
              child: ElevatedButton(
                onPressed: (_paying || needsTimeSlot) ? null : _payAndBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                ),
                child: _paying
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 20.w, height: 20.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                  SizedBox(width: 12.w),
                  Text('Processing...', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
                ])
                    : Text(
                    needsTimeSlot ? 'Select a time slot first' : 'Pay ₹19 & Request Table',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
              ),
            ),

            SizedBox(height: 12.h),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text('Cancel',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100.w, height: 100.w,
              decoration: BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: AppColors.success, size: 52.sp),
            ),
            SizedBox(height: 24.h),
            Text('Booking Request Sent!',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
            SizedBox(height: 10.h),
            Text(
              'Your ₹19 payment is confirmed and the restaurant has been notified. '
                  'Once they confirm your table, you\'ll receive a notification to place your food order.',
              style: TextStyle(fontSize: 14.sp, color: AppColors.muted,
                  fontWeight: FontWeight.w600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 36.h),
            SizedBox(
              width: double.infinity, height: 52.h,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text('View My Bookings',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}