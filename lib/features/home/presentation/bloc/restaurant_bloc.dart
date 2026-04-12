import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/restaurant_repository.dart';
import 'restaurant_event.dart';
import 'restaurant_state.dart';

class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final RestaurantRepository repo;

  RestaurantBloc(this.repo) : super(const RestaurantLoading()) {
    on<LoadRestaurantsEvent>(_loadRestaurants);
    on<LoadRestaurantDetailEvent>(_loadDetail);
  }

  Future<void> _loadRestaurants(
      LoadRestaurantsEvent event, Emitter<RestaurantState> emit) async {
    emit(const RestaurantLoading());
    try {
      final results = await Future.wait([
        repo.getRestaurants(search: event.search),
        repo.getCategories(),
        repo.getFeaturedRestaurants(),
      ]);

      emit(RestaurantLoaded(
        (results[0] as List).cast(),
        categories:          (results[1] as List).cast(),
        featuredRestaurants: (results[2] as List).cast(),
      ));
    } catch (e) {
      emit(RestaurantError(e.toString()));
    }
  }

  Future<void> _loadDetail(
      LoadRestaurantDetailEvent event, Emitter<RestaurantState> emit) async {
    emit(const RestaurantLoading());
    try {
      final (restaurant, branchId, menu) = await repo.getRestaurantDetail(
        event.restaurantId,
        selectedBranchId: event.selectedBranchId,
      );
      emit(RestaurantDetailLoaded(
        restaurant: restaurant,
        branchId:   branchId,
        menuItems:  menu,
      ));
    } catch (e) {
      emit(RestaurantError(e.toString()));
    }
  }
}