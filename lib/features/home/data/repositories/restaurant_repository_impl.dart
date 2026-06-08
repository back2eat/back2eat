// 📱 CUSTOMER APP
// lib/features/home/data/repositories/restaurant_repository_impl.dart

import '../../domain/entities/branch.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/restaurant_remote_datasource.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDatasource ds;
  RestaurantRepositoryImpl(this.ds);

  @override
  Future<List<Restaurant>> getRestaurants({String? search, String? city}) =>
      ds.getRestaurants(search: search, city: city);

  @override
  Future<(Restaurant, String?, List<MenuItem>, bool, String?, String?)>
  getRestaurantDetail(String restaurantId, {String? selectedBranchId}) =>
      ds.getRestaurantDetail(restaurantId, selectedBranchId: selectedBranchId);

  @override
  Future<List<(String, int)>> getCategories() => ds.getCategories();

  @override
  Future<List<Restaurant>> getFeaturedRestaurants() =>
      ds.getFeaturedRestaurants();

  @override
  Future<List<BranchEntity>> getPublicBranches(String restaurantId) =>
      ds.getPublicBranches(restaurantId);
}