import 'package:equatable/equatable.dart';

class CartLine extends Equatable {
  final String restaurantId;
  final String restaurantName;
  final String menuItemId;
  final String name;
  final double price;
  final int qty;
  final String branchId;

  const CartLine({
    required this.restaurantId,
    required this.restaurantName,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.qty,
    this.branchId = '',
  });

  CartLine copyWith({int? qty}) => CartLine(
    restaurantId:   restaurantId,
    restaurantName: restaurantName,
    menuItemId:     menuItemId,
    name:           name,
    price:          price,
    qty:            qty ?? this.qty,
    branchId:       branchId,
  );

  @override
  List<Object?> get props => [restaurantId, restaurantName, menuItemId, name, price, qty, branchId];
}

class CartState extends Equatable {
  final List<CartLine> items;
  const CartState({required this.items});
  double get total => items.fold(0, (p, e) => p + e.price * e.qty);
  @override
  List<Object?> get props => [items];
}