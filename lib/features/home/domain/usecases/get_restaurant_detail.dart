import '../entities/menu_item.dart';
import '../entities/restaurant.dart';
import '../repositories/restaurant_repository.dart';

class GetRestaurantDetail {
  final RestaurantRepository _repo;
  GetRestaurantDetail(this._repo);

  Future<(Restaurant, String?, List<MenuItem>)> call(String restaurantId) =>
      _repo.getRestaurantDetail(restaurantId);
}