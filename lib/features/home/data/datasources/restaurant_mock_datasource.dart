import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';

class RestaurantMockDatasource {
  Future<List<Restaurant>> getRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const [
      Restaurant(
        id: '1',
        name: 'Burger Hub',
        rating: 4.6,
        distanceKm: 1.8,
        isOpen: true,
        prepTimeMins: 18,
        categories: ['Burgers', 'Fast Food'],
      ),
      Restaurant(
        id: '2',
        name: 'Pizza Town',
        rating: 4.4,
        distanceKm: 2.6,
        isOpen: true,
        prepTimeMins: 25,
        categories: ['Pizza', 'Italian'],
      ),
      Restaurant(
        id: '3',
        name: 'Sub Corner',
        rating: 4.7,
        distanceKm: 0.9,
        isOpen: false,
        prepTimeMins: 15,
        categories: ['Sandwich', 'Snacks'],
      ),
    ];
  }

  Future<(Restaurant, List<MenuItem>)> getRestaurantDetail(String restaurantId) async {
    final all = await getRestaurants();
    final r = all.firstWhere((e) => e.id == restaurantId);

    await Future.delayed(const Duration(milliseconds: 180));
    final menu = <MenuItem>[
      MenuItem(
        id: 'm1-$restaurantId',
        restaurantId: restaurantId,
        name: 'Classic Combo',
        description: 'Signature item with fries and drink',
        price: 9.99,
      ),
      MenuItem(
        id: 'm2-$restaurantId',
        restaurantId: restaurantId,
        name: 'Spicy Special',
        description: 'Hot & crispy with house sauce',
        price: 7.49,
      ),
      MenuItem(
        id: 'm3-$restaurantId',
        restaurantId: restaurantId,
        name: 'Cheese Burst',
        description: 'Extra cheese, extra joy',
        price: 8.79,
      ),
    ];
    return (r, menu);
  }
}
