// ── Entity ────────────────────────────────────────────────────────────

class RazorpayOrder {
  final String razorpayOrderId;
  final String orderId;  // our internal order id
  final double amount;
  final String currency;
  final String keyId;

  const RazorpayOrder({
    required this.razorpayOrderId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });
}