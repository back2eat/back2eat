import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../points/presentation/pages/points_page.dart';

// ── FAQ data ──────────────────────────────────────────────────────────────────
class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

const _faqs = <_Faq>[
  _Faq('What is Back2Eat?',
      'Back2Eat is a dine-in and take-away platform connecting you with local restaurant partners. You can browse menus, place orders, and book tables — all in one app. We do not offer home delivery.'),
  _Faq('How does Dine-In work?',
      'Select Dine-In, choose a time slot, add items to your cart, and place your order. Show up at the restaurant at your selected time and your meal will be ready.'),
  _Faq('How does Take-Away work?',
      'Select Take-Away, place your order, and collect it directly from the restaurant counter at your selected time. No waiting in queues.'),
  _Faq('What is a Table Booking?',
      'Table Booking lets you reserve a specific table at the restaurant. A flat Rs.19 fee is charged once the restaurant confirms your booking. The fee is non-refundable after confirmation.'),
  _Faq('When do I pay for a Table Booking?',
      'After placing your request, the restaurant confirms your table. Once confirmed, you will be prompted inside the app to pay the Rs.19 booking fee to finalise your reservation.'),
  _Faq('Can I cancel my order?',
      'You can cancel before the restaurant accepts your order for a full refund. Once the restaurant has accepted and started preparing, cancellation may not be possible.'),
  _Faq('How do coupons work?',
      'Enter a valid coupon code at checkout and tap Apply. The discount is instantly shown in your bill. Only one coupon can be applied per order.'),
  _Faq('Is there a platform fee?',
      'Yes, a 2% platform fee is charged on the order subtotal. The exact amount is shown clearly in your bill before you confirm.'),
  _Faq('What payment methods are accepted?',
      'Back2Eat accepts all major UPI apps (GPay, PhonePe, Paytm), debit and credit cards, and net banking through our secure payment gateway.'),
  _Faq('How do I track my order?',
      'After placing an order you are taken to the Order Tracking screen. You can also access it from Profile > Order History.'),
  _Faq('What if the restaurant rejects my booking?',
      'If the restaurant rejects your table booking, any fee charged will be fully refunded to your original payment method within 5-7 business days.'),
  _Faq('Is my payment secure?',
      'Yes. All payments are processed through a PCI-DSS compliant payment gateway. Back2Eat does not store your card or UPI details.'),
];

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthBloc>()..add(const AuthCheckSessionEvent()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go('/start');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoggedIn = state is AuthAuthenticated;
              final user = isLoggedIn ? (state).user : null;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
                child: Column(
                  children: [
                    // ── Profile card ────────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 56.w, height: 56.w,
                          decoration: BoxDecoration(color: AppColors.soft2, borderRadius: BorderRadius.circular(18.r)),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            user?.name?.isNotEmpty == true ? user!.name! : isLoggedIn ? user!.mobile : 'Guest User',
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            isLoggedIn ? (user!.email ?? user.mobile) : 'Sign in to sync your orders',
                            style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                        ])),
                        if (!isLoggedIn)
                          GestureDetector(
                            onTap: () => context.go('/signin'),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                              ),
                              child: Text('Sign In', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
                            ),
                          ),
                      ]),
                    ),

                    // ── Recent Orders ───────────────────────────────────
                    if (isLoggedIn) ...[
                      SizedBox(height: 20.h),
                      Row(children: [
                        Text('Recent Orders', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.black87)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/order-history'),
                          child: Text('View all', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                      ]),
                      SizedBox(height: 10.h),
                      _RecentOrders(),
                    ],

                    SizedBox(height: 16.h),

                    // ── Quick Actions ───────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Quick Actions', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.black87)),
                    ),
                    SizedBox(height: 10.h),
                    _Tile(
                      title: 'Order History',
                      subtitle: 'View all your previous orders',
                      icon: Icons.receipt_long,
                      onTap: () => context.push('/order-history'),
                    ),
                    SizedBox(height: 10.h),
                    _Tile(
                      title: 'My Points',
                      subtitle: 'View balance, earn & redeem rewards',
                      icon: Icons.stars_rounded,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PointsPage())),
                    ),
                    SizedBox(height: 10.h),
                    _Tile(
                      title: 'Back to Home',
                      subtitle: 'Browse restaurants',
                      icon: Icons.home_outlined,
                      onTap: () => context.go('/home'),
                    ),

                    if (isLoggedIn) ...[
                      SizedBox(height: 16.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Account', style: TextStyle(
                            fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.black87)),
                      ),
                      SizedBox(height: 10.h),
                      _Tile(
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        icon: Icons.logout,
                        onTap: () => _confirmLogout(context),
                        isDestructive: true,
                      ),
                      SizedBox(height: 10.h),
                      // ── Delete Account (required for Play Store) ────────
                      _Tile(
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account and all data',
                        icon: Icons.delete_forever_rounded,
                        onTap: () => _confirmDeleteAccount(context),
                        isDestructive: true,
                      ),
                      SizedBox(height: 10.h),
                      // ── Cancel Deletion (if pending) ────────────────────
                      _CancelDeletionTile(),
                    ],

                    SizedBox(height: 18.h),

                    // ── FAQs ───────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('FAQs', style: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.black87)),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                            blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Column(children: [
                        ..._faqs.asMap().entries.map((entry) {
                          final i   = entry.key;
                          final faq = entry.value;
                          return _FaqTile(
                            question:    faq.question,
                            answer:      faq.answer,
                            showDivider: i < _faqs.length - 1,
                          );
                        }),
                      ]),
                    ),

                    // ── Contact card ────────────────────────────────────
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Column(children: [
                        Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 28.sp),
                        SizedBox(height: 8.h),
                        Text('Still have a question?',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4.h),
                        Text("We're here to help. Reach out to us:",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('admin@back2eat.com',
                              style: TextStyle(fontSize: 13.sp,
                                  fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ),
                      ]),
                    ),

                    SizedBox(height: 18.h),

                    // ── App info ────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44.w, height: 44.w,
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16.r)),
                          child: const Icon(Icons.info_outline, color: Colors.black54),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(child: Text(
                          'Back2Eat is dine-in & take-away only.\nNo home delivery.',
                          style: TextStyle(fontSize: 12.sp, color: AppColors.muted,
                              fontWeight: FontWeight.w700, height: 1.3),
                        )),
                      ]),
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

  // ── Logout ──────────────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44.w, height: 5.h,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999))),
          SizedBox(height: 16.h),
          Text('Logout', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 8.h),
          Text('Are you sure you want to sign out?', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
          SizedBox(height: 18.h),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )),
            SizedBox(width: 12.w),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const AuthLogoutEvent());
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
  }

  // ── Delete Account ──────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(width: 44.w, height: 5.h,
                decoration: BoxDecoration(color: AppColors.line,
                    borderRadius: BorderRadius.circular(999))),
            SizedBox(height: 18.h),

            // Warning icon
            Container(
              width: 60.w, height: 60.w,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever_rounded,
                  color: AppColors.danger, size: 30.sp),
            ),
            SizedBox(height: 12.h),

            Text('Delete Account?',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text(
              'This will permanently delete your account, order history, and all associated data. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: AppColors.muted,
                  fontWeight: FontWeight.w600, height: 1.5),
            ),
            SizedBox(height: 16.h),

            // Reason text field
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason for deletion (optional)',
                hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
            SizedBox(height: 16.h),

            // Buttons
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('Cancel'),
              )),
              SizedBox(width: 12.w),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final reason = reasonCtrl.text.trim();
                  Navigator.pop(context);
                  await _deleteAccount(context, reason);
                },
                child: Text('Delete Account',
                    style: TextStyle(color: Colors.white,
                        fontSize: 13.sp, fontWeight: FontWeight.w900)),
              )),
            ]),

            SizedBox(height: 8.h),
            Text('You will be signed out immediately.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, color: AppColors.muted,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, String reason) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await getIt<ApiClient>().post('/account-deletion/request', {
        if (reason.isNotEmpty) 'reason': reason,
      });

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner
        // Show scheduled message then log out
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text(
            'Deletion scheduled. You can cancel within 7 days.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ));
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          context.read<AuthBloc>().add(const AuthLogoutEvent());
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text(
            'Could not request deletion. Contact admin@back2eat.com',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ));
      }
    }
  }
}

