import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/presentation/bloc/booking_bloc.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<OrderBloc>()..add(const LoadMyOrdersEvent()),
        ),
        BlocProvider(
          create: (_) =>
          getIt<BookingBloc>()..add(const LoadMyBookingsEvent()),
        ),
      ],
      child: const _OrderHistoryView(),
    );
  }
}

class _OrderHistoryView extends StatefulWidget {
  const _OrderHistoryView();

  @override
  State<_OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<_OrderHistoryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelStyle:
          TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
          unselectedLabelStyle:
          TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.line,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Table Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Regular Orders ─────────────────────────────────────
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is OrderError) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(state.message,
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => context
                          .read<OrderBloc>()
                          .add(const LoadMyOrdersEvent()),
                      child: const Text('Retry'),
                    ),
                  ]),
                );
              }
              final orders = state is OrdersLoaded ? state.orders : [];
              if (orders.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 56.sp, color: AppColors.muted),
                    SizedBox(height: 12.h),
                    Text('No orders yet',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted)),
                  ]),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<OrderBloc>()
                    .add(const LoadMyOrdersEvent()),
                child: ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    final status = o.status;
                    final statusColor = status == 'COMPLETED'
                        ? AppColors.success
                        : status == 'CANCELLED'
                        ? AppColors.danger
                        : AppColors.warning;
                    final statusBg = statusColor.withOpacity(0.12);
                    final typeLabel = o.orderType == 'DINE_IN'
                        ? 'Dine-In'
                        : o.orderType == 'TABLE_BOOKING'
                        ? 'Table Booking'
                        : 'Take-Away';

                    return GestureDetector(
                      onTap: () =>
                          context.push('/order-tracking', extra: o.id),
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52.w, height: 52.w,
                              decoration: BoxDecoration(
                                color: AppColors.soft2 ?? AppColors.soft,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: const Icon(Icons.receipt_long,
                                  color: AppColors.primary),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        o.restaurantName.isEmpty
                                            ? 'Restaurant'
                                            : o.restaurantName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    _Chip(
                                      text: typeLabel,
                                      bg: Colors.black.withOpacity(0.06),
                                      fg: Colors.black87,
                                    ),
                                  ]),
                                  SizedBox(height: 6.h),
                                  Text(
                                    '${o.orderNumber} • ${_formatDate(o.createdAt)}',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 10.h),
                                  _Chip(
                                      text: status,
                                      bg: statusBg,
                                      fg: statusColor),
                                ],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              currency.format(o.totalAmount),
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // ── Tab 2: Table Bookings ─────────────────────────────────────
          BlocConsumer<BookingBloc, BookingState>(
            listener: (context, state) {
              if (state is BookingCancelled) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Booking cancelled'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
                context
                    .read<BookingBloc>()
                    .add(const LoadMyBookingsEvent());
              }
            },
            builder: (context, state) {
              if (state is BookingLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final bookings =
              state is BookingsLoaded ? state.bookings : <BookingEntity>[];
              if (bookings.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.event_seat_outlined,
                        size: 56.sp, color: AppColors.muted),
                    SizedBox(height: 12.h),
                    Text('No bookings yet',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted)),
                  ]),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<BookingBloc>()
                    .add(const LoadMyBookingsEvent()),
                child: ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, i) =>
                      _BookingSummaryCard(booking: bookings[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(dt);
  }
}

// ── Booking Summary Card (used in history tab) ────────────────────────────────
class _BookingSummaryCard extends StatelessWidget {
  final BookingEntity booking;
  const _BookingSummaryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.status == 'CONFIRMED'
        ? AppColors.success
        : booking.status == 'CANCELLED'
        ? AppColors.danger
        : AppColors.warning;
    final statusBg = statusColor.withOpacity(0.12);
    final statusLabel = booking.status == 'CONFIRMED'
        ? 'Confirmed'
        : booking.status == 'CANCELLED'
        ? 'Cancelled'
        : booking.status == 'COMPLETED'
        ? 'Completed'
        : 'Pending';

    return GestureDetector(
      onTap: () => context.push('/bookings'),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: booking.needsPayment
                ? AppColors.primary.withOpacity(0.4)
                : Colors.black.withOpacity(0.05),
            width: booking.needsPayment ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52.w, height: 52.w,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(Icons.event_seat_rounded,
                  color: AppColors.primary, size: 26.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.restaurantName ?? 'Restaurant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${booking.timeSlot}  ·  ${booking.guestCount} guest${booking.guestCount != 1 ? "s" : ""}',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  Row(children: [
                    _Chip(text: statusLabel, bg: statusBg, fg: statusColor),
                    if (booking.needsPayment) ...[
                      SizedBox(width: 6.w),
                      _Chip(
                        text: 'Pay ₹19',
                        bg: AppColors.primarySoft,
                        fg: AppColors.primary,
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.bg, required this.fg});
  final String text;
  final Color  bg;
  final Color  fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w900,
              color: fg)),
    );
  }
}