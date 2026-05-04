import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../order_type/presentation/cubit/order_type_cubit.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final hasItems = state.items.isNotEmpty;

            return Stack(
              children: [
                Column(children: [

                  // ── Header ────────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                    child: Row(children: [
                      _HeaderIcon(icon: Icons.arrow_back, onTap: () => context.pop()),
                      SizedBox(width: 10.w),
                      Expanded(child: Row(children: [
                        SizedBox(
                          height: isTablet ? 30.h : 24.h,
                          child: Image.asset('assets/images/brand/back2eat_logo.png', fit: BoxFit.contain),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(child: Text('Cart',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.text))),
                      ])),
                      if (hasItems) ...[
                        SizedBox(width: 8.w),
                        _HeaderTextButton(
                          text: 'Clear',
                          onTap: () => context.read<CartBloc>().add(const ClearCartEvent()),
                        ),
                      ],
                    ]),
                  ),

                  // ── Order Type Banner ──────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
                    child: BlocBuilder<OrderTypeCubit, OrderType>(
                      builder: (context, type) {
                        final cubit   = context.read<OrderTypeCubit>();
                        final allowed = cubit.allowedTypes;
                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.soft2,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(color: AppColors.line.withOpacity(0.6)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                width: 38.w, height: 38.w,
                                decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
                                child: Icon(_typeIcon(type), color: AppColors.primary),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Order Type',
                                    style: TextStyle(fontSize: 11.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
                                SizedBox(height: 2.h),
                                Text(_typeLabel(type),
                                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                              ])),
                              _PillButton(
                                label: 'Change',
                                onTap: () => _showOrderTypeSheet(context, type, allowed),
                              ),
                            ]),

                            // Table booking info
                            if (type == OrderType.tableBooking) ...[
                              SizedBox(height: 10.h),
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: AppColors.infoSoft,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(color: AppColors.info.withOpacity(0.25)),
                                ),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 14.sp),
                                  SizedBox(width: 6.w),
                                  Expanded(child: Text(
                                    'Pay ₹19 upfront to reserve your table. '
                                        'Refundable if restaurant cancels. Non-refundable if you cancel.',
                                    style: TextStyle(fontSize: 11.sp, color: AppColors.info,
                                        fontWeight: FontWeight.w700, height: 1.4),
                                  )),
                                ]),
                              ),
                            ],
                          ]),
                        );
                      },
                    ),
                  ),

                  // ── Items ──────────────────────────────────────────────────
                  Expanded(
                    child: hasItems
                        ? ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 110.h),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (_, i) {
                        final item = state.items[i];
                        return _CartItemCard(
                          name:           item.name,
                          restaurantName: item.restaurantName,
                          price:          item.price,
                          qty:            item.qty,
                          onMinus: () => context.read<CartBloc>().add(DecreaseQtyEvent(item.menuItemId)),
                          onPlus:  () => context.read<CartBloc>().add(IncreaseQtyEvent(item.menuItemId)),
                        );
                      },
                    )
                        : _EmptyCart(onBrowse: () => context.go('/home')),
                  ),
                ]),

                // ── Sticky Bottom CTA ──────────────────────────────────────
                if (hasItems)
                  Positioned(
                    left: 16.w, right: 16.w, bottom: 12.h,
                    child: BlocBuilder<OrderTypeCubit, OrderType>(
                      builder: (context, type) {
                        final isTableBooking = type == OrderType.tableBooking;
                        return _CheckoutBar(
                          total:          state.total,
                          isTableBooking: isTableBooking,
                          onTap: () {
                            if (isTableBooking) {
                              // Pay ₹19 FIRST → booking created on payment success
                              context.push('/booking-pre-payment', extra: {
                                'restaurantId': state.items.first.restaurantId,
                                'branchId':     state.items.first.branchId,
                              });
                            } else {
                              context.push('/checkout');
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showOrderTypeSheet(BuildContext context, OrderType current, List<OrderType> allowed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44.w, height: 5.h,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999))),
          SizedBox(height: 14.h),
          Text('Order Type', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 4.h),
          Text('Back2Eat has no home delivery.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
          SizedBox(height: 16.h),

          if (allowed.contains(OrderType.dineIn)) ...[
            _OrderTypeOptionTile(
              title: 'Dine-In', subtitle: 'Eat at the restaurant', icon: Icons.storefront,
              selected: current == OrderType.dineIn,
              onTap: () { context.read<OrderTypeCubit>().set(OrderType.dineIn); Navigator.pop(context); },
            ),
            SizedBox(height: 10.h),
          ],
          if (allowed.contains(OrderType.takeAway)) ...[
            _OrderTypeOptionTile(
              title: 'Take-Away', subtitle: 'Pickup from restaurant', icon: Icons.shopping_bag_outlined,
              selected: current == OrderType.takeAway,
              onTap: () { context.read<OrderTypeCubit>().set(OrderType.takeAway); Navigator.pop(context); },
            ),
            SizedBox(height: 10.h),
          ],
          if (allowed.contains(OrderType.tableBooking))
            _OrderTypeOptionTile(
              title: 'Table Booking', subtitle: 'Reserve a table · ₹19 fee upfront',
              icon: Icons.event_seat_rounded,
              selected: current == OrderType.tableBooking,
              onTap: () { context.read<OrderTypeCubit>().set(OrderType.tableBooking); Navigator.pop(context); },
            ),
        ]),
      ),
    );
  }

  IconData _typeIcon(OrderType type) {
    switch (type) {
      case OrderType.dineIn:       return Icons.storefront;
      case OrderType.takeAway:     return Icons.shopping_bag_outlined;
      case OrderType.tableBooking: return Icons.event_seat_rounded;
    }
  }

  String _typeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:       return 'Dine-In';
      case OrderType.takeAway:     return 'Take-Away';
      case OrderType.tableBooking: return 'Table Booking (+₹19 upfront)';
    }
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(14.r),
    child: Container(
      width: 42.w, height: 42.w,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Icon(icon, size: 22.sp, color: AppColors.text),
    ),
  );
}

