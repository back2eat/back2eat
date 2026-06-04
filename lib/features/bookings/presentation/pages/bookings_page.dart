// 📱 CUSTOMER APP
// lib/features/bookings/presentation/pages/bookings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../bloc/booking_bloc.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});
  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late Razorpay _razorpay;
  String? _pendingFoodOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onFoodPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onFoodPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _payForFood(BookingEntity booking) async {
    final orderId = booking.orderId;
    if (orderId == null || orderId.isEmpty) return;
    _pendingFoodOrderId = orderId;

    try {
      final payRes = await getIt<ApiClient>().post(
        '/payments/create-food-order',
        {'bookingId': booking.id},
      );

      final razorpayOrderId = payRes['razorpayOrderId'] as String;
      final amountInPaise   = payRes['amount']          as int;
      final keyId           = payRes['keyId']           as String;

      _razorpay.open({
        'key':         keyId,
        'amount':      amountInPaise,
        'order_id':    razorpayOrderId,
        'name':        'Back2Eat',
        'description': 'Food Order — ${booking.restaurantName ?? ""}',
        'theme':       {'color': '#D01008'},
        'retry':       {'enabled': false},
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception:', '').trim()),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _onFoodPaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted || _pendingFoodOrderId == null) return;
    try {
      await getIt<ApiClient>().post('/payments/verify', {
        'orderId':           _pendingFoodOrderId!,
        'razorpayOrderId':   response.orderId   ?? '',
        'razorpayPaymentId': response.paymentId ?? '',
        'razorpaySignature': response.signature ?? '',
      });

      if (!mounted) return;

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment successful! Your food order is being prepared.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));

      // Reload bookings to reflect FOOD_PAID status
      context.read<BookingBloc>().add(const LoadMyBookingsEvent());

      // Navigate to order tracking after short delay so snackbar shows
      final orderId = _pendingFoodOrderId!;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.push('/order-tracking', extra: orderId);
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment done but confirmation failed. Contact support.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _onFoodPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.message ?? 'Payment failed. Please try again.'),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingBloc>()..add(const LoadMyBookingsEvent()),
      child: _BookingsView(onPayForFood: _payForFood),
    );
  }
}

