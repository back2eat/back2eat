import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderBloc>()..add(const LoadMyOrdersEvent()),
      child: const _OrderHistoryView(),
    );
  }
}

class _OrderHistoryView extends StatelessWidget {
  const _OrderHistoryView();

  @override
  Widget build(BuildContext context) {
    final currency =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Order History'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                ],
              ),
            );
          }

          final orders =
          state is OrdersLoaded ? state.orders : [];

          return Padding(
            padding: EdgeInsets.all(16.w),
            child: orders.isEmpty
                ? Center(
              child: Text(
                'No orders yet',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted),
              ),
            )
                : ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, i) {
                final o = orders[i];
                final status = o.status;
                final statusColor = status == 'COMPLETED'
                    ? const Color(0xFF1E8E3E)
                    : status == 'CANCELLED'
                    ? Colors.red
                    : const Color(0xFFE37400);
                final statusBg = statusColor.withOpacity(0.12);
                final typeLabel = o.orderType == 'DINE_IN'
                    ? 'Dine-In'
                    : 'Take-Away';
                final dateLabel = _formatDate(o.createdAt);

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
                          width: 52.w,
                          height: 52.w,
                          decoration: BoxDecoration(
                            color: AppColors.soft2,
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
                              Row(
                                children: [
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
                                    bg:
                                    Colors.black.withOpacity(0.06),
                                    fg: Colors.black87,
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '${o.orderNumber} • $dateLabel',
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
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(dt);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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