import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const SectionHeader({
    super.key,
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(action, style: TextStyle(fontSize: 13.sp, color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
