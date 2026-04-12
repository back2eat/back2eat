import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class RestaurantFeedCard extends StatelessWidget {
  final String        name;
  final double        rating;
  final double        km;
  final String?       city;
  final bool          isOpen;
  final List<String>  categories;
  final int           readyInMins;
  final VoidCallback  onTap;
  final String?       coverUrl;
  final String?       logoUrl;

  // Service flags
  final bool dineInEnabled;
  final bool takeawayEnabled;
  final bool tableBookingEnabled;

  const RestaurantFeedCard({
    super.key,
    required this.name,
    required this.rating,
    required this.km,
    this.city,
    required this.isOpen,
    required this.categories,
    required this.readyInMins,
    required this.onTap,
    this.coverUrl,
    this.logoUrl,
    this.dineInEnabled       = true,
    this.takeawayEnabled     = true,
    this.tableBookingEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cat        = categories.isEmpty ? 'Food' : categories.first;
    final imageToUse = coverUrl ?? logoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Column(children: [
          // ── Cover image ───────────────────────────────────────────
          ClipRRect(
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(18.r)),
            child: SizedBox(
              height: 150.h,
              width:  double.infinity,
              child: (imageToUse != null && imageToUse.isNotEmpty)
                  ? CachedNetworkImage(
                imageUrl:    imageToUse,
                fit:         BoxFit.cover,
                placeholder: (_, __) => _Placeholder(),
                errorWidget: (_, __, ___) => _Placeholder(),
              )
                  : _Placeholder(),
            ),
          ),

          // ── Info ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + open badge
                Row(children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:   15.sp,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 8.w, height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOpen ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize:   12.sp,
                      color:      isOpen ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]),

                SizedBox(height: 6.h),

                // Rating + category + distance + prep time
                Row(children: [
                  _RatingPill(rating: rating),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '$cat · ${km > 0 ? "${km.toStringAsFixed(1)} km" : (city != null && city!.isNotEmpty ? city! : "Nearby")}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:   12.sp,
                          color:      AppColors.muted,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(Icons.timer_outlined, size: 12.sp, color: AppColors.muted),
                  SizedBox(width: 2.w),
                  Text(
                    '${readyInMins}m',
                    style: TextStyle(
                        fontSize:   12.sp,
                        color:      AppColors.muted,
                        fontWeight: FontWeight.w700),
                  ),
                ]),

                SizedBox(height: 8.h),

                // ── Service chips ─────────────────────────────────────
                Wrap(spacing: 6.w, runSpacing: 4.h, children: [
                  if (dineInEnabled)
                    _ServiceChip(
                      icon:  Icons.storefront_rounded,
                      label: 'Dine-In',
                      color: AppColors.primary,
                    ),
                  if (takeawayEnabled)
                    _ServiceChip(
                      icon:  Icons.shopping_bag_outlined,
                      label: 'Takeaway',
                      color: const Color(0xFF2E7D32),
                    ),
                  if (tableBookingEnabled)
                    _ServiceChip(
                      icon:  Icons.event_seat_rounded,
                      label: 'Table Booking',
                      color: const Color(0xFF6A1B9A),
                    ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Service chip ──────────────────────────────────────────────────────────────
class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(8.r),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11.sp, color: color),
      SizedBox(width: 3.w),
      Text(
        label,
        style: TextStyle(
          fontSize:   10.5.sp,
          fontWeight: FontWeight.w800,
          color:      color,
        ),
      ),
    ]),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEFEFEF),
    child: const Center(
      child: Icon(Icons.restaurant_menu, size: 44, color: Colors.black26),
    ),
  );
}

class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
    decoration: BoxDecoration(
      color:        AppColors.primary,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star, size: 13, color: Colors.white),
      SizedBox(width: 3.w),
      Text(
        rating > 0 ? rating.toStringAsFixed(1) : 'New',
        style: TextStyle(
            fontSize:   11.5.sp,
            color:      Colors.white,
            fontWeight: FontWeight.w900,
            height:     1.0),
      ),
    ]),
  );
}