import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart';

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderPlaced extends OrderState {
  final OrderEntity order;
  const OrderPlaced(this.order);
  @override
  List<Object?> get props => [order];
}

class OrdersLoaded extends OrderState {
  final List<OrderEntity> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final OrderEntity order;
  const OrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderCancelled extends OrderState {
  final OrderEntity order;
  const OrderCancelled(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
  @override
  List<Object?> get props => [message];
}