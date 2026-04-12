// ── Entity ────────────────────────────────────────────────────────────

class ReviewEntity {
  final String id;
  final String orderId;
  final String? restaurantName;
  final int rating;
  final String? comment;
  final String? partnerReply;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.orderId,
    this.restaurantName,
    required this.rating,
    this.comment,
    this.partnerReply,
    required this.createdAt,
  });
}