// ── Cancel Deletion Tile ──────────────────────────────────────────────────────
// Shows only if user has a pending deletion request.
// Calls GET /account-deletion/status to check, then DELETE to cancel.

class _CancelDeletionTile extends StatefulWidget {
  @override
  State<_CancelDeletionTile> createState() => _CancelDeletionTileState();
}

class _CancelDeletionTileState extends State<_CancelDeletionTile> {
  bool _hasPending  = false;
  bool _loadingCancel = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final data = await getIt<ApiClient>().get('/account-deletion/status');
      if (mounted) {
        setState(() => _hasPending = data['pending'] == true ||
            data['scheduledAt'] != null);
      }
    } catch (_) {
      // Not all backends have /status — silently ignore
    }
  }

  Future<void> _cancel() async {
    setState(() => _loadingCancel = true);
    try {
      await getIt<ApiClient>().post('/account-deletion/cancel', {});
      if (mounted) {
        setState(() { _hasPending = false; _loadingCancel = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Account deletion cancelled.',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCancel = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not cancel deletion.',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPending) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(children: [
        Container(
          width: 44.w, height: 44.w,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.schedule_rounded,
              color: AppColors.warning, size: 22.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Deletion Scheduled',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900,
                  color: AppColors.warning)),
          SizedBox(height: 3.h),
          Text('Your account will be deleted in 7 days. Tap to cancel.',
              style: TextStyle(fontSize: 11.sp, color: AppColors.warning,
                  fontWeight: FontWeight.w600)),
        ])),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: _loadingCancel ? null : _cancel,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: _loadingCancel
                ? SizedBox(width: 14.w, height: 14.w,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Text('Undo',
                style: TextStyle(fontSize: 12.sp,
                    fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

// ── Recent Orders ─────────────────────────────────────────────────────────────

class _RecentOrders extends StatefulWidget {
  @override
  State<_RecentOrders> createState() => _RecentOrdersState();
}

class _RecentOrdersState extends State<_RecentOrders> {
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo   = getIt<OrderRepository>();
      final orders = await repo.getMyOrders();
      if (mounted) setState(() {
        _orders  = orders.take(3).cast<OrderModel>().toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 80.h,
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(18.r)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(children: [
          Icon(Icons.receipt_long_outlined, color: AppColors.muted, size: 28.sp),
          SizedBox(width: 12.w),
          Text('No orders yet', style: TextStyle(
              fontSize: 13.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ]),
      );
    }

    return Column(
      children: _orders.map((order) {
        final statusColor = _statusColor(order.status);
        final statusBg    = _statusBg(order.status);
        return GestureDetector(
          onTap: () => context.push('/order-tracking', extra: order.id),
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Container(
                width: 44.w, height: 44.w,
                decoration: BoxDecoration(color: AppColors.soft,
                    borderRadius: BorderRadius.circular(14.r)),
                child: Icon(
                  order.orderType == 'DINE_IN'
                      ? Icons.table_restaurant_rounded
                      : order.orderType == 'TABLE_BOOKING'
                      ? Icons.event_seat_rounded
                      : Icons.takeout_dining_rounded,
                  color: AppColors.primary, size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.restaurantName,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3.h),
                Text(
                  '${order.items.length} item${order.items.length != 1 ? "s" : ""} · ₹${order.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.muted,
                      fontWeight: FontWeight.w600),
                ),
                if (order.scheduledTime != null && order.scheduledTime!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Row(children: [
                    Icon(Icons.schedule_rounded, size: 11.sp, color: AppColors.warning),
                    SizedBox(width: 3.w),
                    Text(order.scheduledTime!, style: TextStyle(
                        fontSize: 11.sp, color: AppColors.warning, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ])),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: statusBg,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(_statusLabel(order.status), style: TextStyle(
                    fontSize: 10.sp, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'CREATED':
      case 'ACCEPTED':  return AppColors.warning;
      case 'PREPARING': return AppColors.info;
      case 'READY':
      case 'COMPLETED': return AppColors.success;
      case 'CANCELLED': return AppColors.danger;
      default:          return AppColors.muted;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'CREATED':
      case 'ACCEPTED':  return AppColors.warningSoft;
      case 'PREPARING': return AppColors.infoSoft;
      case 'READY':
      case 'COMPLETED': return AppColors.successSoft;
      case 'CANCELLED': return AppColors.dangerSoft;
      default:          return AppColors.soft;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'CREATED':   return 'Placed';
      case 'ACCEPTED':  return 'Accepted';
      case 'PREPARING': return 'Preparing';
      case 'READY':     return 'Ready';
      case 'COMPLETED': return 'Done';
      case 'CANCELLED': return 'Cancelled';
      default:          return s;
    }
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final String     title;
  final String     subtitle;
  final IconData   icon;
  final VoidCallback onTap;
  final bool       isDestructive;

  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Ink(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 44.w, height: 44.w,
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withOpacity(0.10)
                  : AppColors.soft,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon,
                color: isDestructive ? Colors.red : AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(
                fontSize: 14.sp, fontWeight: FontWeight.w900,
                color: isDestructive ? Colors.red : null)),
            SizedBox(height: 4.h),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
          ])),
          Icon(Icons.chevron_right,
              color: isDestructive ? Colors.red : null),
        ]),
      ),
    );
  }
}

// ── FAQ Tile ──────────────────────────────────────────────────────────────────

class _FaqTile extends StatefulWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.showDivider,
  });
  final String question;
  final String answer;
  final bool   showDivider;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(widget.question,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800))),
            SizedBox(width: 8.w),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _expanded ? 0.5 : 0,
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted, size: 20.sp),
            ),
          ]),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          child: Text(widget.answer,
              style: TextStyle(fontSize: 12.sp, color: AppColors.muted,
                  fontWeight: FontWeight.w600, height: 1.5)),
        ),
        crossFadeState: _expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
      if (widget.showDivider)
        Divider(height: 1, indent: 14.w, endIndent: 14.w, color: AppColors.line),
    ]);
  }
}