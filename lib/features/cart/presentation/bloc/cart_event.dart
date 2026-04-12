import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final String restaurantId;
  final String restaurantName;
  final String menuItemId;
  final String name;
  final double price;
  final String branchId;

  const AddToCartEvent({
    required this.restaurantId,
    required this.restaurantName,
    required this.menuItemId,
    required this.name,
    required this.price,
    this.branchId = '',
  });

  @override
  List<Object?> get props => [restaurantId, restaurantName, menuItemId, name, price, branchId];
}

class IncreaseQtyEvent extends CartEvent {
  final String menuItemId;
  const IncreaseQtyEvent(this.menuItemId);
  @override
  List<Object?> get props => [menuItemId];
}

class DecreaseQtyEvent extends CartEvent {
  final String menuItemId;
  const DecreaseQtyEvent(this.menuItemId);
  @override
  List<Object?> get props => [menuItemId];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}