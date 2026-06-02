// 📱 CUSTOMER APP
// lib/features/home/presentation/pages/restaurant_detail_page.dart

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
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_event.dart';
import '../bloc/restaurant_state.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String  restaurantId;
  final String? selectedBranchId;
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
  String  _searchQuery     = '';
  String? _selectedCategory;
  final   _searchCtrl = TextEditingController();
  final   _scrollCtrl = ScrollController();

  // Map of categoryName → list of items
  Map<String, List<MenuItem>> _grouped = {};
  List<String>                _catOrder = [];

  @override
  void initState() {
    super.initState();
    context.read<RestaurantBloc>().add(LoadRestaurantDetailEvent(
      restaurantId:     widget.restaurantId,
      selectedBranchId: widget.selectedBranchId,
    ));
  }

  @override
  void dispose() {
    try { context.read<OrderTypeCubit>().resetAllowedTypes(); } catch (_) {}
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDistance(double lat, double lng) async {
    if (_distanceFetched) return;
    _distanceFetched = true;
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos == null || !mounted) return;
      setState(() => _distanceKm = LocationService.distanceKm(
          pos.latitude, pos.longitude, lat, lng));
    } catch (_) {}
  }

  String _distanceLabel(double km, String? city) {
    if (_distanceKm != null)           return '${_distanceKm!.toStringAsFixed(1)} km';
    if (km > 0)                        return '${km.toStringAsFixed(1)} km';
    if (city != null && city.isNotEmpty) return city;
    return 'Nearby';
  }

  // Group menu items by category, preserving backend order
  void _buildGroups(List<MenuItem> items) {
    final map    = <String, List<MenuItem>>{};
    final order  = <String>[];
    for (final item in items) {
      final cat = item.categoryName?.isNotEmpty == true
          ? item.categoryName!
          : 'Other';
      if (!map.containsKey(cat)) {
        map[cat] = [];
        order.add(cat);
      }
      map[cat]!.add(item);
    }
    _grouped  = map;
    _catOrder = order;
    if (_selectedCategory == null && order.isNotEmpty) {
      _selectedCategory = order.first;
    }
  }

  // Filter items based on search query
  Map<String, List<MenuItem>> _filteredGroups() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _grouped;
    final result = <String, List<MenuItem>>{};
    for (final cat in _catOrder) {
      final filtered = (_grouped[cat] ?? [])
          .where((i) =>
      i.name.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q))
          .toList();
      if (filtered.isNotEmpty) result[cat] = filtered;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: true,
        child: BlocConsumer<RestaurantBloc, RestaurantState>(
          listener: (_, state) {
            if (state is RestaurantDetailLoaded) {
              final r = state.restaurant;
              if (r.latitude != null && r.longitude != null) {
                _fetchDistance(r.latitude!, r.longitude!);
              }
              setState(() => _buildGroups(state.menuItems));
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

            final r        = state.restaurant;
            final filtered = _filteredGroups();
            final cats     = filtered.keys.toList();

            return Stack(children: [
              CustomScrollView(
                controller: _scrollCtrl,
                slivers: [

                  // ── Cover ──────────────────────────────────────────────
                  SliverToBoxAdapter(child: _CoverSection(
                    restaurant: r,
                    onBack: () {
                      if (context.canPop()) context.pop();
                      else context.go('/home');
                    },
                    onCart: () => context.push('/cart'),
                  )),

                  SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                  // ── Info ───────────────────────────────────────────────
                  SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.name,
                          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900)),
                      SizedBox(height: 10.h),
                      Wrap(spacing: 10.w, runSpacing: 10.h, children: [
                        _InfoChip(icon: Icons.star,
                            text: r.rating > 0 ? r.rating.toStringAsFixed(1) : 'New'),
                        _InfoChip(icon: Icons.location_on_outlined,
                            text: _distanceLabel(r.distanceKm, r.city)),
                        _InfoChip(icon: Icons.timer_outlined,
                            text: 'Ready in ${r.prepTimeMins} min'),
                      ]),
                      SizedBox(height: 12.h),
                      _ServiceRow(restaurant: r),
                    ]),
                  )),

                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                  // ── Search bar ─────────────────────────────────────────
                  SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search in menu…',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.muted, size: 20.sp),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(Icons.close_rounded,
                                color: AppColors.muted, size: 18.sp))
                            : null,
                        filled: true,
                        fillColor: AppColors.soft,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                      ),
                    ),
                  )),

                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                  // ── Category tabs ──────────────────────────────────────
                  if (cats.isNotEmpty && _searchQuery.isEmpty)
                    SliverToBoxAdapter(child: SizedBox(
                      height: 36.h,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: _catOrder.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (_, i) {
                          final cat      = _catOrder[i];
                          final selected = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.soft,
                                borderRadius: BorderRadius.circular(99),
                                border: selected
                                    ? null
                                    : Border.all(color: AppColors.line),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.text,
                                  )),
                            ),
                          );
                        },
                      ),
                    )),

                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                  // ── Menu grouped by category ───────────────────────────
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(child: Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search_off_rounded,
                            size: 40.sp, color: AppColors.muted),
                        SizedBox(height: 10.h),
                        Text('No items found for "$_searchQuery"',
                            style: TextStyle(fontSize: 13.sp,
                                color: AppColors.muted, fontWeight: FontWeight.w700)),
                      ])),
                    ))
                  else
                  // When searching: show all matching categories
                  // When not searching: show only selected category
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 120.h),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (ctx, idx) {
                            final displayCats = _searchQuery.isNotEmpty
                                ? cats
                                : (_selectedCategory != null &&
                                filtered.containsKey(_selectedCategory)
                                ? [_selectedCategory!]
                                : cats);

                            if (idx >= displayCats.length) return null;
                            final cat   = displayCats[idx];
                            final items = filtered[cat] ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category header
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: idx == 0 ? 0 : 20.h, bottom: 10.h),
                                  child: Row(children: [
                                    Container(
                                      width: 4.w, height: 18.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(cat,
                                        style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900)),
                                    SizedBox(width: 8.w),
                                    Text('(${items.length})',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                                // Items in category
                                ...items.asMap().entries.map((entry) {
                                  final i    = entry.key;
                                  final item = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom: i < items.length - 1 ? 12.h : 0),
                                    child: BlocBuilder<CartBloc, CartState>(
                                      builder: (context, cartState) {
                                        final cartLine = cartState.items
                                            .where((x) => x.menuItemId == item.id)
                                            .firstOrNull;
                                        final qty = cartLine?.qty ?? 0;
                                        return _MenuCard(
                                          item: item,
                                          qty:  qty,
                                          onAdd: () => context
                                              .read<CartBloc>()
                                              .add(AddToCartEvent(
                                            restaurantId:   r.id,
                                            restaurantName: r.name,
                                            branchId:       state.branchId ?? '',
                                            menuItemId:     item.id,
                                            name:           item.name,
                                            price:          item.price,
                                          )),
                                          onIncrease: () => context
                                              .read<CartBloc>()
                                              .add(IncreaseQtyEvent(item.id)),
                                          onDecrease: () => context
                                              .read<CartBloc>()
                                              .add(DecreaseQtyEvent(item.id)),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                          childCount: _searchQuery.isNotEmpty
                              ? cats.length
                              : (_selectedCategory != null ? 1 : cats.length),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Sticky cart button ───────────────────────────────────────
              Positioned(
                left: 16.w, right: 16.w, bottom: 16.h,
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (_, cart) {
                    final count = cart.items.fold<int>(0, (s, i) => s + i.qty);
                    if (count == 0) {
                      return PrimaryButton(
                          text: 'Go to cart',
                          onTap: () => context.push('/cart'));
                    }
                    return GestureDetector(
                      onTap: () => context.push('/cart'),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 26.w, height: 26.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(child: Text('$count',
                                style: TextStyle(fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white))),
                          ),
                          SizedBox(width: 12.w),
                          Text('View Cart',
                              style: TextStyle(fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const Spacer(),
                          Text('₹${cart.total.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          SizedBox(width: 4.w),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14.sp, color: Colors.white),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ── Cover section ─────────────────────────────────────────────────────────────
class _CoverSection extends StatelessWidget {
  final Restaurant  restaurant;
  final VoidCallback onBack;
  final VoidCallback onCart;
  const _CoverSection({
    required this.restaurant,
    required this.onBack,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return Container(
      height: 260.h,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Stack(fit: StackFit.expand, children: [
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
        Positioned(left: 16.w, top: 52.h,
            child: _CircleIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack)),
        Positioned(right: 16.w, top: 52.h,
            child: _CircleIcon(icon: Icons.shopping_bag_outlined, onTap: onCart)),
      ]),
    );
  }
}

// ── Menu Card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final MenuItem     item;
  final int          qty;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _MenuCard({
    required this.item, required this.qty,
    required this.onAdd, required this.onIncrease, required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor       = item.isVeg ? AppColors.success : AppColors.danger;
    final hasDiscount    = item.hasDiscount;
    final effectivePrice = item.effectivePrice;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Veg / non-veg dot
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Container(
            width: 14.w, height: 14.w,
            decoration: BoxDecoration(
              border: Border.all(color: dotColor, width: 1.5),
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: Center(child: Container(
              width: 7.w, height: 7.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            )),
          ),
        ),
        SizedBox(width: 10.w),

        // Name + description + price
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
          if (item.description.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
          SizedBox(height: 6.h),
          // Price row — with or without discount
          if (hasDiscount) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Discounted (effective) price — shown in primary color
              Text('₹${effectivePrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
              SizedBox(width: 6.w),
              // Original price — strikethrough in muted
              Text('₹${item.price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600,
                      color: AppColors.muted, decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.muted)),
            ]),
            SizedBox(height: 3.h),
            // Discount label badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Text(item.discountLabel,
                  style: TextStyle(fontSize: 10.sp,
                      fontWeight: FontWeight.w800, color: AppColors.success)),
            ),
          ] else
            Text('₹${item.price.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 14.sp,
                    fontWeight: FontWeight.w900, color: AppColors.primary)),
        ])),

        SizedBox(width: 10.w),

        // Image + Add/qty button
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
                width: 72.w, height: 72.w, fit: BoxFit.cover,
                placeholder: (_, __) => _ItemPlaceholder(),
                errorWidget: (_, __, ___) => _ItemPlaceholder(),
              ),
            )
          else
            SizedBox(width: 72.w, height: 72.w, child: _ItemPlaceholder()),
          SizedBox(height: 6.h),
          // Add button or qty stepper
          qty == 0
              ? GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 72.w, height: 34.h,
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(10.r)),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 16.sp),
                SizedBox(width: 3.w),
                Text('Add', style: TextStyle(fontSize: 12.sp,
                    fontWeight: FontWeight.w900, color: Colors.white)),
              ])),
            ),
          )
              : Container(
            width: 100.w, height: 34.h,
            decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(10.r)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              GestureDetector(onTap: onDecrease,
                  child: SizedBox(width: 32.w, height: 34.h,
                      child: const Icon(Icons.remove_rounded, color: Colors.white, size: 16))),
              Text('$qty', style: TextStyle(fontSize: 13.sp,
                  fontWeight: FontWeight.w900, color: Colors.white)),
              GestureDetector(onTap: onIncrease,
                  child: SizedBox(width: 32.w, height: 34.h,
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 16))),
            ]),
          ),
        ]),
      ]),
    );
  }
}
// ── Service Row ───────────────────────────────────────────────────────────────
class _ServiceRow extends StatelessWidget {
  final Restaurant restaurant;
  const _ServiceRow({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderTypeCubit, OrderType>(
      builder: (_, currentType) {
        final r = restaurant;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<OrderTypeCubit>().setAllowedTypes(
            dineIn:       r.dineInEnabled,
            takeaway:     r.takeawayEnabled,
            tableBooking: r.tableBookingEnabled,
          );
        });
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8.w, runSpacing: 6.h, children: [
            if (r.dineInEnabled)
              _OrderTypeChip(
                icon: Icons.storefront_rounded, label: 'Dine-In',
                color: AppColors.primary,
                selected: currentType == OrderType.dineIn,
                onTap: () => context.read<OrderTypeCubit>().set(OrderType.dineIn),
              ),
            if (r.takeawayEnabled)
              _OrderTypeChip(
                icon: Icons.shopping_bag_outlined, label: 'Takeaway',
                color: const Color(0xFF2E7D32),
                selected: currentType == OrderType.takeAway,
                onTap: () => context.read<OrderTypeCubit>().set(OrderType.takeAway),
              ),
            if (r.tableBookingEnabled)
              _OrderTypeChip(
                icon: Icons.event_seat_rounded, label: 'Table Booking',
                color: const Color(0xFF6A1B9A),
                selected: currentType == OrderType.tableBooking,
                onTap: () => context.read<OrderTypeCubit>().set(OrderType.tableBooking),
              ),
          ]),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
                color: AppColors.soft2, borderRadius: BorderRadius.circular(12.r)),
            child: Row(children: [
              Icon(_typeIcon(currentType), color: AppColors.primary, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(child: Text(_typeLabel(currentType),
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700))),
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
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800,
            color: selected ? color : AppColors.muted)),
      ]),
    ),
  );
}

// ── Small Widgets ──────────────────────────────────────────────────────────────
class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFFEFEFEF),
      child: const Center(child: Icon(Icons.restaurant, size: 64, color: Colors.black26)));
}

class _ItemPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(
        color: const Color(0xFFEFEFEF),
        child: const Icon(Icons.fastfood, size: 28, color: Colors.black38)),
  );
}

class _CircleIcon extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42.w, height: 42.w,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
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