import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../shared/services/location_service.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../order_type/presentation/cubit/order_type_cubit.dart';
import '../../domain/entities/restaurant.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_event.dart';
import '../bloc/restaurant_state.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String  restaurantId;
  final String? selectedBranchId; // pre-selected branch from picker
  const RestaurantDetailPage({
    super.key,
    required this.restaurantId,
    this.selectedBranchId,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  double? _distanceKm;
  bool    _distanceFetched = false;

  @override
  void initState() {
    super.initState();
    context.read<RestaurantBloc>().add(
      LoadRestaurantDetailEvent(
        restaurantId:      widget.restaurantId,
        selectedBranchId:  widget.selectedBranchId,
      ),
    );
  }

  @override
  void dispose() {
    // Reset allowed order types so home/checkout isn't restricted
    // after leaving this page
    try {
      context.read<OrderTypeCubit>().resetAllowedTypes();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _fetchDistance(double branchLat, double branchLng) async {
    if (_distanceFetched) return;
    _distanceFetched = true;
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position == null || !mounted) return;
      final dist = LocationService.distanceKm(
        position.latitude, position.longitude,
        branchLat, branchLng,
      );
      setState(() => _distanceKm = dist);
    } catch (_) {}
  }

  /// Returns the best distance label to show:
  /// 1. Live GPS distance if calculated
  /// 2. Pre-calculated distanceKm from datasource if > 0
  /// 3. City name if available
  /// 4. "Nearby" as last fallback
  String _distanceLabel(double storedKm, String? city) {
    if (_distanceKm != null) return '${_distanceKm!.toStringAsFixed(1)} km';
    if (storedKm > 0)        return '${storedKm.toStringAsFixed(1)} km';
    if (city != null && city.isNotEmpty) return city;
    return 'Nearby';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<RestaurantBloc, RestaurantState>(
          listener: (_, state) {
            if (state is RestaurantDetailLoaded) {
              final r = state.restaurant;
              if (r.latitude != null && r.longitude != null) {
                _fetchDistance(r.latitude!, r.longitude!);
              }
            }
          },
          builder: (_, state) {
            if (state is RestaurantLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RestaurantError) {
              return Center(child: Text(state.message));
            }
            if (state is! RestaurantDetailLoaded) return const SizedBox();

            final r    = state.restaurant;
            final menu = state.menuItems;

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // ── Cover image ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        height: 260.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.only(
                            bottomLeft:  Radius.circular(28.r),
                            bottomRight: Radius.circular(28.r),
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                bottomLeft:  Radius.circular(28.r),
                                bottomRight: Radius.circular(28.r),
                              ),
                              child: (r.coverUrl != null && r.coverUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                imageUrl: r.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _CoverPlaceholder(),
                                errorWidget: (_, __, ___) => _CoverPlaceholder(),
                              )
                                  : _CoverPlaceholder(),
                            ),
                            if (r.coverUrl != null && r.coverUrl!.isNotEmpty)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft:  Radius.circular(28.r),
                                    bottomRight: Radius.circular(28.r),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.15),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 16.w, top: 16.h,
                              child: _CircleIcon(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () {
                                  if (context.canPop()) context.pop();
                                  else context.go('/home');
                                },
                              ),
                            ),
                            Positioned(
                              right: 16.w, top: 16.h,
                              child: _CircleIcon(
                                icon: Icons.shopping_bag_outlined,
                                onTap: () => context.push('/cart'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                    // ── Restaurant info ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900)),
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 10.w, runSpacing: 10.h,
                              children: [
                                _InfoChip(icon: Icons.star,
                                    text: r.rating > 0 ? r.rating.toStringAsFixed(1) : 'New'),
                                _InfoChip(
                                  icon: Icons.location_on_outlined,
                                  text: _distanceLabel(r.distanceKm, r.city),
                                ),
                                _InfoChip(icon: Icons.timer_outlined,
                                    text: 'Ready in ${r.prepTimeMins} min'),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            // ── Service availability + order type row ──
                            _ServiceRow(restaurant: r),
                            SizedBox(height: 16.h),
                            Text('Menu',
                                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),
                    ),

                    // ── Menu list ─────────────────────────────────────────
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 120.h),
                      sliver: SliverList.separated(
                        itemCount: menu.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (ctx, i) {
                          final item = menu[i];
                          return BlocBuilder<CartBloc, CartState>(
                            builder: (context, cartState) {
                              final cartLine = cartState.items
                                  .where((x) => x.menuItemId == item.id)
                                  .firstOrNull;
                              final qty = cartLine?.qty ?? 0;
                              return _MenuCard(
                                title:       item.name,
                                description: item.description,
                                price:       item.price,
                                imageUrl:    item.imageUrl,
                                qty:         qty,
                                onAdd: () => context.read<CartBloc>().add(AddToCartEvent(
                                  restaurantId:   r.id,
                                  restaurantName: r.name,
                                  branchId:       state.branchId ?? '',
                                  menuItemId:     item.id,
                                  name:           item.name,
                                  price:          item.price,
                                )),
                                onIncrease: () => context.read<CartBloc>().add(IncreaseQtyEvent(item.id)),
                                onDecrease: () => context.read<CartBloc>().add(DecreaseQtyEvent(item.id)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // ── Sticky bottom CTA ──────────────────────────────────────
                Positioned(
                  left: 16.w, right: 16.w, bottom: 16.h,
                  child: PrimaryButton(text: 'Go to cart', onTap: () => context.push('/cart')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Menu Card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final String       title;
  final String       description;
  final double       price;
  final String?      imageUrl;
  final int          qty;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _MenuCard({
    required this.title, required this.description, required this.price,
    required this.qty,   required this.onAdd,       required this.onIncrease,
    required this.onDecrease, this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(width: 64.w, height: 64.w,
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover,
                placeholder: (_, __) => _ItemPlaceholder(),
                errorWidget: (_, __, ___) => _ItemPlaceholder())
                : _ItemPlaceholder(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 4.h),
          Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Text('₹${price.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ])),
        SizedBox(width: 10.w),
        qty == 0
            ? GestureDetector(onTap: onAdd, child: Container(
            width: 42.w, height: 42.w,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14.r)),
            child: const Icon(Icons.add, color: Colors.white)))
            : Container(
          height: 42.w,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14.r)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: onDecrease, child: SizedBox(width: 36.w, height: 42.w,
                child: const Icon(Icons.remove, color: Colors.white, size: 18))),
            Text('$qty', style: TextStyle(color: Colors.white,
                fontSize: 14.sp, fontWeight: FontWeight.w900)),
            GestureDetector(onTap: onIncrease, child: SizedBox(width: 36.w, height: 42.w,
                child: const Icon(Icons.add, color: Colors.white, size: 18))),
          ]),
        ),
      ]),
    );
  }
}

// ── Small Widgets ──────────────────────────────────────────────────────────────

// ── Service row — shows what's available + lets user switch order type ────────
class _ServiceRow extends StatelessWidget {
  final Restaurant restaurant;
  const _ServiceRow({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderTypeCubit, OrderType>(
      builder: (_, currentType) {
        final r = restaurant;

        // Auto-correct order type if current type is disabled for this restaurant
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Set allowed types on the cubit — also auto-switches if needed
          context.read<OrderTypeCubit>().setAllowedTypes(
            dineIn:       r.dineInEnabled,
            takeaway:     r.takeawayEnabled,
            tableBooking: r.tableBookingEnabled,
          );
        });

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Selectable chips ──────────────────────────────────────
          Wrap(spacing: 8.w, runSpacing: 6.h, children: [
            if (r.dineInEnabled)
              _OrderTypeChip(
                icon:     Icons.storefront_rounded,
                label:    'Dine-In',
                color:    AppColors.primary,
                selected: currentType == OrderType.dineIn,
                onTap:    () => context.read<OrderTypeCubit>().set(OrderType.dineIn),
              ),
            if (r.takeawayEnabled)
              _OrderTypeChip(
                icon:     Icons.shopping_bag_outlined,
                label:    'Takeaway',
                color:    const Color(0xFF2E7D32),
                selected: currentType == OrderType.takeAway,
                onTap:    () => context.read<OrderTypeCubit>().set(OrderType.takeAway),
              ),
            if (r.tableBookingEnabled)
              _OrderTypeChip(
                icon:     Icons.event_seat_rounded,
                label:    'Table Booking',
                color:    const Color(0xFF6A1B9A),
                selected: currentType == OrderType.tableBooking,
                onTap:    () => context.read<OrderTypeCubit>().set(OrderType.tableBooking),
              ),
          ]),
          SizedBox(height: 8.h),

          // ── Current selection label ───────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color:        AppColors.soft2,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(children: [
              Icon(_typeIcon(currentType), color: AppColors.primary, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(child: Text(
                _typeLabel(currentType),
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              )),
            ]),
          ),
        ]);
      },
    );
  }

  IconData _typeIcon(OrderType t) {
    switch (t) {
      case OrderType.dineIn:       return Icons.storefront_rounded;
      case OrderType.takeAway:     return Icons.shopping_bag_outlined;
      case OrderType.tableBooking: return Icons.event_seat_rounded;
    }
  }

  String _typeLabel(OrderType t) {
    switch (t) {
      case OrderType.dineIn:       return 'Dine-In — sit and enjoy your meal';
      case OrderType.takeAway:     return 'Takeaway — pick up at the counter';
      case OrderType.tableBooking: return 'Table Booking — reserve your table (+₹19)';
    }
  }
}

class _OrderTypeChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final bool selected; final VoidCallback onTap;
  const _OrderTypeChip({
    required this.icon, required this.label, required this.color,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: selected ? color.withOpacity(0.5) : Colors.black.withOpacity(0.08),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14.sp, color: selected ? color : AppColors.muted),
        SizedBox(width: 5.w),
        Text(label, style: TextStyle(
          fontSize: 12.sp, fontWeight: FontWeight.w800,
          color: selected ? color : AppColors.muted,
        )),
      ]),
    ),
  );
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFFEFEFEF),
      child: const Center(child: Icon(Icons.restaurant, size: 64, color: Colors.black26)));
}

class _ItemPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFFEFEFEF),
      child: const Icon(Icons.fastfood, size: 28, color: Colors.black38));
}

class _CircleIcon extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42.w, height: 42.w,
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, 6))]),
      child: Icon(icon, size: 20.sp),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16.sp, color: AppColors.primary),
      SizedBox(width: 6.w),
      Text(text, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800)),
    ]),
  );
}