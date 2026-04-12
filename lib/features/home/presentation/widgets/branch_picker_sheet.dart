import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/restaurant_remote_datasource.dart';
import '../../domain/entities/branch.dart';

/// Shows a modal bottom sheet that lists all branches for [restaurantId],
/// sorted by distance. Returns the selected [BranchEntity] or null.
Future<BranchEntity?> showBranchPicker({
  required BuildContext context,
  required String       restaurantId,
  required String       restaurantName,
}) {
  return showModalBottomSheet<BranchEntity>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BranchPickerSheet(
      restaurantId:   restaurantId,
      restaurantName: restaurantName,
    ),
  );
}

class _BranchPickerSheet extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  const _BranchPickerSheet({
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<_BranchPickerSheet> createState() => _BranchPickerSheetState();
}

class _BranchPickerSheetState extends State<_BranchPickerSheet> {
  List<BranchEntity> _branches = [];
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds       = getIt<RestaurantRemoteDatasource>();
      final branches = await ds.getPublicBranches(widget.restaurantId);
      if (mounted) setState(() { _branches = branches; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Handle + header ─────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: Column(children: [
            Container(
              width: 44.w, height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: 16.h),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Branch',
                      style: TextStyle(
                          fontSize: 17.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2.h),
                  Text(widget.restaurantName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.muted,
                          fontWeight: FontWeight.w600)),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36.w, height: 36.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.close, size: 18.sp),
                ),
              ),
            ]),
            SizedBox(height: 12.h),
            Divider(height: 1, color: AppColors.line),
          ]),
        ),

        // ── Content ─────────────────────────────────────────────────
        if (_loading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_error != null || _branches.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Column(children: [
              Icon(Icons.storefront_outlined, size: 40.sp, color: AppColors.muted),
              SizedBox(height: 8.h),
              Text('No branches available',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.muted,
                      fontWeight: FontWeight.w700)),
            ]),
          )
        else if (_branches.length == 1)
          // Single branch — auto-select, no need to show list
            _AutoSelectSingle(branch: _branches.first)
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                itemCount: _branches.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) => _BranchTile(
                  branch: _branches[i],
                  rank:   i,
                  onTap:  () => Navigator.pop(context, _branches[i]),
                ),
              ),
            ),
      ]),
    );
  }
}

// ── Auto-select widget for single branch ──────────────────────────────────────
class _AutoSelectSingle extends StatefulWidget {
  final BranchEntity branch;
  const _AutoSelectSingle({required this.branch});

  @override
  State<_AutoSelectSingle> createState() => _AutoSelectSingleState();
}

class _AutoSelectSingleState extends State<_AutoSelectSingle> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss and return the only branch after brief display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) Navigator.pop(context, widget.branch);
      });
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
    child: _BranchTile(
      branch: widget.branch,
      rank:   0,
      onTap:  () => Navigator.pop(context, widget.branch),
    ),
  );
}

// ── Branch tile ───────────────────────────────────────────────────────────────
class _BranchTile extends StatelessWidget {
  final BranchEntity branch;
  final int          rank;
  final VoidCallback onTap;
  const _BranchTile({
    required this.branch,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNearest = rank == 0 && branch.distanceKm != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isNearest
                ? AppColors.primary.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            width: isNearest ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 44.w, height: 44.w,
            decoration: BoxDecoration(
              color:        isNearest
                  ? AppColors.primary.withOpacity(0.10)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: isNearest ? AppColors.primary : AppColors.muted,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(branch.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w900))),
                if (isNearest)
                  Container(
                    margin: EdgeInsets.only(left: 6.w),
                    padding: EdgeInsets.symmetric(
                        horizontal: 7.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('Nearest',
                        style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ),
              ]),
              SizedBox(height: 3.h),
              Text(branch.address,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5.sp, color: AppColors.muted,
                      fontWeight: FontWeight.w600, height: 1.4)),
              SizedBox(height: 6.h),
              Row(children: [
                // Distance
                Icon(Icons.location_on_outlined,
                    size: 13.sp, color: AppColors.muted),
                SizedBox(width: 2.w),
                Text(branch.distanceLabel,
                    style: TextStyle(
                        fontSize: 11.sp, color: AppColors.muted,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 12.w),
                // Open/Closed
                Container(
                  width: 6.w, height: 6.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: branch.isOpen
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(branch.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: branch.isOpen
                            ? AppColors.success
                            : AppColors.danger,
                        fontWeight: FontWeight.w800)),
                if (branch.phone != null &&
                    branch.phone!.isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  Icon(Icons.phone_outlined,
                      size: 12.sp, color: AppColors.muted),
                  SizedBox(width: 2.w),
                  Text(branch.phone!,
                      style: TextStyle(
                          fontSize: 11.sp, color: AppColors.muted,
                          fontWeight: FontWeight.w600)),
                ],
              ]),
            ],
          )),
          SizedBox(width: 8.w),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.muted, size: 20.sp),
        ]),
      ),
    );
  }
}