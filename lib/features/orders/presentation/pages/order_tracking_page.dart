import 'dart:async';
import '../../../../../../shared/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderTrackingPage extends StatefulWidget {
  final String? orderId;
  const OrderTrackingPage({super.key, this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late final OrderBloc _bloc;
  Timer?                _timer;
  StreamSubscription?   _fcmSub;  // foreground FCM subscription
  bool _reviewShown = false;

  static const _steps = [
    ('Order Placed',        'Waiting for restaurant to accept'),
    ('Preparing',           'Kitchen is preparing your items'),
    ('Ready',               'Your order is ready for pickup / serving'),
    ('Served / Picked up',  'Order completed — enjoy your meal!'),
  ];

  static const _statusToStep = {
    'CREATED':   0,
    'ACCEPTED':  0,
    'PREPARING': 1,
    'READY':     2,
    'COMPLETED': 3,
    'CANCELLED': -1,
  };

  // Only CREATED and ACCEPTED can be cancelled by customer
  static const _cancellableStatuses = {'CREATED', 'ACCEPTED'};

  @override
  void initState() {
    super.initState();
    // Always create a FRESH bloc — never use getIt singleton here.
    // The singleton carries stale state from previous orders/users.
    _bloc = OrderBloc(getIt<OrderRepository>());
    if (widget.orderId != null) {
      _bloc.add(LoadOrderDetailEvent(widget.orderId!));
    }
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (widget.orderId != null && mounted) {
        _bloc.add(SilentRefreshOrderEvent(widget.orderId!));
      }
    });

    // Instant refresh when a push arrives for this order while page is open
    _fcmSub = NotificationService.instance.orderUpdateStream.listen((incomingOrderId) {
      if (incomingOrderId == widget.orderId && mounted) {
        _bloc.add(SilentRefreshOrderEvent(widget.orderId!));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fcmSub?.cancel();
    _bloc.close();
    super.dispose();
  }

  void _maybeShowReview(BuildContext context, String status) {
    if (status == 'COMPLETED' && !_reviewShown) {
      _reviewShown = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showReviewSheet(context);
      });
    }
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Cancel Order?',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this order?',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Order',
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(CancelOrderEvent(
                orderId: orderId,
                reason:  reasonCtrl.text.trim().isNotEmpty
                    ? reasonCtrl.text.trim()
                    : null,
              ));
            },
            child: Text('Yes, Cancel',
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final encoded = Uri.encodeComponent(label);

    // Try geo: URI first — opens default maps app on Android
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encoded)');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback: Google Maps universal URL (works on iOS + web)
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReviewSheet(BuildContext context) {
    int _stars = 5;
    final _commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20.w, 20.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(999))),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(18.r)),
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 40.sp),
              ),
              SizedBox(height: 14.h),
              Text('Order Completed!',
                  style: TextStyle(
                      fontSize: 20.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 6.h),
              Text('How was your experience?',
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (i) => GestureDetector(
                    onTap: () => setS(() => _stars = i + 1),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Icon(
                          i < _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFFC107),
                          size: 36.sp),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us more (optional)…',
                  hintStyle:
                  TextStyle(fontSize: 13.sp, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.soft,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // TODO: submit review to backend
                  },
                  child: Text('Submit Review',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.sp)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Skip',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: WillPopScope(
        onWillPop: () async {
          context.go('/home');
          return false;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: AppBar(
            title: const Text('Order Status'),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.go('/home'),
            ),
          ),
          body: BlocConsumer<OrderBloc, OrderState>(
            listener: (ctx, state) {
              if (state is OrderDetailLoaded) {
                _maybeShowReview(ctx, state.order.status);
              }
              if (state is OrderCancelled) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Order cancelled successfully'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                );
                // Reload to reflect cancelled state
                _bloc.add(LoadOrderDetailEvent(widget.orderId!));
              }
              if (state is OrderError) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                );
              }
            },
            builder: (ctx, state) {
              if (state is OrderLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              int    currentStep    = 1;
              String restaurantName = 'Back2Eat';
              String orderNumber    = '';
              String orderType      = '';
              String orderStatus    = '';
              bool   isCancelled    = false;
              bool   isCompleted    = false;
              String orderId        = widget.orderId ?? '';
              double? branchLat;
              double? branchLng;
              String? branchAddress;
              String? branchName;
              String? branchPhone;
              String? scheduledTime;
              OrderEntity? currentOrder;

              if (state is OrderPlaced) {
                currentStep    = _statusToStep[state.order.status] ?? 1;
                restaurantName = state.order.restaurantName;
                orderNumber    = state.order.orderNumber;
                orderType      = state.order.orderType;
                orderStatus    = state.order.status;
                isCancelled    = state.order.status == 'CANCELLED';
                isCompleted    = state.order.status == 'COMPLETED';
                orderId        = state.order.id;
                branchLat      = state.order.branchLatitude;
                branchLng      = state.order.branchLongitude;
                branchAddress  = state.order.branchAddress;
                branchName     = state.order.branchName;
                branchPhone    = state.order.branchPhone;
                scheduledTime  = state.order.scheduledTime;
                currentOrder   = state.order;
              } else if (state is OrderDetailLoaded) {
                currentStep    = _statusToStep[state.order.status] ?? 1;
                restaurantName = state.order.restaurantName;
                orderNumber    = state.order.orderNumber;
                orderType      = state.order.orderType;
                orderStatus    = state.order.status;
                isCancelled    = state.order.status == 'CANCELLED';
                isCompleted    = state.order.status == 'COMPLETED';
                orderId        = state.order.id;
                branchLat      = state.order.branchLatitude;
                branchLng      = state.order.branchLongitude;
                branchAddress  = state.order.branchAddress;
                branchName     = state.order.branchName;
                branchPhone    = state.order.branchPhone;
                scheduledTime  = state.order.scheduledTime;
                currentOrder   = state.order;
              }

              final canCancel = _cancellableStatuses.contains(orderStatus);

              return RefreshIndicator(
                onRefresh: () async {
                  if (widget.orderId != null) {
                    _bloc.add(SilentRefreshOrderEvent(widget.orderId!));
                  }
                },
                child: ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    // ── Info card ──
                    _Card(
                      child: Row(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: const Icon(Icons.storefront,
                                color: AppColors.primary),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(restaurantName,
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900))),
                                  if (branchPhone != null && branchPhone!.isNotEmpty)
                                    _ActionIconButton(
                                      icon: Icons.call_rounded,
                                      color: AppColors.success,
                                      tooltip: 'Call restaurant',
                                      onTap: () async {
                                        final uri = Uri.parse('tel:$branchPhone');
                                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                                      },
                                    ),
                                  SizedBox(width: 6.w),
                                  if (branchLat != null && branchLng != null)
                                    _ActionIconButton(
                                      icon: Icons.directions_rounded,
                                      color: AppColors.primary,
                                      tooltip: 'Get directions',
                                      onTap: () => _openMaps(branchLat!, branchLng!, branchName ?? restaurantName),
                                    ),
                                ]),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    if (orderNumber.isNotEmpty)
                                      Text('$orderNumber  ·  ',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppColors.muted,
                                              fontWeight: FontWeight.w600)),
                                    if (orderType.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          orderType == 'DINE_IN'
                                              ? 'Dine-In'
                                              : orderType == 'TABLE_BOOKING'
                                              ? 'Table Booking'
                                              : 'Take-Away',
                                          style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary),
                                        ),
                                      ),
                                  ],
                                ),
                                if (scheduledTime != null && scheduledTime!.isNotEmpty) ...[
                                  SizedBox(height: 6.h),
                                  Row(children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 13.sp, color: AppColors.warning),
                                    SizedBox(width: 4.w),
                                    Text('Slot: $scheduledTime',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w800)),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                          if (isCancelled)
                            _StatusBadge(
                                label: 'CANCELLED', color: AppColors.danger),
                          if (isCompleted && !isCancelled)
                            _StatusBadge(
                                label: 'DONE', color: AppColors.success),
                        ],
                      ),
                    ),

                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Text('Live Status',
                            style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Icon(Icons.sync, size: 16.sp, color: AppColors.muted),
                        SizedBox(width: 4.w),
                        Text('Auto-updating',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // ── Steps ──
                    ...List.generate(_steps.length, (i) {
                      final isDone =
                          i < currentStep && !isCancelled;
                      final isActive = i == currentStep &&
                          !isCancelled &&
                          !isCompleted;
                      final color = isDone || isActive
                          ? AppColors.primary
                          : AppColors.soft;
                      final IconData icon = isDone
                          ? Icons.check_rounded
                          : isActive
                          ? Icons.timelapse_rounded
                          : Icons.more_horiz;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _Card(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius:
                                    BorderRadius.circular(12.r)),
                                child: Icon(icon,
                                    color: (isDone || isActive)
                                        ? Colors.white
                                        : AppColors.muted,
                                    size: 20.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(_steps[i].$1,
                                              style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight:
                                                  FontWeight.w900)),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.w,
                                                vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.12),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  999),
                                              border: Border.all(
                                                  color: AppColors.primary
                                                      .withOpacity(0.18)),
                                            ),
                                            child: Text('LIVE',
                                                style: TextStyle(
                                                    fontSize: 11.sp,
                                                    fontWeight:
                                                    FontWeight.w900,
                                                    color:
                                                    AppColors.primary)),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(_steps[i].$2,
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w600)),
                                    if (isActive) ...[
                                      SizedBox(height: 10.h),
                                      LinearProgressIndicator(
                                        value: null,
                                        minHeight: 5.h,
                                        backgroundColor:
                                        Colors.black.withOpacity(0.06),
                                        color: AppColors.primary,
                                        borderRadius:
                                        BorderRadius.circular(999),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // ── Cancelled banner ──
                    if (isCancelled) ...[
                      SizedBox(height: 4.h),
                      _Card(
                        child: Row(
                          children: [
                            Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: BoxDecoration(
                                  color: AppColors.dangerSoft,
                                  borderRadius:
                                  BorderRadius.circular(12.r)),
                              child: Icon(Icons.cancel_outlined,
                                  color: AppColors.danger, size: 22.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text('Order Cancelled',
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.danger)),
                                  Text(
                                      'This order has been cancelled',
                                      style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Review card ──
                    if (isCompleted) ...[
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () => _showReviewSheet(context),
                        child: _Card(
                          child: Row(
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius:
                                    BorderRadius.circular(12.r)),
                                child: Icon(Icons.star_rounded,
                                    color: const Color(0xFFFFC107),
                                    size: 22.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text('Rate your experience',
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w900)),
                                    Text(
                                        'Help others by sharing your feedback',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: AppColors.muted),
                            ],
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 16.h),

                    // ── Lucky Draw Ticket ───────────────────────────────
                    if (currentOrder?.luckyTicketNumber != null) ...[
                      _LuckyTicketCard(order: currentOrder!),
                      SizedBox(height: 16.h),
                    ],

                    // ── Reach to Restaurant ──
                    if (branchLat != null && branchLng != null) ...[
                      ElevatedButton.icon(
                        onPressed: () => _openMaps(
                          branchLat!,
                          branchLng!,
                          branchName ?? restaurantName,
                        ),
                        icon: Icon(Icons.directions, size: 18.sp),
                        label: Text(
                          'Reach to Restaurant',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                          elevation: 0,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      if (branchAddress != null && branchAddress!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14.sp, color: AppColors.muted),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  branchAddress!,
                                  style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],

                    // ── Cancel button (only when cancellable) ──
                    if (canCancel && orderId.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showCancelDialog(context, orderId),
                        icon: Icon(Icons.cancel_outlined,
                            color: AppColors.danger, size: 18.sp),
                        label: Text('Cancel Order',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.sp)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                          side: BorderSide(color: AppColors.danger),
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],

                    OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Back to Home'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                        side: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color:        color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
          border:       Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 17.sp, color: color),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: color)),
    );
  }
}

class _LuckyTicketCard extends StatelessWidget {
  final OrderEntity order;
  const _LuckyTicketCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isWinner  = order.luckyIsWinner;
    final drawTitle = order.luckyDrawTitle;
    final prize     = order.luckyPrize;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWinner
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: (isWinner ? const Color(0xFFFFD700) : AppColors.primary)
                .withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(isWinner ? '🎉' : '🎟️', style: TextStyle(fontSize: 22.sp)),
          SizedBox(width: 8.w),
          Expanded(child: Text(
            isWinner ? 'You Won!' : 'Lucky Draw Ticket',
            style: TextStyle(
              fontSize: 15.sp, fontWeight: FontWeight.w900,
              color: isWinner ? Colors.black : Colors.white,
            ),
          )),
        ]),
        SizedBox(height: 12.h),

        // Ticket number
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isWinner
                ? Colors.black.withOpacity(0.12)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isWinner
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(children: [
            Text('TICKET NUMBER',
                style: TextStyle(
                  fontSize: 10.sp, fontWeight: FontWeight.w800,
                  color: isWinner
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                  letterSpacing: 1.5,
                )),
            SizedBox(height: 4.h),
            Text(
              order.luckyTicketNumber ?? '',
              style: TextStyle(
                fontSize: 28.sp, fontWeight: FontWeight.w900,
                color: isWinner ? Colors.black : Colors.white,
                letterSpacing: 4,
              ),
            ),
          ]),
        ),

        if (drawTitle != null || prize != null) ...[
          SizedBox(height: 10.h),
          if (drawTitle != null)
            Text(drawTitle,
                style: TextStyle(
                  fontSize: 12.sp, fontWeight: FontWeight.w700,
                  color: isWinner
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                )),
          if (prize != null) ...[
            SizedBox(height: 2.h),
            Row(children: [
              Icon(Icons.card_giftcard_rounded,
                  size: 14.sp,
                  color: isWinner ? Colors.black : Colors.white),
              SizedBox(width: 4.w),
              Text('Prize: $prize',
                  style: TextStyle(
                    fontSize: 12.sp, fontWeight: FontWeight.w800,
                    color: isWinner ? Colors.black : Colors.white,
                  )),
            ]),
          ],
        ],

        if (!isWinner) ...[
          SizedBox(height: 10.h),
          Text('Keep this ticket! Results announced on draw date.',
              style: TextStyle(
                fontSize: 11.sp, fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.6),
              )),
        ],
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      child: child,
    );
  }
}