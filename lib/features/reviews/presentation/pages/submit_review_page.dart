import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../reviews/data/repositories/reviews_cubit.dart';

class SubmitReviewPage extends StatefulWidget {
  final String orderId;
  final String restaurantName;

  const SubmitReviewPage({
    super.key,
    required this.orderId,
    required this.restaurantName,
  });

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReviewsCubit>(),
      child: BlocConsumer<ReviewsCubit, ReviewsState>(
        listener: (context, state) {
          if (state.submitted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submitted! Thank you.')),
            );
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: AppBar(
              title: const Text('Leave a Review'),
              centerTitle: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.restaurantName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'How was your experience?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.sp, color: AppColors.muted),
                  ),
                  SizedBox(height: 24.h),

                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = i + 1),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            i < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40.r,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _ratingLabel(_rating),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 24.h),

                  // Comment
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                        'Tell us more about your experience (optional)',
                        hintStyle: TextStyle(
                            color: AppColors.muted, fontSize: 13.sp),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Opacity(
                    opacity: state.submitting ? 0.6 : 1,
                    child: PrimaryButton(
                      text: state.submitting
                          ? 'Submitting…'
                          : 'Submit Review',
                      onTap: () {
                        if (state.submitting) return;
                        context.read<ReviewsCubit>().submitReview(
                          orderId: widget.orderId,
                          rating: _rating,
                          comment: _commentCtrl.text
                              .trim()
                              .isEmpty
                              ? null
                              : _commentCtrl.text.trim(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}