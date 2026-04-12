import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/review.dart';

// ── Repository ────────────────────────────────────────────────────────

class ReviewRepository {
  final ApiClient _api;
  ReviewRepository(this._api);

  ReviewEntity _fromJson(Map<String, dynamic> j) => ReviewEntity(
    id: j['_id'] as String? ?? j['id'] as String,
    orderId: j['orderId'] as String? ?? '',
    restaurantName:
    (j['restaurant'] as Map?)?['restaurantName'] as String?,
    rating: (j['rating'] as num?)?.toInt() ?? 5,
    comment: j['comment'] as String?,
    partnerReply: j['partnerReply'] as String?,
    createdAt: DateTime.parse(
        j['createdAt'] as String? ?? DateTime.now().toIso8601String()),
  );

  /// POST /reviews  — submit review after a completed order
  Future<ReviewEntity> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final data = await _api.post('/reviews', {
      'orderId': orderId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return _fromJson(data['review'] as Map<String, dynamic>);
  }

  /// GET /reviews/my
  Future<List<ReviewEntity>> getMyReviews() async {
    final data = await _api.get('/reviews/my');
    final list = data['reviews'] as List<dynamic>? ?? [];
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ── State ─────────────────────────────────────────────────────────────

class ReviewsState {
  final bool loading;
  final bool submitting;
  final List<ReviewEntity> reviews;
  final bool submitted;
  final String? error;

  const ReviewsState({
    this.loading = false,
    this.submitting = false,
    this.reviews = const [],
    this.submitted = false,
    this.error,
  });

  ReviewsState copyWith({
    bool? loading,
    bool? submitting,
    List<ReviewEntity>? reviews,
    bool? submitted,
    String? error,
  }) =>
      ReviewsState(
        loading: loading ?? this.loading,
        submitting: submitting ?? this.submitting,
        reviews: reviews ?? this.reviews,
        submitted: submitted ?? this.submitted,
        error: error,
      );
}

// ── Cubit ─────────────────────────────────────────────────────────────

class ReviewsCubit extends Cubit<ReviewsState> {
  final ReviewRepository _repo;

  ReviewsCubit(this._repo) : super(const ReviewsState());

  Future<void> loadMyReviews() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final reviews = await _repo.getMyReviews();
      emit(state.copyWith(loading: false, reviews: reviews));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    emit(state.copyWith(submitting: true, error: null, submitted: false));
    try {
      final review = await _repo.submitReview(
          orderId: orderId, rating: rating, comment: comment);
      emit(state.copyWith(
        submitting: false,
        submitted: true,
        reviews: [review, ...state.reviews],
      ));
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}