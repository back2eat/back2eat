import 'package:equatable/equatable.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../order_type/presentation/cubit/order_type_cubit.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class PlaceOrderEvent extends OrderEvent {
  final String         restaurantId;
  final String         branchId;
  final OrderType      orderType;
  final List<CartLine> cartItems;
  final String?        specialInstructions;
  final String?        scheduledTime;
  final int?           guestCount;
  final String?        couponCode;
  final int?           pointsRedeemed;
  final double?        subtotal;
  final double?        commissionAmount;
  final double?        bookingFee;
  final double?        totalAmount;

  const PlaceOrderEvent({
    required this.restaurantId,
    required this.branchId,
    required this.orderType,
    required this.cartItems,
    this.specialInstructions,
    this.scheduledTime,
    this.guestCount,
    this.couponCode,
    this.pointsRedeemed,
    this.subtotal,
    this.commissionAmount,
    this.bookingFee,
    this.totalAmount,
  });

  @override
  List<Object?> get props => [
    restaurantId, branchId, orderType, cartItems,
    specialInstructions, scheduledTime, guestCount, couponCode, pointsRedeemed, subtotal,
    commissionAmount, bookingFee, totalAmount,
  ];
}

class LoadMyOrdersEvent extends OrderEvent {
  const LoadMyOrdersEvent();
}

class LoadOrderDetailEvent extends OrderEvent {
  final String orderId;
  const LoadOrderDetailEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class SilentRefreshOrderEvent extends OrderEvent {
  final String orderId;
  const SilentRefreshOrderEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class CancelOrderEvent extends OrderEvent {
  final String  orderId;
  final String? reason;
  const CancelOrderEvent({required this.orderId, this.reason});
  @override
  List<Object?> get props => [orderId, reason];
}

class ResetOrderEvent extends OrderEvent {
  const ResetOrderEvent();
}