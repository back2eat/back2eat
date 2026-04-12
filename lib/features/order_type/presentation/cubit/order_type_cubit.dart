import 'package:flutter_bloc/flutter_bloc.dart';

enum OrderType { dineIn, takeAway, tableBooking }

class OrderTypeCubit extends Cubit<OrderType> {
  OrderTypeCubit() : super(OrderType.dineIn);

  /// Types the current restaurant allows — updated when restaurant loads
  List<OrderType> allowedTypes = OrderType.values;

  void set(OrderType type) => emit(type);

  /// Called once when RestaurantDetailLoaded fires — restricts available types
  void setAllowedTypes({
    required bool dineIn,
    required bool takeaway,
    required bool tableBooking,
  }) {
    allowedTypes = [
      if (dineIn)       OrderType.dineIn,
      if (takeaway)     OrderType.takeAway,
      if (tableBooking) OrderType.tableBooking,
    ];
    // If nothing is allowed (edge case), fall back to all
    if (allowedTypes.isEmpty) allowedTypes = OrderType.values;
    // If current selection is no longer allowed, auto-switch to first allowed
    if (!allowedTypes.contains(state)) emit(allowedTypes.first);
  }

  /// Reset allowed types when leaving the restaurant page
  void resetAllowedTypes() {
    allowedTypes = OrderType.values;
  }
}