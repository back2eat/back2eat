import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../order_type/presentation/cubit/order_type_cubit.dart';
import '../../domain/repositories/order_repository.dart';
import '../../../../core/network/api_client.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repo;

  OrderBloc(this._repo) : super(const OrderInitial()) {
    on<PlaceOrderEvent>(_placeOrder);
    on<LoadMyOrdersEvent>(_loadMyOrders);
    on<LoadOrderDetailEvent>(_loadOrderDetail);
    on<SilentRefreshOrderEvent>(_silentRefresh);
    on<CancelOrderEvent>(_cancelOrder);
    on<ResetOrderEvent>((_, emit) => emit(const OrderInitial()));
  }

  Future<void> _placeOrder(PlaceOrderEvent e, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final items = e.cartItems.map((c) => {
        'menuItemId': c.menuItemId,
        'name':       c.name,
        'quantity':   c.qty,
        'price':      c.price,
      }).toList();

      String orderTypeStr;
      switch (e.orderType) {
        case OrderType.dineIn:
          orderTypeStr = 'DINE_IN';
          break;
        case OrderType.tableBooking:
          orderTypeStr = 'TABLE_BOOKING';
          break;
        case OrderType.takeAway:
        default:
          orderTypeStr = 'TAKEAWAY';
      }

      final order = await _repo.placeOrder(
        restaurantId:        e.restaurantId,
        branchId:            e.branchId,
        orderType:           orderTypeStr,
        items:               items,
        specialInstructions: e.specialInstructions,
        paymentMethod:       'UPI',
        scheduledTime:       e.scheduledTime,
        guestCount:          e.guestCount,
        couponCode:          e.couponCode,
        pointsRedeemed:      e.pointsRedeemed,
        subtotal:            e.subtotal,
        commissionAmount:    e.commissionAmount,
        bookingFee:          e.bookingFee,
        totalAmount:         e.totalAmount,
      );
      emit(OrderPlaced(order));
    } on ApiException catch (ex) {
      emit(OrderError(ex.message));
    } catch (_) {
      emit(const OrderError('Failed to place order. Please try again.'));
    }
  }

  Future<void> _loadMyOrders(LoadMyOrdersEvent e, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final orders = await _repo.getMyOrders();
      emit(OrdersLoaded(orders));
    } catch (_) {
      emit(const OrderError('Could not load orders.'));
    }
  }

  Future<void> _loadOrderDetail(LoadOrderDetailEvent e, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final order = await _repo.getOrderById(e.orderId);
      emit(OrderDetailLoaded(order));
    } catch (_) {
      emit(const OrderError('Could not load order details.'));
    }
  }

  Future<void> _silentRefresh(SilentRefreshOrderEvent e, Emitter<OrderState> emit) async {
    try {
      final order = await _repo.getOrderById(e.orderId);
      emit(OrderDetailLoaded(order));
    } catch (_) {}
  }

  Future<void> _cancelOrder(CancelOrderEvent e, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final order = await _repo.cancelOrder(
        orderId: e.orderId,
        reason:  e.reason,
      );
      emit(OrderCancelled(order));
    } on ApiException catch (ex) {
      emit(OrderError(ex.message));
    } catch (_) {
      emit(const OrderError('Failed to cancel order. Please try again.'));
    }
  }
}