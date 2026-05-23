// 📱 CUSTOMER APP
// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../shared/services/location_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../order_type/presentation/cubit/order_type_cubit.dart';
import '../../domain/entities/restaurant.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_event.dart';
import '../bloc/restaurant_state.dart';
import '../widgets/branch_picker_sheet.dart';
import '../widgets/category_bubble.dart';
import '../../data/datasources/restaurant_remote_datasource.dart';
import '../widgets/partner_card.dart';
import '../widgets/restaurant_feed_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ValueNotifier<String> _selected   = ValueNotifier<String>('All');
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<String> _query      = ValueNotifier<String>('');
  final ScrollController      _scrollCtrl = ScrollController();

  bool    _vegOnly         = false;
  String? _detectedCity;
  String? _selectedCity;
  bool    _locationLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AuthBloc>().add(const AuthCheckSessionEvent());
    _detectLocationAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selected.dispose(); _query.dispose();
    _searchCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRestaurants();
  }

  // ── Auto detect city from GPS ─────────────────────────────────────────────
  Future<void> _detectLocationAndLoad() async {
    setState(() => _locationLoading = true);
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        // Use geocoding package to reverse geocode lat/lng → city
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final p    = placemarks.first;
          // locality = city (e.g. "Bhuj"), subAdministrativeArea = district
          final city = (p.locality?.trim().isNotEmpty == true)
              ? p.locality!.trim()
              : (p.subAdministrativeArea?.trim().isNotEmpty == true)
              ? p.subAdministrativeArea!.trim()
              : null;
          if (city != null) {
            setState(() {
              _detectedCity = city;
              _selectedCity = city;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[Location] Reverse geocode failed: $e');
    }
    setState(() => _locationLoading = false);
    _loadRestaurants();
  }

  void _loadRestaurants() {
    context.read<RestaurantBloc>().add(
      LoadRestaurantsEvent(city: _selectedCity),
    );
  }

  // ── City picker bottom sheet ──────────────────────────────────────────────
  void _showCityPicker(List<Restaurant> allRestaurants) {
    final cities = allRestaurants
        .map((r) => r.city ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final ctrl = TextEditingController(text: _selectedCity ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 44.w, height: 5.h,
                  decoration: BoxDecoration(color: AppColors.line,
                      borderRadius: BorderRadius.circular(99))),
              SizedBox(height: 16.h),
              Row(children: [
                Expanded(child: Text('Select Location',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900))),
                if (_detectedCity != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedCity = _detectedCity);
                      _loadRestaurants();
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.my_location_rounded,
                        size: 14.sp, color: AppColors.primary),
                    label: Text('Use GPS',
                        style: TextStyle(fontSize: 12.sp,
                            color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
              ]),
              SizedBox(height: 12.h),
              // Manual city entry
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                onSubmitted: (v) {
                  final city = v.trim();
                  if (city.isNotEmpty) {
                    setState(() => _selectedCity = city);
                    _loadRestaurants();
                    Navigator.pop(context);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Type your city name...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.check_circle_rounded,
                        color: AppColors.primary),
                    onPressed: () {
                      final city = ctrl.text.trim();
                      if (city.isNotEmpty) {
                        setState(() => _selectedCity = city);
                        _loadRestaurants();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              if (cities.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Available cities',
                      style: TextStyle(fontSize: 12.sp,
                          color: AppColors.muted, fontWeight: FontWeight.w700)),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w, runSpacing: 8.h,
                  children: [
                    // All cities chip
                    _CityChip(
                      label: 'All Cities',
                      selected: _selectedCity == null,
                      onTap: () {
                        setState(() => _selectedCity = null);
                        _loadRestaurants();
                        Navigator.pop(context);
                      },
                    ),
                    ...cities.map((city) => _CityChip(
                      label: city,
                      selected: _selectedCity == city,
                      onTap: () {
                        setState(() => _selectedCity = city);
                        _loadRestaurants();
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ],
              SizedBox(height: 8.h),
            ]),
          ),
        ),
      ),
    );
  }

  List<Restaurant> _filterRestaurants({
    required List<Restaurant> all,
    required String selected,
    required String query,
    required bool vegOnly,
  }) {
    final q = query.trim().toLowerCase();
    return all.where((r) {
      final matchesQuery = q.isEmpty
          ? true
          : (r.name.toLowerCase().contains(q) ||
          r.categories.any((c) => c.toLowerCase().contains(q)));
      final matchesSelected = selected == 'All'
          ? true
          : r.categories.any(
              (c) => c.trim().toLowerCase() == selected.trim().toLowerCase());
      return matchesQuery && matchesSelected;
    }).toList();
  }

  void _scrollToTop() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(0,
        duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _query.value = '';
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<RestaurantBloc, RestaurantState>(
          builder: (context, state) {
            if (state is RestaurantLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RestaurantError) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(state.message), SizedBox(height: 12.h),
                ElevatedButton(
                    onPressed: _loadRestaurants, child: const Text('Retry')),
              ]));
            }
            if (state is! RestaurantLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final all           = state.restaurants;
            final allCategories = <(String, int)>[('All', 0), ...state.categories];

            return ValueListenableBuilder<String>(
              valueListenable: _selected,
              builder: (_, selected, __) {
                return ValueListenableBuilder<String>(
                  valueListenable: _query,
                  builder: (_, query, __) {
                    final filtered = _filterRestaurants(
                        all: all, selected: selected,
                        query: query, vegOnly: _vegOnly);

                    final bestPartners = state.featuredRestaurants.isNotEmpty
                        ? state.featuredRestaurants
                        : filtered.take(4).toList();
                    final isFeatured = state.featuredRestaurants.isNotEmpty;

                    return RefreshIndicator(
                      onRefresh: _detectLocationAndLoad,
                      child: CustomScrollView(
                        controller: _scrollCtrl,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [

                          // ── Sticky header ────────────────────────────────
                          SliverAppBar(
                            pinned: true,
                            backgroundColor: Colors.white,
                            elevation: 0,
                            toolbarHeight: 0,
                            collapsedHeight: isTablet ? 168.h : 152.h,
                            flexibleSpace: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                    16.w, 10.h, 16.w, 12.h),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(children: [
                                        Expanded(child: AppTextField(
                                          hint: 'Search on Back2Eat',
                                          prefix: const Icon(Icons.search,
                                              color: Color(0xFF9A9A9A)),
                                          controller: _searchCtrl,
                                          onChanged: (v) => _query.value = v,
                                        )),
                                        SizedBox(width: 12.w),
                                        if (query.trim().isNotEmpty) ...[
                                          GestureDetector(
                                            onTap: _clearSearch,
                                            child: Container(
                                                height: 44.h, width: 44.h,
                                                decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.06),
                                                    borderRadius:
                                                    BorderRadius.circular(14.r)),
                                                child: const Icon(Icons.close,
                                                    color: Colors.black87)),
                                          ),
                                          SizedBox(width: 10.w),
                                        ],
                                        GestureDetector(
                                          onTap: () => _showFilterSheet(context),
                                          child: Container(
                                              height: 44.h, width: 44.h,
                                              decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                  BorderRadius.circular(14.r)),
                                              child: const Icon(Icons.tune,
                                                  color: Colors.white)),
                                        ),
                                      ]),
                                      SizedBox(height: 14.h),
                                      Row(children: [
                                        InkWell(
                                          onTap: _scrollToTop,
                                          borderRadius: BorderRadius.circular(12.r),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 4.h, horizontal: 2.w),
                                            child: SizedBox(
                                                height: isTablet ? 36.h : 28.h,
                                                child: Image.asset(
                                                    'assets/images/brand/back2eat_logo.png',
                                                    fit: BoxFit.contain)),
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            BlocBuilder<AuthBloc, AuthState>(
                                              builder: (_, authState) {
                                                String name = 'User';
                                                if (authState
                                                is AuthAuthenticated) {
                                                  final full = authState.user.name
                                                      ?.trim() ??
                                                      '';
                                                  if (full.isNotEmpty) {
                                                    name = full.split(' ').first;
                                                  }
                                                }
                                                return Text('Hello, $name',
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: isTablet
                                                            ? 16.sp
                                                            : 14.sp,
                                                        fontWeight:
                                                        FontWeight.w900,
                                                        color: AppColors.text));
                                              },
                                            ),
                                            SizedBox(height: 2.h),
                                            Text('Dine-In & Take-Away',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.muted)),
                                          ],
                                        )),
                                        IconButton(
                                            onPressed: () =>
                                                context.push('/cart'),
                                            icon: const Icon(
                                                Icons.shopping_bag_outlined)),
                                        IconButton(
                                            onPressed: () =>
                                                context.push('/profile'),
                                            icon: const Icon(
                                                Icons.person_outline)),
                                      ]),
                                    ]),
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(child: SizedBox(height: 10.h)),

                          // ── Order type ───────────────────────────────────
                          SliverToBoxAdapter(child: Padding(
                              padding:
                              EdgeInsets.symmetric(horizontal: 16.w),
                              child: const _OrderTypeRow())),
                          SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                          // ── Veg Only (left) + Location (right) ───────────
                          SliverToBoxAdapter(child: Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(children: [
                              _VegOnlyToggle(
                                value: _vegOnly,
                                onToggle: (v) =>
                                    setState(() => _vegOnly = v),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _showCityPicker(all),
                                child: AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 160),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: _selectedCity != null
                                        ? AppColors.primary.withOpacity(0.08)
                                        : Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(99),
                                    border: Border.all(
                                      color: _selectedCity != null
                                          ? AppColors.primary
                                          : AppColors.line,
                                      width:
                                      _selectedCity != null ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _locationLoading
                                            ? SizedBox(
                                          width: 14.w,
                                          height: 14.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: AppColors.primary,
                                          ),
                                        )
                                            : Icon(
                                          _selectedCity != null
                                              ? Icons.location_on_rounded
                                              : Icons
                                              .location_searching_rounded,
                                          size: 14.sp,
                                          color: _selectedCity != null
                                              ? AppColors.primary
                                              : AppColors.muted,
                                        ),
                                        SizedBox(width: 5.w),
                                        Text(
                                          _locationLoading
                                              ? 'Detecting...'
                                              : (_selectedCity ?? 'Set Location'),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                            color: _selectedCity != null
                                                ? AppColors.primary
                                                : AppColors.muted,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 14.sp,
                                            color: _selectedCity != null
                                                ? AppColors.primary
                                                : AppColors.muted),
                                      ]),
                                ),
                              ),
                            ]),
                          )),
                          SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                          // ── Coming Soon OR normal content ────────────────
                          if (all.isEmpty && _selectedCity != null && !_locationLoading)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _ComingSoonPage(
                                city: _selectedCity!,
                                onShowAll: () {
                                  setState(() => _selectedCity = null);
                                  _loadRestaurants();
                                },
                              ),
                            )
                          else ...[

                            // Categories
                            SliverToBoxAdapter(child: SectionHeader(
                                title: 'Category',
                                action: 'See all',
                                onAction: () =>
                                    context.push('/categories'))),
                            SliverToBoxAdapter(child: SizedBox(
                              height: 110.h,
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w),
                                scrollDirection: Axis.horizontal,
                                itemCount: allCategories.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 14.w),
                                itemBuilder: (_, i) {
                                  final title = allCategories[i].$1;
                                  final count = allCategories[i].$2;
                                  return RepaintBoundary(
                                      child: CategoryBubble(
                                        title: title,
                                        selected: selected == title,
                                        itemCount:
                                        title == 'All' ? null : count,
                                        onTap: () {
                                          _selected.value = title;
                                          if (title != 'All') {
                                            context.push(
                                                '/partners?category=$title');
                                          }
                                        },
                                      ));
                                },
                              ),
                            )),
                            SliverToBoxAdapter(
                                child: SizedBox(height: 18.h)),

                            // Best Partners
                            SliverToBoxAdapter(child: Row(children: [
                              Padding(
                                padding: EdgeInsets.only(left: 16.w),
                                child: Row(children: [
                                  Text('Best Partners',
                                      style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w900)),
                                  if (isFeatured) ...[
                                    SizedBox(width: 6.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 7.w, vertical: 3.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3CD),
                                        borderRadius:
                                        BorderRadius.circular(99),
                                        border: Border.all(
                                            color: const Color(0xFFFFD700)
                                                .withOpacity(0.5)),
                                      ),
                                      child: Text('⭐ Promoted',
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(
                                                  0xFF856404))),
                                    ),
                                  ],
                                ]),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => context.push('/partners'),
                                child: Padding(
                                  padding: EdgeInsets.only(right: 16.w),
                                  child: Text('See all',
                                      style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                ),
                              ),
                            ])),
                            SliverToBoxAdapter(
                                child: SizedBox(height: 10.h)),
                            SliverToBoxAdapter(child: SizedBox(
                              height: 210.h,
                              child: bestPartners.isEmpty
                                  ? Center(
                                  child: Text('No restaurants yet',
                                      style: TextStyle(
                                          fontSize: 13.sp,
                                          color: AppColors.muted)))
                                  : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w),
                                scrollDirection: Axis.horizontal,
                                itemCount: bestPartners.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 14.w),
                                itemBuilder: (_, i) {
                                  final r = bestPartners[i];
                                  return SizedBox(
                                    width:
                                    isTablet ? 320.w : 260.w,
                                    height: 200.h,
                                    child: PartnerCard(
                                      name: r.name,
                                      rating: r.rating,
                                      km: r.distanceKm,
                                      isOpen: r.isOpen,
                                      readyInMins: r.prepTimeMins,
                                      coverUrl: r.coverUrl,
                                      logoUrl: r.logoUrl,
                                      city: r.city,
                                      dineInEnabled: r.dineInEnabled,
                                      takeawayEnabled:
                                      r.takeawayEnabled,
                                      tableBookingEnabled:
                                      r.tableBookingEnabled,
                                      onTap: () =>
                                          _navigateToRestaurant(
                                              context,
                                              r.id,
                                              r.name),
                                    ),
                                  );
                                },
                              ),
                            )),
                            SliverToBoxAdapter(
                                child: SizedBox(height: 30.h)),

                            // Feed
                            if (filtered.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 24.h),
                                  child: Center(
                                      child: Text(
                                        query.trim().isEmpty
                                            ? 'No restaurants found for "$selected"'
                                            : 'No results for "${query.trim()}"',
                                        style: TextStyle(
                                            fontSize: 13.sp,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      )),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                    16.w, 0, 16.w, 90.h),
                                sliver: SliverList.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: 18.h),
                                  itemBuilder: (_, i) {
                                    final r = filtered[i];
                                    return RestaurantFeedCard(
                                      name: r.name,
                                      rating: r.rating,
                                      km: r.distanceKm,
                                      isOpen: r.isOpen,
                                      categories: r.categories,
                                      readyInMins: r.prepTimeMins,
                                      coverUrl: r.coverUrl,
                                      logoUrl: r.logoUrl,
                                      city: r.city,
                                      dineInEnabled: r.dineInEnabled,
                                      takeawayEnabled: r.takeawayEnabled,
                                      tableBookingEnabled:
                                      r.tableBookingEnabled,
                                      onTap: () => _navigateToRestaurant(
                                          context, r.id, r.name),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _navigateToRestaurant(
      BuildContext context, String restaurantId, String restaurantName) async {
    final ds       = getIt<RestaurantRemoteDatasource>();
    final branches = await ds.getPublicBranches(restaurantId);
    if (!context.mounted) return;
    if (branches.isEmpty || branches.length == 1) {
      context.push('/restaurant/$restaurantId',
          extra: branches.isNotEmpty ? branches.first.id : null);
      return;
    }
    final picked = await showBranchPicker(
      context: context,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
    if (picked != null && context.mounted) {
      context.push('/restaurant/$restaurantId', extra: picked.id);
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24.r))),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 44.w, height: 5.h,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999))),
          SizedBox(height: 16.h),
          Text('Filter',
              style: TextStyle(
                  fontSize: 18.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 10.h),
          Text(
              'Back2Eat has no home delivery.\nFilter by rating, distance, and category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 16.h),
          Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: const ['Top Rated', 'Near Me', 'Open Now']
                  .map((t) => _Chip(text: t))
                  .toList()),
          SizedBox(height: 16.h),
          SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Apply',
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900)))),
        ]),
      ),
    );
  }
}

