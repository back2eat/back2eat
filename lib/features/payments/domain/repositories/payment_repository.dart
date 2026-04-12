import '../entities/razorpay_order.dart';

abstract class PaymentRepository {
  /// Step 1 — create a Razorpay payment order for the given internal order.
  Future<RazorpayOrder> createPaymentOrder(String orderId);

  /// Step 2 — verify payment after Razorpay success callback.
  Future<void> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  });
}