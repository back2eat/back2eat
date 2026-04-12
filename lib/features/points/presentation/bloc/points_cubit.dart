import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/points_repository_impl.dart';
import '../../domain/entities/points.dart';

// ── State ─────────────────────────────────────────────────────────────

class PointsState {
  final bool loading;
  final PointsBalance? balance;
  final List<PointsHistoryItem> history;
  final String? error;

  const PointsState({
    this.loading = false,
    this.balance,
    this.history = const [],
    this.error,
  });

  PointsState copyWith({
    bool? loading,
    PointsBalance? balance,
    List<PointsHistoryItem>? history,
    String? error,
  }) =>
      PointsState(
        loading: loading ?? this.loading,
        balance: balance ?? this.balance,
        history: history ?? this.history,
        error: error,
      );
}

// ── Cubit ─────────────────────────────────────────────────────────────

class PointsCubit extends Cubit<PointsState> {
  final PointsRepository _repo;

  PointsCubit(this._repo) : super(const PointsState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final results = await Future.wait([
        _repo.getBalance(),
        _repo.getHistory(),
      ]);
      emit(state.copyWith(
        loading: false,
        balance: results[0] as PointsBalance,
        history: results[1] as List<PointsHistoryItem>,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<double> getRedeemable(double orderTotal) =>
      _repo.getRedeemableAmount(orderTotal);
}