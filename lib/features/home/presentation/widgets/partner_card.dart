import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class PartnerCard extends StatelessWidget {
  final String       name;
  final double       rating;
  final double       km;
  final bool         isOpen;
  final int          readyInMins;
  final VoidCallback onTap;
  final String?      coverUrl;
  final String?      logoUrl;
  final String?      city;

  // Service flags
  final bool dineInEnabled;
  final bool takeawayEnabled;
  final bool tableBookingEnabled;

  const PartnerCard({
    super.key,
    required this.name,
    required this.rating,
    required this.km,
    required this.isOpen,
    required this.readyInMins,
    required this.onTap,
    this.coverUrl,
    this.logoUrl,
    this.city,
    this.dineInEnabled       = true,
    this.takeawayEnabled     = true,
    this.tableBookingEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageToUse = coverUrl ?? logoUrl;

    return LayoutBuilder(
      builder: (context, c) {
        final h       = c.maxHeight.isFinite ? c.maxHeight : 200.h;
        final imageH  = (h * 0.50).clamp(84.0, 110.0);
        final contentH = h - imageH;

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
              // ── Cover image ──────────────────────────────────────
              ClipRRect(
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(18.r)),
                child: SizedBox(
                  height: imageH,
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

              // ── Content ──────────────────────────────────────────
              SizedBox(
                height: contentH,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 6.h),
                  child: Column(
                    mainAxisAlignment:  MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:   13.sp,
                          fontWeight: FontWeight.w900,
                          height:     1.0,
                        ),
                      ),

                      // Rating + distance + open
                      Row(children: [
                        _Rating(rating: rating),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            km > 0
                                ? '${km.toStringAsFixed(1)} km'
                                : (city != null && city!.isNotEmpty
                                ? city!
                                : 'Nearby'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize:   11.sp,
                              color:      AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize:   11.sp,
                            color: isOpen
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ]),

                      // ── Service chips ─────────────────────────────
                      Row(children: [
                        if (dineInEnabled)
                          _ServiceChip(
                            icon:  Icons.storefront_rounded,
                            label: 'Dine-In',
                            color: AppColors.primary,
                          ),
                        if (dineInEnabled && takeawayEnabled)
                          SizedBox(width: 4.w),
                        if (takeawayEnabled)
                          _ServiceChip(
                            icon:  Icons.shopping_bag_outlined,
                            label: 'Takeaway',
                            color: const Color(0xFF2E7D32),
                          ),
                        if (tableBookingEnabled &&
                            (dineInEnabled || takeawayEnabled))
                          SizedBox(width: 4.w),
                        if (tableBookingEnabled)
                          _ServiceChip(
                            icon:  Icons.event_seat_rounded,
                            label: 'Book',
                            color: const Color(0xFF6A1B9A),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
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
    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(6.r),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9.sp, color: color),
      SizedBox(width: 2.w),
      Text(
        label,
        style: TextStyle(
          fontSize:   8.5.sp,
          fontWeight: FontWeight.w800,
          color:      color,
        ),
      ),
    ]),
  );
}

// ── Placeholder ───────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEFEFEF),
    child: const Center(
      child: Icon(Icons.restaurant, size: 36, color: Colors.black26),
    ),
  );
}

// ── Rating pill ───────────────────────────────────────────────────────────────
class _Rating extends StatelessWidget {
  final double rating;
  const _Rating({required this.rating});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
    decoration: BoxDecoration(
        color:        AppColors.primary,
        borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star, size: 12, color: Colors.white),
      SizedBox(width: 3.w),
      Text(
        rating > 0 ? rating.toStringAsFixed(1) : 'New',
        style: TextStyle(
          fontSize:   11.sp,
          color:      Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    ]),
  );
}