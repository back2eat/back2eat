// 📱 CUSTOMER APP
// lib/features/bookings/presentation/pages/booking_payment_page.dart
// Replaces mock payment with real Razorpay SDK
// Used when customer needs to pay ₹19 again (edge case: verification failed)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class BookingPaymentPage extends StatefulWidget {
  final String bookingId;
  final String orderId;

  const BookingPaymentPage({
    super.key,
    required this.bookingId,
    required this.orderId,
  });

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  bool    _loading = false;
  bool    _success = false;
  String? _error;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Create Razorpay order for ₹19
      final orderRes = await getIt<ApiClient>().post(
        '/payments/create-order',
        {'orderId': widget.orderId},
      );

      final razorpayOrderId = orderRes['razorpayOrderId'] as String;
      final amountInPaise   = orderRes['amount']          as int;
      final keyId           = orderRes['keyId']           as String;

      _razorpay.open({
        'key':         keyId,
        'amount':      amountInPaise,
        'order_id':    razorpayOrderId,
        'name':        'Back2Eat',
        'description': 'Table Booking Fee',
        'theme':       {'color': '#D01008'},
        'retry':       {'enabled': false},
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await getIt<ApiClient>().post('/payments/verify', {
        'orderId':           widget.orderId,
        'razorpayOrderId':   response.orderId   ?? '',
        'razorpayPaymentId': response.paymentId ?? '',
        'razorpaySignature': response.signature ?? '',
      });
      if (mounted) setState(() { _success = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error   = 'Payment done but verification failed. Contact support.';
      });
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() {
      _loading = false;
      _error   = response.message ?? 'Payment failed. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _SuccessView(onDone: () => context.go('/bookings'));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Amount card ───────────────────────────────────────────────
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
                SizedBox(height: 6.h),
                Text('Refundable if restaurant cancels',
                    style: TextStyle(fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600)),
              ]),
            ),
            SizedBox(height: 24.h),

            // ── Error ─────────────────────────────────────────────────────
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

            // ── Info ──────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                  color: AppColors.infoSoft, borderRadius: BorderRadius.circular(10.r)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(child: Text(
                  'This ₹19 fee is fully refundable if the restaurant cancels your booking.',
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.info,
                      fontWeight: FontWeight.w600, height: 1.4),
                )),
              ]),
            ),
            SizedBox(height: 28.h),

            // ── Pay button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                ),
                child: _loading
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 20.w, height: 20.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                  SizedBox(width: 12.w),
                  Text('Processing...', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
                ])
                    : Text('Pay ₹19 Now', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
              ),
            ),
            SizedBox(height: 12.h),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text('Pay Later', style: TextStyle(
                    fontSize: 13.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

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
            Text('Payment Successful!',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
            SizedBox(height: 10.h),
            Text('Waiting for restaurant to confirm your table.',
                style: TextStyle(fontSize: 14.sp, color: AppColors.muted,
                    fontWeight: FontWeight.w600, height: 1.4),
                textAlign: TextAlign.center),
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
                child: Text('View My Bookings', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}