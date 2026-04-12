import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_state.dart';
import '../widgets/category_bubble.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: AppColors.bg,
      body: BlocBuilder<RestaurantBloc, RestaurantState>(
        builder: (context, state) {
          final backendCats = state is RestaurantLoaded
              ? state.categories
              : <(String, int)>[];

          final allCategories = [
            ('All', 0),
            ...backendCats,
          ];

          if (backendCats.isEmpty && state is RestaurantLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: GridView.builder(
              itemCount: allCategories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                (MediaQuery.sizeOf(context).width >= 700) ? 4 : 3,
                mainAxisSpacing: 14.h,
                crossAxisSpacing: 14.w,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (_, i) {
                final title = allCategories[i].$1;
                final count = allCategories[i].$2;

                return CategoryBubble(
                  title: title,
                  selected: false,
                  itemCount: title == 'All' ? null : count,
                  onTap: () {
                    if (title == 'All') {
                      context.push('/partners');
                    } else {
                      context.push('/partners?category=$title');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}