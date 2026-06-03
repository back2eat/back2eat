// 📱 CUSTOMER APP
// lib/features/checkout/presentation/pages/checkout_page.dart
// pubspec.yaml: razorpay_flutter: ^1.3.7

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../order_type/presentation/cubit/order_type_cubit.dart';
import '../../../orders/presentation/bloc/order_bloc.dart';
import '../../../orders/presentation/bloc/order_event.dart';
import '../../../orders/presentation/bloc/order_state.dart';

const double _commissionPercent = 2.0;
const int    _maxRedeemPercent  = 20;

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

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderBloc>(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();
  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  String? _selectedTime;
  int     _guestCount    = 1;
  bool    _isSubmitting  = false;
  late List<String> _timeSlots;

  final _couponCtrl    = TextEditingController();
  bool    _applyingCoupon = false;
  String? _appliedCode;
  double  _discountAmount = 0.0;
  String? _couponError;
  String? _couponSuccess;

  int    _pointsBalance    = 0;
  int    _luckyWinBalance  = 0;
  double _pointsValuePerPt = 0.1;
  bool   _usePoints        = false;
  double _pointsDiscount   = 0.0;

  // ── Razorpay ──────────────────────────────────────────────────────────────
  late Razorpay _razorpay;

  // Stored during payment so we can use in callbacks
  CartState?  _pendingCart;
  OrderType?  _pendingOrderType;
  double?     _pendingSubtotal;
  double?     _pendingCommission;
  double?     _pendingTotal;
  int?        _pendingGuestCount;
  int         _pendingPointsToRedeem = 0;

  int    get _pointsToRedeem => _usePoints ? (_pointsDiscount / _pointsValuePerPt).round() : 0;
  double get _totalSavings   => _discountAmount + _pointsDiscount;

  @override
  void initState() {
    super.initState();
    _timeSlots = _buildTimeSlots();
    _loadPoints();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadPoints() async {
    try {
      final data = await getIt<ApiClient>().get('/points');
      if (!mounted) return;
      setState(() {
        _pointsBalance    = (data['balance']         as num?)?.toInt()    ?? 0;
        _luckyWinBalance  = (data['luckyWinBalance'] as num?)?.toInt()    ?? 0;
        _pointsValuePerPt = (data['valuePerPoint']   as num?)?.toDouble() ?? 0.1;
      });
    } catch (_) {}
  }

  void _togglePoints(double subtotal) {
    if (_pointsBalance == 0) return;
    setState(() {
      _usePoints = !_usePoints;
      if (_usePoints) {
        final luckyVal   = (_luckyWinBalance * _pointsValuePerPt).clamp(0.0, subtotal);
        final regularBal = (_pointsBalance - _luckyWinBalance).clamp(0, _pointsBalance);
        final regularMax = (regularBal * _pointsValuePerPt).clamp(0.0, subtotal * _maxRedeemPercent / 100);
        _pointsDiscount  = double.parse((luckyVal + regularMax).clamp(0.0, subtotal).toStringAsFixed(2));
      } else {
        _pointsDiscount = 0.0;
      }
    });
  }

  Future<void> _applyCoupon(double subtotal, String orderType, String restaurantId) async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _applyingCoupon = true; _couponError = null; _couponSuccess = null; });
    try {
      final res = await getIt<ApiClient>().post('/coupons/apply',
          {'code': code, 'subtotal': subtotal, 'orderType': orderType, 'restaurantId': restaurantId});
      final discount = (res['discountAmount'] as num?)?.toDouble() ?? 0.0;
      final desc     = (res['coupon'] as Map?)?['description'] as String? ?? '';
      setState(() {
        _appliedCode    = code;
        _discountAmount = discount;
        _couponSuccess  = desc.isNotEmpty ? desc : 'Coupon applied! You save ₹${discount.toStringAsFixed(0)}';
        _couponError    = null;
      });
    } catch (e) {
      String msg = 'Invalid or expired coupon';
      if (e.toString().contains('Minimum'))      msg = e.toString().replaceAll('Exception: ', '');
      if (e.toString().contains('already used')) msg = 'You have already used this coupon';
      setState(() { _couponError = msg; _appliedCode = null; _discountAmount = 0.0; _couponSuccess = null; });
    } finally {
      setState(() => _applyingCoupon = false);
    }
  }

  void _removeCoupon() => setState(() {
    _couponCtrl.clear(); _appliedCode = null; _discountAmount = 0.0;
    _couponError = null; _couponSuccess = null;
  });

  // ── Step 1: Create Razorpay order on backend, open payment sheet ──────────
  Future<void> _initiatePayment(
      BuildContext context,
      CartState cart,
      OrderType orderType,
      double subtotal,
      double commission,
      double total,
      int? guestCount,
      int pointsToRedeem,
      ) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Store for use in payment callbacks
    _pendingCart           = cart;
    _pendingOrderType      = orderType;
    _pendingSubtotal       = subtotal;
    _pendingCommission     = commission;
    _pendingTotal          = total;
    _pendingGuestCount     = guestCount;
    _pendingPointsToRedeem = pointsToRedeem;

    try {
      // Create Razorpay order on backend
      final res = await getIt<ApiClient>().post('/payments/create-order', {
        'amount':  total,
        'receipt': 'order_${DateTime.now().millisecondsSinceEpoch}',
      });

      final razorpayOrderId = res['razorpayOrderId'] as String;
      final keyId           = res['keyId']           as String;
      final amountInPaise   = res['amount']          as int;

      // Open Razorpay payment sheet
      final options = {
        'key':         keyId,
        'amount':      amountInPaise,
        'order_id':    razorpayOrderId,
        'name':        'Back2Eat',
        'description': 'Food Order Payment',
        'image':       'https://back2eat-api.onrender.com/assets/logo.png',
        'prefill': {
          'contact': '', // will auto-fill from Razorpay account
          'email':   '',
        },
        'theme': {
          'color': '#D01008',
        },
        'retry': {
          'enabled': false,
        },
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment failed: ${e.toString().replaceAll("Exception:", "").trim()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Step 2: Payment success → verify + place order ────────────────────────
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    final cart      = _pendingCart;
    final orderType = _pendingOrderType;
    if (cart == null || orderType == null) return;

    String orderTypeStr;
    switch (orderType) {
      case OrderType.dineIn:       orderTypeStr = 'DINE_IN';   break;
      case OrderType.tableBooking: orderTypeStr = 'TABLE_BOOKING'; break;
      case OrderType.takeAway:
      default:                     orderTypeStr = 'TAKEAWAY';
    }

    final items = cart.items.map((c) => {
      'menuItemId': c.menuItemId,
      'name':       c.name,
      'quantity':   c.qty,
      'price':      c.price,
    }).toList();

    // Dispatch verify + place order event
    if (mounted) {
      context.read<OrderBloc>().add(VerifyAndPlaceOrderEvent(
        razorpayOrderId:   response.orderId   ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        restaurantId:      cart.items.first.restaurantId,
        branchId:          cart.items.first.branchId,
        orderType:         orderType,
        cartItems:         cart.items,
        scheduledTime:     _selectedTime,
        guestCount:        _pendingGuestCount,
        couponCode:        _appliedCode,
        pointsRedeemed:    _pendingPointsToRedeem > 0 ? _pendingPointsToRedeem : null,
        subtotal:          _pendingSubtotal,
        commissionAmount:  _pendingCommission,
        bookingFee:        0,
        totalAmount:       _pendingTotal,
      ));
    }
  }

  // ── Payment failed ────────────────────────────────────────────────────────
  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isSubmitting = false);
    if (!mounted) return;
    final msg = response.message ?? 'Payment failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── External wallet selected ──────────────────────────────────────────────
  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _isSubmitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('External wallet: ${response.walletName}'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderPlaced) {
          setState(() => _isSubmitting = false);
          context.read<CartBloc>().add(const ClearCartEvent());
          context.go('/order-tracking', extra: state.order.id);
        }
        if (state is OrderError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: const Text('Checkout'),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, cart) {
              final isEmpty      = cart.items.isEmpty;
              final subtotal     = cart.total;
              final commission   = double.parse((subtotal * _commissionPercent / 100).toStringAsFixed(2));
              final restaurantId = cart.items.isNotEmpty ? cart.items.first.restaurantId : '';

              return BlocBuilder<OrderTypeCubit, OrderType>(
                builder: (context, orderType) {
                  final effectiveType = orderType == OrderType.tableBooking ? OrderType.dineIn : orderType;
                  final needsGuests   = effectiveType == OrderType.dineIn;
                  final orderTypeStr  = effectiveType == OrderType.dineIn ? 'DINE_IN' : 'TAKEAWAY';
                  final total = double.parse(
                      (subtotal - _discountAmount - _pointsDiscount + commission)
                          .clamp(0, double.infinity).toStringAsFixed(2));

                  return BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, orderState) {
                      final isLoading     = orderState is OrderLoading || _isSubmitting;
                      final needsTimeSlot = _selectedTime == null;

                      return Column(children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                              // ORDER TYPE
                              _SectionTitle(title: 'Order Type'),
                              SizedBox(height: 10.h),
                              _Card(child: Row(children: [
                                Container(
                                  width: 40.w, height: 40.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(_orderTypeIcon(effectiveType), color: AppColors.primary, size: 20.sp),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_orderTypeLabel(effectiveType),
                                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                                  Text(_orderTypeSubLabel(effectiveType),
                                      style: TextStyle(fontSize: 11.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                ])),
                                _PillButton(text: 'Change', onTap: () => _showOrderTypeSheet(context, effectiveType)),
                              ])),

                              // TIME SLOT
                              SizedBox(height: 12.h),
                              _SectionTitle(title: 'Select Time Slot'),
                              SizedBox(height: 10.h),
                              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('When would you like to arrive?',
                                    style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
                                SizedBox(height: 12.h),
                                _timeSlots.isEmpty
                                    ? Text('No available slots for today',
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
                              ])),

                              // GUEST COUNT
                              if (needsGuests) ...[
                                SizedBox(height: 12.h),
                                _SectionTitle(title: 'Number of Guests'),
                                SizedBox(height: 10.h),
                                _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('How many people are dining?',
                                      style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
                                  SizedBox(height: 14.h),
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    GestureDetector(
                                      onTap: () { if (_guestCount > 1) setState(() => _guestCount--); },
                                      child: Container(
                                        width: 40.w, height: 40.w,
                                        decoration: BoxDecoration(
                                          color: _guestCount > 1 ? AppColors.primary : AppColors.soft,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Icon(Icons.remove, color: _guestCount > 1 ? Colors.white : AppColors.muted, size: 20.sp),
                                      ),
                                    ),
                                    SizedBox(width: 24.w),
                                    Column(children: [
                                      Text('$_guestCount', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900)),
                                      Text(_guestCount == 1 ? 'person' : 'people',
                                          style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                    ]),
                                    SizedBox(width: 24.w),
                                    GestureDetector(
                                      onTap: () { if (_guestCount < 20) setState(() => _guestCount++); },
                                      child: Container(
                                        width: 40.w, height: 40.w,
                                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12.r)),
                                        child: Icon(Icons.add, color: Colors.white, size: 20.sp),
                                      ),
                                    ),
                                  ]),
                                ])),
                              ],

                              // COUPON
                              SizedBox(height: 12.h),
                              _SectionTitle(title: 'Coupon / Offer'),
                              SizedBox(height: 10.h),
                              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (_appliedCode != null) ...[
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(12.r)),
                                    child: Row(children: [
                                      Icon(Icons.local_offer_rounded, color: AppColors.success, size: 18.sp),
                                      SizedBox(width: 8.w),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(_appliedCode!, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: AppColors.success)),
                                        if (_couponSuccess != null)
                                          Text(_couponSuccess!, style: TextStyle(fontSize: 11.sp, color: AppColors.success, fontWeight: FontWeight.w700)),
                                      ])),
                                      GestureDetector(
                                        onTap: _removeCoupon,
                                        child: Padding(padding: EdgeInsets.all(4.w),
                                            child: Icon(Icons.close, size: 16.sp, color: AppColors.success)),
                                      ),
                                    ]),
                                  ),
                                ] else ...[
                                  Row(children: [
                                    Expanded(child: TextField(
                                      controller: _couponCtrl,
                                      textCapitalization: TextCapitalization.characters,
                                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                                      decoration: InputDecoration(
                                        hintText: 'Enter coupon code',
                                        hintStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.muted, letterSpacing: 0),
                                        prefixIcon: Icon(Icons.local_offer_outlined, color: AppColors.muted, size: 18.sp),
                                        filled: true, fillColor: AppColors.soft,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                      ),
                                    )),
                                    SizedBox(width: 8.w),
                                    GestureDetector(
                                      onTap: _applyingCoupon ? null : () => _applyCoupon(subtotal, orderTypeStr, restaurantId),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
                                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12.r)),
                                        child: _applyingCoupon
                                            ? SizedBox(width: 16.w, height: 16.w,
                                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : Text('Apply', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                                      ),
                                    ),
                                  ]),
                                  if (_couponError != null) ...[
                                    SizedBox(height: 8.h),
                                    Row(children: [
                                      Icon(Icons.error_outline, size: 13.sp, color: AppColors.danger),
                                      SizedBox(width: 4.w),
                                      Expanded(child: Text(_couponError!,
                                          style: TextStyle(fontSize: 11.sp, color: AppColors.danger, fontWeight: FontWeight.w700))),
                                    ]),
                                  ],
                                ],
                              ])),

                              // POINTS
                              if (_pointsBalance > 0) ...[
                                SizedBox(height: 12.h),
                                _SectionTitle(title: 'Back2Eat Points'),
                                SizedBox(height: 10.h),
                                _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      width: 40.w, height: 40.w,
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(12.r)),
                                      child: Icon(Icons.stars_rounded, color: AppColors.primary, size: 20.sp),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('$_pointsBalance pts  ·  ₹${(_pointsBalance * _pointsValuePerPt).toStringAsFixed(0)} value',
                                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                                      Text(
                                        _usePoints ? 'Saving ₹${_pointsDiscount.toStringAsFixed(0)} on this order' : 'Tap to apply points',
                                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700,
                                            color: _usePoints ? AppColors.success : AppColors.muted),
                                      ),
                                    ])),
                                    Switch(value: _usePoints, activeColor: AppColors.primary, onChanged: (_) => _togglePoints(subtotal)),
                                  ]),
                                ])),
                              ],

                              // ORDER SUMMARY
                              SizedBox(height: 12.h),
                              _SectionTitle(title: 'Order Summary'),
                              SizedBox(height: 10.h),

                              if (isEmpty)
                                _Card(child: Row(children: [
                                  const Icon(Icons.shopping_bag_outlined, color: AppColors.muted),
                                  SizedBox(width: 10.w),
                                  Expanded(child: Text('Your cart is empty',
                                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800))),
                                  TextButton(
                                    onPressed: () => context.go('/home'),
                                    child: Text('Browse', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                                  ),
                                ]))
                              else
                                _Card(child: Column(children: [
                                  ...cart.items.map((e) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Container(
                                        height: 38.h, width: 38.h,
                                        decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12.r)),
                                        child: const Icon(Icons.fastfood, color: Colors.black54),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                                        SizedBox(height: 4.h),
                                        Text('Qty: ${e.qty}',
                                            style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
                                      ])),
                                      SizedBox(width: 8.w),
                                      Text(currency.format(e.price * e.qty),
                                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                                    ]),
                                  )),
                                  Container(height: 1, color: AppColors.line),
                                  SizedBox(height: 12.h),
                                  _BillRow(label: 'Subtotal', value: subtotal, currency: currency),
                                  SizedBox(height: 6.h),
                                  _BillRow(label: 'Platform fee (2%)', value: commission, currency: currency, labelColor: AppColors.muted),
                                  if (_discountAmount > 0) ...[
                                    SizedBox(height: 6.h),
                                    Row(children: [
                                      Row(children: [
                                        Icon(Icons.local_offer_rounded, size: 13.sp, color: AppColors.success),
                                        SizedBox(width: 4.w),
                                        Text('Coupon discount', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.success)),
                                      ]),
                                      const Spacer(),
                                      Text('- ${currency.format(_discountAmount)}',
                                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: AppColors.success)),
                                    ]),
                                  ],
                                  if (_pointsDiscount > 0) ...[
                                    SizedBox(height: 6.h),
                                    Row(children: [
                                      Row(children: [
                                        Icon(Icons.stars_rounded, size: 13.sp, color: AppColors.primary),
                                        SizedBox(width: 4.w),
                                        Text('Points discount', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                      ]),
                                      const Spacer(),
                                      Text('- ${currency.format(_pointsDiscount)}',
                                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
                                    ]),
                                  ],
                                  SizedBox(height: 10.h),
                                  Container(height: 1, color: AppColors.line),
                                  SizedBox(height: 10.h),
                                  Row(children: [
                                    Text('Total', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
                                    const Spacer(),
                                    Text(currency.format(total),
                                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
                                  ]),
                                ])),

                              SizedBox(height: 100.h),
                            ]),
                          ),
                        ),

                        // ── Sticky bottom CTA ──────────────────────────────
                        Container(
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Row(children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Payable', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppColors.muted)),
                                if (_totalSavings > 0)
                                  Text('You saved ₹${_totalSavings.toStringAsFixed(0)}!',
                                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppColors.success)),
                              ]),
                              const Spacer(),
                              Text(currency.format(total), style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
                            ]),
                            if (needsTimeSlot) ...[
                              SizedBox(height: 6.h),
                              Text('Please select a time slot above',
                                  style: TextStyle(fontSize: 11.sp, color: AppColors.danger, fontWeight: FontWeight.w700)),
                            ],
                            SizedBox(height: 10.h),
                            Opacity(
                              opacity: (isEmpty || isLoading || needsTimeSlot) ? 0.6 : 1,
                              child: PrimaryButton(
                                text: isLoading ? 'Processing...' : isEmpty ? 'Cart Empty' : 'Pay ₹${total.toStringAsFixed(0)}',
                                onTap: () {
                                  if (isEmpty || isLoading || needsTimeSlot || _isSubmitting) return;
                                  _initiatePayment(
                                    context, cart, effectiveType,
                                    subtotal, commission, total,
                                    needsGuests ? _guestCount : null,
                                    _pointsToRedeem,
                                  );
                                },
                              ),
                            ),
                          ]),
                        ),
                      ]);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _orderTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.dineIn:       return Icons.storefront;
      case OrderType.takeAway:     return Icons.shopping_bag_outlined;
      case OrderType.tableBooking: return Icons.event_seat_rounded;
    }
  }

  String _orderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:   return 'Dine-In';
      case OrderType.takeAway: return 'Take-Away (pickup)';
      default:                 return 'Dine-In';
    }
  }

  String _orderTypeSubLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:   return 'Sit and enjoy at the restaurant';
      case OrderType.takeAway: return 'Pick up at the counter';
      default:                 return 'Sit and enjoy at the restaurant';
    }
  }

  void _showOrderTypeSheet(BuildContext context, OrderType current) {
    final cubit   = context.read<OrderTypeCubit>();
    final allowed = cubit.allowedTypes.where((t) => t != OrderType.tableBooking).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44.w, height: 5.h,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999))),
          SizedBox(height: 14.h),
          Text('Select Order Type', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 14.h),
          Row(children: [
            if (allowed.contains(OrderType.dineIn)) ...[
              Expanded(child: _BubbleChoice(
                title: 'Dine-In', subtitle: 'Eat at restaurant', icon: Icons.storefront,
                selected: current == OrderType.dineIn,
                onTap: () { context.read<OrderTypeCubit>().set(OrderType.dineIn); Navigator.pop(context); },
              )),
              SizedBox(width: 10.w),
            ],
            if (allowed.contains(OrderType.takeAway))
              Expanded(child: _BubbleChoice(
                title: 'Take-Away', subtitle: 'Pickup at counter', icon: Icons.shopping_bag_outlined,
                selected: current == OrderType.takeAway,
                onTap: () { context.read<OrderTypeCubit>().set(OrderType.takeAway); Navigator.pop(context); },
              )),
          ]),
        ]),
      ),
    );
  }
}

// ── Supporting widgets (unchanged) ────────────────────────────────────────────
class _BillRow extends StatelessWidget {
  final String label; final double value; final NumberFormat currency; final Color? labelColor;
  const _BillRow({required this.label, required this.value, required this.currency, this.labelColor});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: labelColor ?? AppColors.text)),
    const Spacer(),
    Text(currency.format(value), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
  ]);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 2.w),
    child: Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.black87)),
  );
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.text, required this.onTap});
  final String text; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.black87)),
    ),
  );
}

class _BubbleChoice extends StatelessWidget {
  const _BubbleChoice({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});
  final String title, subtitle; final IconData icon; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18.r), onTap: onTap,
    child: Ink(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.12) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: selected ? AppColors.primary.withOpacity(0.35) : Colors.black.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            height: 36.h, width: 36.h,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withOpacity(0.18) : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 18.sp, color: selected ? AppColors.primary : Colors.black54)),
        SizedBox(height: 8.h),
        Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 2.h),
        Text(subtitle, style: TextStyle(fontSize: 11.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: Colors.black.withOpacity(0.05)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: child,
  );
}