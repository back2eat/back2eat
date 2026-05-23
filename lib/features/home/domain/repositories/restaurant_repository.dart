// 📱 CUSTOMER APP
// lib/features/home/domain/repositories/restaurant_repository.dart

import '../entities/menu_item.dart';
import '../entities/restaurant.dart';

abstract class RestaurantRepository {
  Future<List<Restaurant>> getRestaurants({String? search, String? city});
  Future<(Restaurant, String?, List<MenuItem>)> getRestaurantDetail(
      String restaurantId, {String? selectedBranchId});
  Future<List<(String, int)>> getCategories();
  Future<List<Restaurant>> getFeaturedRestaurants();
}