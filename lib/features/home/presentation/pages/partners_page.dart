import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_state.dart';
import '../widgets/restaurant_feed_card.dart';

class PartnersPage extends StatelessWidget {
  final String? category; // from query param
  const PartnersPage({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    final selected = (category == null || category!.trim().isEmpty) ? 'All' : category!.trim();
    final needle = selected.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(selected == 'All' ? 'Best Partners' : selected),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<RestaurantBloc, RestaurantState>(
        builder: (_, state) {
          if (state is RestaurantLoading) return const Center(child: CircularProgressIndicator());
          if (state is RestaurantError) return Center(child: Text(state.message));
          if (state is! RestaurantLoaded) return const Center(child: Text('Loading...'));

          final all = state.restaurants;

          final filtered = (selected == 'All')
              ? all
              : all.where((r) {
            final cats = (r.categories as List).whereType<String>();
            return cats.any((String c) => c.toLowerCase().contains(needle));
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No restaurants found for "$selected"',
                style: TextStyle(fontSize: 13.sp, color: AppColors.muted, fontWeight: FontWeight.w700),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(height: 14.h),
            itemBuilder: (_, i) {
              final r = filtered[i];
              return RestaurantFeedCard(
                name: r.name,
                rating: r.rating,
                km: r.distanceKm,
                isOpen: r.isOpen,
                categories: r.categories,
                readyInMins: r.prepTimeMins,
                onTap: () => context.push('/restaurant/${r.id}'),
              );
            },
          );
        },
      ),
      backgroundColor: AppColors.bg,
    );
  }
}