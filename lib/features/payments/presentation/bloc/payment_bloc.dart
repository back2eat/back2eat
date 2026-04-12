import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payment_repository.dart';

// ── Events ────────────────────────────────────────────────────────────

abstract class PaymentEvent {
  const PaymentEvent();
}

class CreatePaymentOrderEvent extends PaymentEvent {
  final String orderId;
  const CreatePaymentOrderEvent(this.orderId);
}

class VerifyPaymentEvent extends PaymentEvent {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final String orderId;

  const VerifyPaymentEvent({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
    required this.orderId,
  });
}

// ── States ────────────────────────────────────────────────────────────

abstract class PaymentState {
  const PaymentState();
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentOrderCreated extends PaymentState {
  final String razorpayOrderId;
  final double amount;
  final String keyId;
  final String internalOrderId;

  const PaymentOrderCreated({
    required this.razorpayOrderId,
    required this.amount,
    required this.keyId,
    required this.internalOrderId,
  });
}

class PaymentVerified extends PaymentState {}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
}

// ── Bloc ──────────────────────────────────────────────────────────────

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repo;

  PaymentBloc(this._repo) : super(PaymentInitial()) {
    on<CreatePaymentOrderEvent>(_onCreate);
    on<VerifyPaymentEvent>(_onVerify);
  }

  Future<void> _onCreate(
      CreatePaymentOrderEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final order = await _repo.createPaymentOrder(event.orderId);
      emit(PaymentOrderCreated(
        razorpayOrderId: order.razorpayOrderId,
        amount: order.amount,
        keyId: order.keyId,
        internalOrderId: order.orderId,
      ));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onVerify(
      VerifyPaymentEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      await _repo.verifyPayment(
        razorpayOrderId:   event.razorpayOrderId,
        razorpayPaymentId: event.razorpayPaymentId,
        razorpaySignature: event.razorpaySignature,
        orderId:           event.orderId,
      );
      emit(PaymentVerified());
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}