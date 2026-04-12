abstract class RestaurantEvent {
  const RestaurantEvent();
}

class LoadRestaurantsEvent extends RestaurantEvent {
  final String? search;
  const LoadRestaurantsEvent({this.search});
}

class LoadRestaurantDetailEvent extends RestaurantEvent {
  final String  restaurantId;
  final String? selectedBranchId;
  const LoadRestaurantDetailEvent({
    required this.restaurantId,
    this.selectedBranchId,
  });
}