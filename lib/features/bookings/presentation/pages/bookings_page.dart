import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/booking.dart';
import '../bloc/booking_bloc.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingBloc>()..add(const LoadMyBookingsEvent()),
      child: const _BookingsView(),
    );
  }
}

class _BookingsView extends StatelessWidget {
  const _BookingsView();

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
            onPressed: () =>
                context.read<BookingBloc>().add(const LoadMyBookingsEvent()),
          ),
        ],
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Booking cancelled successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
            context.read<BookingBloc>().add(const LoadMyBookingsEvent());
          }
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingsLoaded) {
            if (state.bookings.isEmpty) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_seat_outlined,
                      size: 64.r, color: AppColors.muted),
                  SizedBox(height: 12.h),
                  Text('No bookings yet',
                      style: TextStyle(fontSize: 16.sp,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 6.h),
                  Text('Book a table from any restaurant page',
                      style: TextStyle(fontSize: 13.sp,
                          color: AppColors.muted, fontWeight: FontWeight.w600)),
                ],
              ));
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<BookingBloc>().add(const LoadMyBookingsEvent()),
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: state.bookings.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (ctx, i) =>
                    _BookingCard(booking: state.bookings[i]),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final BookingEntity booking;
  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'CONFIRMED':  return AppColors.success;
      case 'CANCELLED':  return AppColors.danger;
      case 'COMPLETED':  return AppColors.info;
      default:           return AppColors.warning;
    }
  }

  Color get _statusBg {
    switch (booking.status) {
      case 'CONFIRMED':  return AppColors.successSoft;
      case 'CANCELLED':  return AppColors.dangerSoft;
      case 'COMPLETED':  return AppColors.infoSoft;
      default:           return AppColors.warningSoft;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case 'CONFIRMED':  return 'Confirmed';
      case 'CANCELLED':  return 'Cancelled';
      case 'COMPLETED':  return 'Completed';
      default:           return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = booking.status == 'PENDING' ||
        (booking.status == 'CONFIRMED' && !booking.needsPayment);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          // Highlight confirmed+unpaid with primary border
          color: booking.needsPayment
              ? AppColors.primary.withOpacity(0.4)
              : Colors.black.withOpacity(0.05),
          width: booking.needsPayment ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header row ──────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
          child: Row(children: [
            Container(
              width: 44.w, height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.event_seat_rounded,
                  color: AppColors.primary, size: 22.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.restaurantName ?? 'Restaurant',
                    style: TextStyle(fontSize: 15.sp,
                        fontWeight: FontWeight.w900),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (booking.tableName != null) ...[
                  SizedBox(height: 2.h),
                  Text(booking.tableName!,
                      style: TextStyle(fontSize: 12.sp,
                          color: AppColors.muted, fontWeight: FontWeight.w600)),
                ],
              ],
            )),
            // Status badge
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

        // ── Divider ─────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Divider(height: 1, color: AppColors.line),
        ),

        // ── Info rows ────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(children: [
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: _formatDate(booking.bookingDate),
            ),
            SizedBox(height: 6.h),
            _InfoRow(
              icon: Icons.access_time_outlined,
              text: booking.timeSlot,
            ),
            SizedBox(height: 6.h),
            _InfoRow(
              icon: Icons.people_outline,
              text: '${booking.guestCount} guest${booking.guestCount != 1 ? "s" : ""}',
            ),
            if (booking.specialRequests != null &&
                booking.specialRequests!.isNotEmpty) ...[
              SizedBox(height: 6.h),
              _InfoRow(
                icon: Icons.note_outlined,
                text: booking.specialRequests!,
              ),
            ],
          ]),
        ),

        // ── PAY ₹19 banner — shown when confirmed but payment pending ────
        if (booking.needsPayment) ...[
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.payment_rounded,
                    color: AppColors.primary, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Table Confirmed! 🎉',
                        style: TextStyle(fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary)),
                    SizedBox(height: 2.h),
                    Text('Pay ₹19 to secure your reservation',
                        style: TextStyle(fontSize: 11.sp,
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                )),
              ]),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: () => _openPayment(context),
                icon: Icon(Icons.lock_rounded, size: 16.sp),
                label: Text('Pay ₹19 to Confirm Table',
                    style: TextStyle(fontSize: 14.sp,
                        fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
        ] else if (canCancel) ...[
          // ── Cancel button ─────────────────────────────────────────────
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showCancelDialog(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: Text('Cancel Booking',
                    style: TextStyle(fontSize: 13.sp,
                        fontWeight: FontWeight.w700, color: AppColors.danger)),
              ),
            ),
          ),
        ] else ...[
          SizedBox(height: 14.h),
        ],

      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _openPayment(BuildContext context) {
    // Navigate to the order tracking / payment page for this booking's order
    if (booking.orderId != null) {
      context.push('/order-tracking', extra: booking.orderId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment link unavailable. Please contact support.'),
      ));
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Text('Cancel Booking',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
        content: Text(
          'Are you sure you want to cancel this table booking?',
          style: TextStyle(fontSize: 13.sp, color: AppColors.muted,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep It',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700,
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

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15.sp, color: AppColors.muted),
      SizedBox(width: 6.w),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 13.sp,
              color: AppColors.muted, fontWeight: FontWeight.w600))),
    ]);
  }
}