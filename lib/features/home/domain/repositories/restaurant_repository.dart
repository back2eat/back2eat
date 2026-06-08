// 📱 CUSTOMER APP
// lib/features/home/domain/repositories/restaurant_repository.dart

import '../entities/branch.dart';
import '../entities/menu_item.dart';
import '../entities/restaurant.dart';

abstract class RestaurantRepository {
  Future<List<Restaurant>> getRestaurants({String? search, String? city});

  /// Returns (restaurant, branchId, menuItems, branchIsOpen, branchOpenTime, branchCloseTime)
  Future<(Restaurant, String?, List<MenuItem>, bool, String?, String?)>
  getRestaurantDetail(String restaurantId, {String? selectedBranchId});

  Future<List<(String, int)>> getCategories();

  Future<List<Restaurant>> getFeaturedRestaurants();

  Future<List<BranchEntity>> getPublicBranches(String restaurantId);
}