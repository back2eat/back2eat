import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/restaurant_remote_datasource.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDatasource ds;
  RestaurantRepositoryImpl(this.ds);

  @override
  Future<List<Restaurant>> getRestaurants({String? search}) =>
      ds.getRestaurants(search: search);

  @override
  Future<(Restaurant, String?, List<MenuItem>)> getRestaurantDetail(
      String restaurantId, {String? selectedBranchId}) =>
      ds.getRestaurantDetail(restaurantId, selectedBranchId: selectedBranchId);

  @override
  Future<List<(String, int)>> getCategories() => ds.getCategories();

  @override
  Future<List<Restaurant>> getFeaturedRestaurants() =>
      ds.getFeaturedRestaurants();
}