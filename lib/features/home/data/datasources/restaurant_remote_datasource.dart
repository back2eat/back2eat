// 📱 CUSTOMER APP
// lib/features/home/data/datasources/restaurant_remote_datasource.dart

import '../../../../core/network/api_client.dart';
import '../../../../shared/services/location_service.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';

class RestaurantRemoteDatasource {
  final ApiClient _api;
  RestaurantRemoteDatasource(this._api);

  Future<List<Restaurant>> getRestaurants({String? search, String? city}) async {
    final query = StringBuffer('/restaurants?limit=30');
    if (search != null && search.isNotEmpty) query.write('&search=$search');
    if (city   != null && city.isNotEmpty)   query.write('&city=$city');

    final data     = await _api.get(query.toString());
    final list     = data['restaurants'] as List<dynamic>? ?? [];
    final position = await LocationService.instance.getCurrentPosition();

    return list.map((e) {
      final json = Map<String, dynamic>.from(e as Map<String, dynamic>);
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

  /// Returns (restaurant, branchId, menuItems, branchIsOpen, branchOpenTime, branchCloseTime)
  Future<(Restaurant, String?, List<MenuItem>, bool, String?, String?)>
  getRestaurantDetail(String restaurantId, {String? selectedBranchId}) async {
    final data     = await _api.get('/restaurants/$restaurantId');
    final branches = data['branches'] as List<dynamic>? ?? [];

    // Pick selected branch or first branch
    Map<String, dynamic>? branch;
    if (branches.isNotEmpty) {
      if (selectedBranchId != null) {
        branch = branches
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (b) => b['_id'] == selectedBranchId,
          orElse: () => branches.first as Map<String, dynamic>,
        );
      } else {
        branch = branches.first as Map<String, dynamic>;
      }
    }

    final branchId        = branch?['_id']       as String?;
    final branchLat       = (branch?['latitude']  as num?)?.toDouble();
    final branchLng       = (branch?['longitude'] as num?)?.toDouble();
    final branchIsOpen    = branch?['isOpen']     as bool?   ?? true;
    final branchOpenTime  = branch?['openTime']   as String?;
    final branchCloseTime = branch?['closeTime']  as String?;

    // Build restaurant JSON with branch location injected
    final restaurantJson = Map<String, dynamic>.from(
        data['restaurant'] as Map<String, dynamic>);
    if (branchLat != null) restaurantJson['latitude']  = branchLat;
    if (branchLng != null) restaurantJson['longitude'] = branchLng;
    final branchCity = branch?['city'] as String?;
    if (branchCity != null && restaurantJson['city'] == null) {
      restaurantJson['city'] = branchCity;
    }

    // Real distance from device GPS
    final position = await LocationService.instance.getCurrentPosition();
    if (position != null && branchLat != null && branchLng != null) {
      restaurantJson['distanceKm'] = LocationService.distanceKm(
        position.latitude, position.longitude, branchLat, branchLng,
      );
    }

    final restaurant = RestaurantModel.fromJson(restaurantJson);

    // Fetch menu
    List<MenuItem> menuItems = [];
    if (branchId != null) {
      try {
        final menuData   = await _api.get('/menu/public?branchId=$branchId');
        final categories = menuData['menu'] as List<dynamic>? ?? [];
        for (final cat in categories) {
          final catMap       = cat as Map<String, dynamic>;
          final categoryName = catMap['name'] as String? ?? '';
          final items        = catMap['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            final itemJson = Map<String, dynamic>.from(item as Map<String, dynamic>);
            itemJson['categoryName'] = categoryName;
            menuItems.add(MenuItemModel.fromJson(itemJson, restaurantId));
          }
        }
      } catch (_) {}
    }

    return (
    restaurant as Restaurant,
    branchId,
    menuItems,
    branchIsOpen,
    branchOpenTime,
    branchCloseTime,
    );
  }

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
      return (counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => (e.key, e.value))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Restaurant>> getFeaturedRestaurants() async {
    try {
      final data     = await _api.get('/featured');
      final featured = data['featured'] as List<dynamic>? ?? [];
      final result   = <Restaurant>[];
      for (final entry in featured) {
        final m = entry as Map<String, dynamic>;
        final r = m['restaurantId'];
        if (r == null) continue;
        result.add(RestaurantModel.fromJson(r as Map<String, dynamic>));
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<BranchEntity>> getPublicBranches(String restaurantId) async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      final query    = StringBuffer('/branches/public/$restaurantId');
      if (position != null) {
        query.write('?lat=${position.latitude}&lng=${position.longitude}');
      }
      final data = await _api.get(query.toString());
      final list = data['branches'] as List<dynamic>? ?? [];
      return list
          .map((e) => BranchEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}