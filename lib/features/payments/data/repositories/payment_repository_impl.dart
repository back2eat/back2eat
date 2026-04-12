import '../../../../core/network/api_client.dart';
import '../../domain/entities/razorpay_order.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiClient _api;
  PaymentRepositoryImpl(this._api);

  @override
  Future<RazorpayOrder> createPaymentOrder(String orderId) async {
    // POST /payments/create-order  { orderId }
    final data = await _api.post('/payments/create-order', {'orderId': orderId});
    final d = data['data'] as Map<String, dynamic>? ?? data;
    return RazorpayOrder(
      razorpayOrderId: d['razorpayOrderId'] as String,
      orderId: orderId,
      amount: (d['amount'] as num).toDouble(),
      currency: d['currency'] as String? ?? 'INR',
      keyId: d['keyId'] as String? ?? '',
    );
  }

  @override
  Future<void> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    // POST /payments/verify
    await _api.post('/payments/verify', {
      'razorpay_order_id':   razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature':  razorpaySignature,
      'orderId':             orderId,
    });
  }
}