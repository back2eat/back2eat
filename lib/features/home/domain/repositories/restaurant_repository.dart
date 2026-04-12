import '../entities/menu_item.dart';
import '../entities/restaurant.dart';

abstract class RestaurantRepository {
  Future<List<Restaurant>> getRestaurants({String? search});
  Future<(Restaurant, String?, List<MenuItem>)> getRestaurantDetail(
      String restaurantId, {String? selectedBranchId});
  Future<List<(String, int)>> getCategories();
  Future<List<Restaurant>> getFeaturedRestaurants();
}