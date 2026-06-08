// 📱 CUSTOMER APP
// lib/features/home/presentation/bloc/restaurant_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';

abstract class RestaurantState extends Equatable {
  const RestaurantState();
  @override
  List<Object?> get props => [];
}

class RestaurantLoading extends RestaurantState {
  const RestaurantLoading();
}

class RestaurantError extends RestaurantState {
  final String message;
  const RestaurantError(this.message);
  @override
  List<Object?> get props => [message];
}

class RestaurantLoaded extends RestaurantState {
  final List<Restaurant>    restaurants;
  final List<Restaurant>    featuredRestaurants;
  final List<(String, int)> categories;

  const RestaurantLoaded(
      this.restaurants, {
        this.featuredRestaurants = const [],
        this.categories          = const [],
      });

  @override
  List<Object?> get props => [restaurants, featuredRestaurants, categories];
}

class RestaurantDetailLoaded extends RestaurantState {
  final Restaurant     restaurant;
  final String?        branchId;
  final List<MenuItem> menuItems;

  // Branch-level open/closed — independent per outlet
  final bool    branchIsOpen;
  final String? branchOpenTime;   // "09:00" 24hr
  final String? branchCloseTime;  // "22:00" 24hr

  const RestaurantDetailLoaded({
    required this.restaurant,
    required this.menuItems,
    this.branchId,
    this.branchIsOpen    = true,
    this.branchOpenTime,
    this.branchCloseTime,
  });

  @override
  List<Object?> get props => [
    restaurant, branchId, menuItems,
    branchIsOpen, branchOpenTime, branchCloseTime,
  ];
}