class _BookingsView extends StatelessWidget {
  final void Function(BookingEntity) onPayForFood;
  const _BookingsView({required this.onPayForFood});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<BookingBloc>().add(const LoadMyBookingsEvent()),
          ),
        ],
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Booking cancelled. Refund will be processed in 5-7 days.'),
              backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
            ));
            context.read<BookingBloc>().add(const LoadMyBookingsEvent());
          }
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) return const Center(child: CircularProgressIndicator());

          if (state is BookingsLoaded) {
            if (state.bookings.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.event_seat_outlined, size: 64.r, color: AppColors.muted),
                SizedBox(height: 12.h),
                Text('No bookings yet',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 6.h),
                Text('Book a table from any restaurant page',
                    style: TextStyle(fontSize: 13.sp,
                        color: AppColors.muted, fontWeight: FontWeight.w600)),
              ]));
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<BookingBloc>().add(const LoadMyBookingsEvent()),
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: state.bookings.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (ctx, i) => _BookingCard(
                  booking:     state.bookings[i],
                  onPayForFood: () => onPayForFood(state.bookings[i]),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback  onPayForFood;
  const _BookingCard({required this.booking, required this.onPayForFood});

  Color get _statusColor {
    switch (booking.status) {
      case 'CONFIRMED': return AppColors.success;
      case 'CANCELLED': return AppColors.danger;
      case 'COMPLETED': return AppColors.info;
      default:          return AppColors.warning;
    }
  }

  Color get _statusBg {
    switch (booking.status) {
      case 'CONFIRMED': return AppColors.successSoft;
      case 'CANCELLED': return AppColors.dangerSoft;
      case 'COMPLETED': return AppColors.infoSoft;
      default:          return AppColors.warningSoft;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case 'CONFIRMED': return 'Confirmed';
      case 'CANCELLED': return 'Cancelled';
      case 'COMPLETED': return 'Completed';
      default:          return 'Pending';
    }
  }

  bool get _canPayForFood =>
      booking.status == 'CONFIRMED' && booking.paymentStatus == 'PAID';

  bool get _needsPayment =>
      booking.status == 'CONFIRMED' && booking.paymentStatus != 'PAID';

  bool get _canCancel => booking.status == 'BOOKED';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _canPayForFood
              ? AppColors.success.withOpacity(0.4)
              : _needsPayment
              ? AppColors.primary.withOpacity(0.4)
              : Colors.black.withOpacity(0.05),
          width: (_canPayForFood || _needsPayment) ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
          child: Row(children: [
            Container(
              width: 44.w, height: 44.w,
              decoration: BoxDecoration(color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14.r)),
              child: Icon(Icons.event_seat_rounded, color: AppColors.primary, size: 22.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking.restaurantName ?? 'Restaurant',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (booking.tableName != null) ...[
                SizedBox(height: 2.h),
                Text(booking.tableName!,
                    style: TextStyle(fontSize: 12.sp,
                        color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ])),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                  color: _statusBg, borderRadius: BorderRadius.circular(999)),
              child: Text(_statusLabel,
                  style: TextStyle(fontSize: 11.sp,
                      fontWeight: FontWeight.w800, color: _statusColor)),
            ),
          ]),
        ),

        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Divider(height: 1, color: AppColors.line),
        ),

        // ── Info rows ────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(children: [
            _InfoRow(icon: Icons.calendar_today_outlined,
                text: _formatDate(booking.bookingDate)),
            SizedBox(height: 6.h),
            _InfoRow(icon: Icons.access_time_outlined, text: booking.timeSlot),
            SizedBox(height: 6.h),
            _InfoRow(icon: Icons.people_outline,
                text: '${booking.guestCount} guest${booking.guestCount != 1 ? "s" : ""}'),
            if (booking.specialRequests?.isNotEmpty == true) ...[
              SizedBox(height: 6.h),
              _InfoRow(icon: Icons.note_outlined, text: booking.specialRequests!),
            ],
          ]),
        ),

        // ── Pay for food (confirmed + ₹19 paid) ──────────────────────────
        if (_canPayForFood) ...[
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Table Confirmed! 🎉',
                      style: TextStyle(fontSize: 13.sp,
                          fontWeight: FontWeight.w900, color: AppColors.success)),
                  SizedBox(height: 2.h),
                  Text('Pay for your food order now',
                      style: TextStyle(fontSize: 11.sp,
                          color: AppColors.success, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: SizedBox(
              width: double.infinity, height: 46.h,
              child: ElevatedButton.icon(
                onPressed: onPayForFood,
                icon: Icon(Icons.payment_rounded, size: 16.sp),
                label: Text('Pay for Food Order',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),

        ] else if (_needsPayment) ...[
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: SizedBox(
              width: double.infinity, height: 46.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (booking.orderId != null) {
                    context.push('/booking-payment', extra: {
                      'bookingId': booking.id,
                      'orderId':   booking.orderId!,
                    });
                  }
                },
                icon: Icon(Icons.lock_rounded, size: 16.sp),
                label: Text('Pay ₹19 to Confirm Table',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),

        ] else if (_canCancel) ...[
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showCancelDialog(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: Text('Cancel Booking',
                    style: TextStyle(fontSize: 13.sp,
                        fontWeight: FontWeight.w700, color: AppColors.danger)),
              ),
            ),
          ),
        ] else
          SizedBox(height: 14.h),

      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Text('Cancel Booking',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
        content: Text('Your ₹19 booking fee will be refunded.',
            style: TextStyle(fontSize: 13.sp,
                color: AppColors.muted, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep It',
                style: TextStyle(fontSize: 13.sp,
                    fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<BookingBloc>().add(CancelBookingEvent(booking.id));
            },
            child: Text('Yes, Cancel',
                style: TextStyle(fontSize: 13.sp,
                    fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15.sp, color: AppColors.muted),
    SizedBox(width: 6.w),
    Expanded(child: Text(text,
        style: TextStyle(fontSize: 13.sp,
            color: AppColors.muted, fontWeight: FontWeight.w600))),
  ]);
}