class _HeaderTextButton extends StatelessWidget {
  final String text; final VoidCallback onTap;
  const _HeaderTextButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: AppColors.text)),
    ),
  );
}

class _PillButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.soft, borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line.withOpacity(0.7)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900)),
        SizedBox(width: 4.w),
        Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp),
      ]),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyCart({required this.onBrowse});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 22.w),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 86.w, height: 86.w,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(26.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Icon(Icons.shopping_bag_outlined, size: 36.sp, color: AppColors.primary),
      ),
      SizedBox(height: 14.h),
      Text('Your cart is empty', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
      SizedBox(height: 6.h),
      Text('Add items from a partner restaurant to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.muted)),
      SizedBox(height: 14.h),
      SizedBox(width: double.infinity, child: PrimaryButton(text: 'Start browsing', onTap: onBrowse)),
    ])),
  );
}

class _CartItemCard extends StatelessWidget {
  final String name, restaurantName;
  final double price; final int qty;
  final VoidCallback onMinus, onPlus;
  const _CartItemCard({required this.name, required this.restaurantName,
    required this.price, required this.qty, required this.onMinus, required this.onPlus});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      Container(
        width: 56.w, height: 56.w,
        decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(16.r)),
        child: Icon(Icons.fastfood, size: 26.sp, color: AppColors.text),
      ),
      SizedBox(width: 12.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 5.h),
        Text(restaurantName, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
        SizedBox(height: 10.h),
        Text('₹${price.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ])),
      SizedBox(width: 10.w),
      _QtyControl(qty: qty, onMinus: onMinus, onPlus: onPlus),
    ]),
  );
}

class _QtyControl extends StatelessWidget {
  final int qty; final VoidCallback onMinus, onPlus;
  const _QtyControl({required this.qty, required this.onMinus, required this.onPlus});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onMinus, borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 28.w, height: 28.w,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
          child: const Icon(Icons.remove, size: 16),
        ),
      ),
      SizedBox(width: 10.w),
      Text('$qty', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
      SizedBox(width: 10.w),
      InkWell(
        onTap: onPlus, borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 28.w, height: 28.w,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10.r)),
          child: const Icon(Icons.add, size: 16, color: Colors.white),
        ),
      ),
    ]),
  );
}

class _CheckoutBar extends StatelessWidget {
  final double total; final bool isTableBooking; final VoidCallback onTap;
  const _CheckoutBar({required this.total, required this.isTableBooking, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 22, offset: const Offset(0, 8))],
    ),
    child: Row(children: [
      Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total', style: TextStyle(fontSize: 11.sp, color: AppColors.muted, fontWeight: FontWeight.w800)),
        SizedBox(height: 3.h),
        Text('₹${total.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
        if (isTableBooking)
          Text('+₹19 booking fee',
              style: TextStyle(fontSize: 10.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ])),
      SizedBox(width: 12.w),
      SizedBox(
        width: 170.w, height: 50.h,
        child: PrimaryButton(
          text: isTableBooking ? 'Pay ₹19 & Book' : 'Checkout',
          onTap: onTap,
        ),
      ),
    ]),
  );
}

class _OrderTypeOptionTile extends StatelessWidget {
  final String title, subtitle; final IconData icon;
  final bool selected; final VoidCallback onTap;
  const _OrderTypeOptionTile({required this.title, required this.subtitle,
    required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18.r),
    child: Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: selected ? AppColors.soft2 : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
            color: selected ? AppColors.primary.withOpacity(0.25) : AppColors.line.withOpacity(0.7)),
      ),
      child: Row(children: [
        Container(
          width: 44.w, height: 44.w,
          decoration: BoxDecoration(
              color: selected ? Colors.white : AppColors.soft,
              borderRadius: BorderRadius.circular(16.r)),
          child: Icon(icon, color: AppColors.primary),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 3.h),
          Text(subtitle, style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        if (selected)
          Container(
            width: 22.w, height: 22.w,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
      ]),
    ),
  );
}