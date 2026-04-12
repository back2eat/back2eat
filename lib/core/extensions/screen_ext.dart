import 'package:flutter_screenutil/flutter_screenutil.dart';

extension FontExt on num {
  double get spMin => ScreenUtil().setSp(this).clamp(0, this * 1.15);
}
