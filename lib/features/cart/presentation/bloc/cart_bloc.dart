import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState(items: [])) {
    on<AddToCartEvent>(_add);
    on<IncreaseQtyEvent>(_inc);
    on<DecreaseQtyEvent>(_dec);
    on<ClearCartEvent>((_, emit) => emit(const CartState(items: [])));
  }

  void _add(AddToCartEvent e, Emitter<CartState> emit) {
    final list = [...state.items];
    final idx  = list.indexWhere((x) => x.menuItemId == e.menuItemId);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(qty: list[idx].qty + 1);
    } else {
      list.add(CartLine(
        restaurantId:   e.restaurantId,
        restaurantName: e.restaurantName,
        menuItemId:     e.menuItemId,
        name:           e.name,
        price:          e.price,
        qty:            1,
        branchId:       e.branchId,
      ));
    }
    emit(CartState(items: list));
  }

  void _inc(IncreaseQtyEvent e, Emitter<CartState> emit) {
    final list = [...state.items];
    final idx  = list.indexWhere((x) => x.menuItemId == e.menuItemId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(qty: list[idx].qty + 1);
    emit(CartState(items: list));
  }

  void _dec(DecreaseQtyEvent e, Emitter<CartState> emit) {
    final list = [...state.items];
    final idx  = list.indexWhere((x) => x.menuItemId == e.menuItemId);
    if (idx < 0) return;
    final next = list[idx].qty - 1;
    if (next <= 0) {
      list.removeAt(idx);
    } else {
      list[idx] = list[idx].copyWith(qty: next);
    }
    emit(CartState(items: list));
  }
}