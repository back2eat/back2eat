import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class CategoryBubble extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final int? itemCount;

  const CategoryBubble({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.itemCount,
  });

  static IconData iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('burger') || n.contains('fast food')) return Icons.fastfood;
    if (n.contains('pizza')) return Icons.local_pizza;
    if (n.contains('sandwich') || n.contains('sub')) return Icons.lunch_dining;
    if (n.contains('coffee') || n.contains('cafe') || n.contains('drink')) return Icons.local_cafe;
    if (n.contains('chicken') || n.contains('meat') || n.contains('grill')) return Icons.set_meal;
    if (n.contains('ice') || n.contains('dessert') || n.contains('sweet')) return Icons.icecream;
    if (n.contains('salad') || n.contains('veg')) return Icons.eco;
    if (n.contains('rice') || n.contains('biryani') || n.contains('meal')) return Icons.rice_bowl;
    if (n.contains('noodle') || n.contains('pasta') || n.contains('chinese')) return Icons.ramen_dining;
    if (n.contains('breakfast') || n.contains('egg')) return Icons.breakfast_dining;
    if (n.contains('snack') || n.contains('fries') || n.contains('starter')) return Icons.tapas;
    if (n.contains('all')) return Icons.grid_view_rounded;
    return Icons.restaurant_menu;
  }

  @override
  Widget build(BuildContext context) {
    final icon = iconForCategory(title);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 86.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFEAEAEA),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26.sp,
                color: selected ? Colors.white : AppColors.text),
            SizedBox(height: 8.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.text,
              ),
            ),
            if (itemCount != null) ...[
              SizedBox(height: 3.h),
              Text(
                '$itemCount items',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}