// ── Coming Soon Page ──────────────────────────────────────────────────────────

class _ComingSoonPage extends StatelessWidget {
  final String       city;
  final VoidCallback onShowAll;
  const _ComingSoonPage({required this.city, required this.onShowAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 140.w, height: 140.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_city_rounded,
                size: 64.sp, color: AppColors.primary.withOpacity(0.6)),
          ),
          SizedBox(height: 28.h),
          Text('Coming Soon to $city! 🚀',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          SizedBox(height: 12.h),
          Text(
            "We're working hard to bring Back2Eat to your city. "
                'Stay tuned — restaurants will be available soon!',
            style: TextStyle(fontSize: 14.sp, color: AppColors.muted,
                fontWeight: FontWeight.w600, height: 1.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity, height: 52.h,
            child: ElevatedButton.icon(
              onPressed: onShowAll,
              icon: Icon(Icons.explore_rounded, size: 18.sp),
              label: Text('Explore All Cities',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => context.push('/profile'),
            child: Text('Get notified when we launch',
                style: TextStyle(fontSize: 13.sp, color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── City Chip ─────────────────────────────────────────────────────────────────

class _CityChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  const _CityChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.12) : AppColors.soft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 12.sp, fontWeight: FontWeight.w800,
          color: selected ? AppColors.primary : AppColors.text)),
    ),
  );
}

// ── Veg Only Toggle ───────────────────────────────────────────────────────────

class _VegOnlyToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onToggle;
  const _VegOnlyToggle({required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
            color: value ? AppColors.success.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: value ? AppColors.success : AppColors.line,
                width: value ? 1.5 : 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 14.w, height: 14.w,
            decoration: BoxDecoration(
                border:
                Border.all(color: AppColors.success, width: 1.5),
                borderRadius: BorderRadius.circular(2.r)),
            child: Center(
                child: Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success))),
          ),
          SizedBox(width: 7.w),
          Text('Veg Only',
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color:
                  value ? AppColors.success : AppColors.muted)),
        ]),
      ),
    );
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: TextStyle(
              fontSize: 12.sp, fontWeight: FontWeight.w800)));
}

class _OrderTypeRow extends StatelessWidget {
  const _OrderTypeRow();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderTypeCubit, OrderType>(
      builder: (_, type) => Row(children: [
        const Icon(Icons.storefront, color: AppColors.primary),
        SizedBox(width: 10.w),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Type',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF8F8F8F))),
                  SizedBox(height: 2.h),
                  Text(
                      type == OrderType.dineIn ? 'Dine-In' : 'Take-Away',
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w900)),
                ])),
        _Pill(
            text: 'Dine-In',
            selected: type == OrderType.dineIn,
            onTap: () =>
                context.read<OrderTypeCubit>().set(OrderType.dineIn)),
        SizedBox(width: 8.w),
        _Pill(
            text: 'Take-Away',
            selected: type == OrderType.takeAway,
            onTap: () => context
                .read<OrderTypeCubit>()
                .set(OrderType.takeAway)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.text,
        required this.selected,
        required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(999)),
          child: Text(text,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : AppColors.text))));
}