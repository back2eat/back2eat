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
    void _showOrderTypeSheet(BuildContext context, OrderType current) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: false,
        builder: (_) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Order Type',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Back2Eat has no home delivery.',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 14.h),

                _OrderTypeOptionTile(
                  title: 'Dine-In',
                  subtitle: 'Eat at the restaurant',
                  icon: Icons.storefront,
                  selected: current == OrderType.dineIn,
                  onTap: () {
                    context.read<OrderTypeCubit>().set(OrderType.dineIn);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 10.h),
                _OrderTypeOptionTile(
                  title: 'Take-Away',
                  subtitle: 'Pickup from restaurant',
                  icon: Icons.shopping_bag_outlined,
                  selected: current == OrderType.takeAway,
                  onTap: () {
                    context.read<OrderTypeCubit>().set(OrderType.takeAway);
                    Navigator.pop(context);
                  },
                ),

                SizedBox(height: 14.h),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final hasItems = state.items.isNotEmpty;

            return Stack(
              children: [
                Column(
                  children: [
                    // ✅ Custom header (pixel stable + logo)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                      child: Row(
                        children: [
                          _HeaderIcon(
                            icon: Icons.arrow_back,
                            onTap: () => context.pop(),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  height: isTablet ? 30.h : 24.h,
                                  child: Image.asset(
                                    'assets/images/brand/back2eat_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    'Cart',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasItems) ...[
                            SizedBox(width: 8.w),
                            _HeaderTextButton(
                              text: 'Clear',
                              onTap: () => context.read<CartBloc>().add(const ClearCartEvent()),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ✅ Order Type banner
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                      child: BlocBuilder<OrderTypeCubit, OrderType>(
                        builder: (_, type) {
                          return Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.soft2,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(color: AppColors.line.withOpacity(0.6)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38.w,
                                  height: 38.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: const Icon(Icons.storefront, color: AppColors.primary),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Type',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        type == OrderType.dineIn ? 'Dine-In' : 'Take-Away',
                                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                                _OrderTypePill(
                                  type: type,
                                  onTap: () => _showOrderTypeSheet(context, type),
                                ),                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // ✅ Content
                    Expanded(
                      child: hasItems
                          ? ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16.w,
                          0,
                          16.w,
                          // leave space for bottom bar
                          110.h,
                        ),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (_, i) {
                          final item = state.items[i];
                          return _CartItemCard(
                            name: item.name,
                            restaurantName: item.restaurantName,
                            price: item.price,
                            qty: item.qty,
                            onMinus: () => context.read<CartBloc>().add(DecreaseQtyEvent(item.menuItemId)),
                            onPlus: () => context.read<CartBloc>().add(IncreaseQtyEvent(item.menuItemId)),
                          );
                        },
                      )
                          : _EmptyCart(
                        onBrowse: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),

                // ✅ Sticky bottom checkout bar
                if (hasItems)
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    bottom: 12.h,
                    child: _CheckoutBar(
                      total: state.total,
                      onCheckout: () => context.push('/checkout'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ----------------------------- Widgets ----------------------------- */

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Icon(icon, size: 22.sp, color: AppColors.text),
      ),
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _HeaderTextButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyCart({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86.w,
              height: 86.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Icon(Icons.shopping_bag_outlined, size: 36.sp, color: AppColors.primary),
            ),
            SizedBox(height: 14.h),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6.h),
            Text(
              'Add items from a partner restaurant to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Start browsing',
                onTap: onBrowse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final String name;
  final String restaurantName;
  final double price;
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CartItemCard({
    required this.name,
    required this.restaurantName,
    required this.price,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(Icons.fastfood, size: 26.sp, color: AppColors.text),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5.h),
                Text(
                  restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10.h),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _QtyControl(qty: qty, onMinus: onMinus, onPlus: onPlus),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double total;
  final VoidCallback onCheckout;

  const _CheckoutBar({required this.total, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: TextStyle(fontSize: 11.sp, color: AppColors.muted, fontWeight: FontWeight.w800)),
                SizedBox(height: 3.h),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            width: 170.w,
            height: 50.h,
            child: PrimaryButton(
              text: 'Checkout',
              onTap: onCheckout,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyControl({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onMinus,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
              child: const Icon(Icons.remove, size: 16),
            ),
          ),
          SizedBox(width: 10.w),
          Text('$qty', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
          SizedBox(width: 10.w),
          InkWell(
            onTap: onPlus,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10.r)),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}
class _OrderTypePill extends StatelessWidget {
  final OrderType type;
  final VoidCallback onTap;
  const _OrderTypePill({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = type == OrderType.dineIn ? 'Dine-In' : 'Take-Away';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line.withOpacity(0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp),
          ],
        ),
      ),
    );
  }
}

class _OrderTypeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OrderTypeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.soft2 : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected ? AppColors.primary.withOpacity(0.25) : AppColors.line.withOpacity(0.7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.soft,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}