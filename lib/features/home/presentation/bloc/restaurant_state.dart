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
  final List<Restaurant>       restaurants;
  final List<Restaurant>       featuredRestaurants;
  final List<(String, int)>    categories;

  const RestaurantLoaded(
      this.restaurants, {
        this.featuredRestaurants = const [],
        this.categories          = const [],
      });

  @override
  List<Object?> get props => [restaurants, featuredRestaurants, categories];
}

class RestaurantDetailLoaded extends RestaurantState {
  final Restaurant    restaurant;
  final String?       branchId;
  final List<MenuItem> menuItems;

  const RestaurantDetailLoaded({
    required this.restaurant,
    required this.menuItems,
    this.branchId,
  });

  @override
  List<Object?> get props => [restaurant, branchId, menuItems];
}