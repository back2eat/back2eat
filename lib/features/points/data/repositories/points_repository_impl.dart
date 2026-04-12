import '../../../../core/network/api_client.dart';
import '../../domain/entities/points.dart';

abstract class PointsRepository {
  Future<PointsBalance>         getBalance();
  Future<double>                getRedeemableAmount(double orderAmount);
  Future<List<PointsLedgerItem>> getHistory();
}

class PointsRepositoryImpl implements PointsRepository {
  final ApiClient _api;
  PointsRepositoryImpl(this._api);

  @override
  Future<PointsBalance> getBalance() async {
    final data = await _api.get('/points');
    return PointsBalance(
      balance:         (data['balance']         as num?)?.toInt()    ?? 0,
      luckyWinBalance: (data['luckyWinBalance']  as num?)?.toInt()    ?? 0,
      rupeeValue:      (data['rupeeValue']       as num?)?.toDouble() ?? 0.0,
      valuePerPoint:   (data['valuePerPoint']    as num?)?.toDouble() ?? 0.5,
      maxRedeemPercent:(data['maxRedeemPercent'] as num?)?.toInt()    ?? 20,
      earnRate:        (data['earnRate']         as num?)?.toInt()    ?? 10,
    );
  }

  @override
  Future<double> getRedeemableAmount(double orderAmount) async {
    final data = await _api.post('/points/redeemable', {'orderAmount': orderAmount});
    return (data['redeemableAmount'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<List<PointsLedgerItem>> getHistory() async {
    final data = await _api.get('/points/history');
    final list = data['ledger'] as List<dynamic>? ?? [];
    return list.map((e) {
      final j       = e as Map<String, dynamic>;
      final orderJ  = j['orderId'] as Map<String, dynamic>?;
      return PointsLedgerItem(
        id:          j['_id']         as String? ?? '',
        points:      (j['points']     as num?)?.toInt() ?? 0,
        type:        j['type']        as String? ?? 'EARN',
        description: j['description'] as String? ?? _defaultDesc(j),
        reason:      j['reason']      as String?,
        orderNumber: orderJ?['orderNumber'] as String?,
        createdAt:   DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  String _defaultDesc(Map<String, dynamic> j) {
    switch (j['type'] as String? ?? '') {
      case 'EARN':       return 'Earned for completed order';
      case 'REDEEM':     return 'Redeemed on order';
      case 'EXPIRE':     return 'Points expired';
      case 'LUCKY_WIN':  return '🎉 Lucky Draw Prize!';
      case 'ADJUST':     return 'Admin adjustment';
      default:           return 'Points transaction';
    }
  }
}