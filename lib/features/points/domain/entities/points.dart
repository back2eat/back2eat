class PointsBalance {
  final int    balance;
  final int    luckyWinBalance;  // points from lucky draw wins — fully redeemable
  final double rupeeValue;
  final double valuePerPoint;
  final int    maxRedeemPercent;
  final int    earnRate;

  const PointsBalance({
    required this.balance,
    this.luckyWinBalance = 0,
    required this.rupeeValue,
    required this.valuePerPoint,
    required this.maxRedeemPercent,
    required this.earnRate,
  });
}

class PointsLedgerItem {
  final String   id;
  final int      points;
  final String   type;         // EARN | REDEEM | EXPIRE | ADJUST | LUCKY_WIN
  final String   description;
  final String?  reason;
  final String?  orderNumber;
  final DateTime createdAt;

  const PointsLedgerItem({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    this.reason,
    this.orderNumber,
    required this.createdAt,
  });

  bool get isCredit => points > 0;
}

// Alias for backwards compatibility with PointsCubit
typedef PointsHistoryItem = PointsLedgerItem;