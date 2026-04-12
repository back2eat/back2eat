import '../../../../core/network/api_client.dart';
import '../../../../shared/services/location_service.dart';
import '../../domain/entities/branch.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';

class RestaurantRemoteDatasource {
  final ApiClient _api;
  RestaurantRemoteDatasource(this._api);

  Future<List<Restaurant>> getRestaurants({String? search, String? city}) async {
    final query = StringBuffer('/restaurants?limit=30');
    if (search != null && search.isNotEmpty) query.write('&search=$search');
    if (city   != null && city.isNotEmpty)   query.write('&city=$city');

    final data = await _api.get(query.toString());
    final list = data['restaurants'] as List<dynamic>? ?? [];

    // Get device location once for all restaurants
    final position = await LocationService.instance.getCurrentPosition();

    return list.map((e) {
      final json = Map<String, dynamic>.from(e as Map<String, dynamic>);

      // Calculate real distance if we have device GPS + branch coords
      if (position != null) {
        final lat = (json['latitude']  as num?)?.toDouble();
        final lng = (json['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          json['distanceKm'] = LocationService.distanceKm(
            position.latitude, position.longitude, lat, lng,
          );
        }
      }

      return RestaurantModel.fromJson(json);
    }).toList();
  }

  /// Returns (restaurant, branchId, menuItems)
  /// If [selectedBranchId] is provided, that branch is used instead of first
  Future<(Restaurant, String?, List<MenuItem>)> getRestaurantDetail(
      String restaurantId, {String? selectedBranchId}) async {
    final data = await _api.get('/restaurants/$restaurantId');

    final branches = data['branches'] as List<dynamic>? ?? [];

    // Use selected branch if provided, otherwise first branch
    Map<String, dynamic>? firstBranch;
    if (branches.isNotEmpty) {
      if (selectedBranchId != null) {
        firstBranch = branches
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (b) => b['_id'] == selectedBranchId,
          orElse: () => branches.first as Map<String, dynamic>,
        );
      } else {
        firstBranch = branches.first as Map<String, dynamic>;
      }
    }

    // Pull lat/lng from the first branch, not the restaurant object
    final branchId  = firstBranch?['_id']       as String?;
    final branchLat = (firstBranch?['latitude']  as num?)?.toDouble();
    final branchLng = (firstBranch?['longitude'] as num?)?.toDouble();

    // Inject branch lat/lng + city into restaurant JSON before parsing
    final restaurantJson = Map<String, dynamic>.from(
        data['restaurant'] as Map<String, dynamic>);
    if (branchLat != null) restaurantJson['latitude']  = branchLat;
    if (branchLng != null) restaurantJson['longitude'] = branchLng;

    final branchCity = firstBranch?['city'] as String?;
    if (branchCity != null && restaurantJson['city'] == null) {
      restaurantJson['city'] = branchCity;
    }

    // Calculate real distance from device GPS to this branch
    final position = await LocationService.instance.getCurrentPosition();
    if (position != null && branchLat != null && branchLng != null) {
      restaurantJson['distanceKm'] = LocationService.distanceKm(
        position.latitude, position.longitude, branchLat, branchLng,
      );
    }

    final restaurant = RestaurantModel.fromJson(restaurantJson);

    List<MenuItem> menuItems = [];
    if (branchId != null) {
      try {
        final menuData   = await _api.get('/menu/public?branchId=$branchId');
        final categories = menuData['menu'] as List<dynamic>? ?? [];
        for (final cat in categories) {
          final items =
              (cat as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            menuItems.add(MenuItemModel.fromJson(
                item as Map<String, dynamic>, restaurantId));
          }
        }
      } catch (_) {}
    }

    return (restaurant as Restaurant, branchId, menuItems);
  }

  /// Builds cuisine categories from the restaurant list itself
  Future<List<(String, int)>> getCategories() async {
    try {
      final data = await _api.get('/restaurants?limit=100');
      final list = data['restaurants'] as List<dynamic>? ?? [];

      final Map<String, int> counts = {};
      for (final r in list) {
        final cuisines =
            (r as Map<String, dynamic>)['cuisine'] as List<dynamic>? ?? [];
        for (final c in cuisines) {
          final name = c.toString().trim();
          if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
        }
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.map((e) => (e.key, e.value)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches admin-curated featured restaurants in position order
  Future<List<Restaurant>> getFeaturedRestaurants() async {
    try {
      final data     = await _api.get('/featured');
      final featured = data['featured'] as List<dynamic>? ?? [];
      final result   = <Restaurant>[];

      for (final entry in featured) {
        final m = entry as Map<String, dynamic>;
        final r = m['restaurantId'];
        if (r == null) continue;
        final restaurant = RestaurantModel.fromJson(r as Map<String, dynamic>);
        result.add(restaurant);
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  /// Fetches all active branches for a restaurant, sorted by distance
  Future<List<BranchEntity>> getPublicBranches(String restaurantId) async {
    try {
      // Get device GPS for distance sorting
      final position = await LocationService.instance.getCurrentPosition();
      final query    = StringBuffer('/branches/public/$restaurantId');
      if (position != null) {
        query.write('?lat=${position.latitude}&lng=${position.longitude}');
      }
      final data     = await _api.get(query.toString());
      final list     = data['branches'] as List<dynamic>? ?? [];
      return list
          .map((e) => BranchEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}