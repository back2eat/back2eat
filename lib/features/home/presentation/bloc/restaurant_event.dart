// 📱 CUSTOMER APP
// lib/features/home/presentation/bloc/restaurant_event.dart

abstract class RestaurantEvent { const RestaurantEvent(); }

class LoadRestaurantsEvent extends RestaurantEvent {
  final String? search;
  final String? city;   // ← filter by city
  const LoadRestaurantsEvent({this.search, this.city});
}

class LoadRestaurantDetailEvent extends RestaurantEvent {
  final String  restaurantId;
  final String? selectedBranchId;
  const LoadRestaurantDetailEvent({
    required this.restaurantId,
    this.selectedBranchId,
  });
}