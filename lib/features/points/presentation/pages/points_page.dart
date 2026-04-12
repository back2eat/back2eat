import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../data/repositories/points_repository_impl.dart';
import '../../domain/entities/points.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  PointsBalance?         _balance;
  List<PointsLedgerItem> _ledger = [];
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo    = getIt<PointsRepository>();
      final results = await Future.wait([repo.getBalance(), repo.getHistory()]);
      if (mounted) setState(() {
        _balance = results[0] as PointsBalance;
        _ledger  = (results[1] as List).cast<PointsLedgerItem>();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('My Points'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48.sp, color: AppColors.muted),
          SizedBox(height: 12.h),
          Text('Failed to load', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 8.h),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]))
            : RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              _BalanceCard(balance: _balance!),
              SizedBox(height: 16.h),
              _HowItWorksCard(balance: _balance!),
              SizedBox(height: 20.h),
              Row(children: [
                Text('Points History',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('${_ledger.length} transactions',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.muted,
                        fontWeight: FontWeight.w600)),
              ]),
              SizedBox(height: 10.h),
              if (_ledger.isEmpty)
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: Colors.black.withOpacity(0.05))),
                  child: Column(children: [
                    Icon(Icons.history_rounded, size: 40.sp, color: AppColors.muted),
                    SizedBox(height: 8.h),
                    Text('No transactions yet',
                        style: TextStyle(fontSize: 13.sp, color: AppColors.muted,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4.h),
                    Text('Place an order to start earning points!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.muted)),
                  ]),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: _ledger.asMap().entries.map((e) => _LedgerTile(
                      item: e.value,
                      showDivider: e.key < _ledger.length - 1,
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final PointsBalance balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8221A), Color(0xFFB71C1C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r)),
              child: Icon(Icons.stars_rounded, color: Colors.white, size: 20.sp)),
          SizedBox(width: 8.w),
          Text('Back2Eat Points',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.9))),
        ]),
        SizedBox(height: 20.h),
        Text('${balance.balance}',
            style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.0)),
        Text('points',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.75))),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12.r)),
          child: Row(children: [
            Icon(Icons.currency_rupee_rounded, color: Colors.white, size: 16.sp),
            SizedBox(width: 4.w),
            Text('Worth ₹${balance.rupeeValue.toStringAsFixed(0)} on Back2Eat',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ]),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final PointsBalance balance;
  const _HowItWorksCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How Points Work',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 12.h),
        _InfoRow(icon: Icons.add_circle_outline_rounded, color: AppColors.success,
            text: 'Earn 1 point for every ₹${balance.earnRate} you spend'),
        SizedBox(height: 8.h),
        _InfoRow(icon: Icons.redeem_rounded, color: AppColors.primary,
            text: '1 point = ₹${balance.valuePerPoint} — redeemable at checkout'),
        SizedBox(height: 8.h),
        _InfoRow(icon: Icons.percent_rounded, color: AppColors.info,
            text: 'Use up to ${balance.maxRedeemPercent}% of any order value via points'),
        SizedBox(height: 8.h),
        _InfoRow(icon: Icons.emoji_events_rounded, color: const Color(0xFFFFD700),
            text: 'Lucky Draw winners receive full order refund as points'),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(10.r)),
          child: Text(
            'Apply points at checkout → "Use Points" for an instant discount!',
            style: TextStyle(fontSize: 11.5.sp, color: AppColors.success,
                fontWeight: FontWeight.w700, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final Color color; final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16.sp, color: color),
      SizedBox(width: 8.w),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12.sp,
          color: AppColors.text, fontWeight: FontWeight.w600, height: 1.4))),
    ],
  );
}

class _LedgerTile extends StatelessWidget {
  final PointsLedgerItem item;
  final bool             showDivider;
  const _LedgerTile({required this.item, required this.showDivider});

  IconData get _icon {
    switch (item.type) {
      case 'EARN':      return Icons.add_circle_rounded;
      case 'REDEEM':    return Icons.remove_circle_rounded;
      case 'EXPIRE':    return Icons.timer_off_rounded;
      case 'LUCKY_WIN': return Icons.emoji_events_rounded;
      default:          return item.isCredit ? Icons.add_circle_rounded : Icons.remove_circle_rounded;
    }
  }

  Color get _color {
    switch (item.type) {
      case 'EARN':      return AppColors.success;
      case 'REDEEM':    return AppColors.danger;
      case 'EXPIRE':    return AppColors.muted;
      case 'LUCKY_WIN': return const Color(0xFFFFD700);
      default:          return item.isCredit ? AppColors.success : AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(item.createdAt);
    final sign    = item.isCredit ? '+' : '';

    return Column(children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(children: [
          Container(width: 38.w, height: 38.w,
              decoration: BoxDecoration(color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r)),
              child: Icon(_icon, color: _color, size: 18.sp)),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.description.isNotEmpty ? item.description : item.type,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 2.h),
            Text(
              item.orderNumber != null ? '#${item.orderNumber!}  ·  $dateStr' : dateStr,
              style: TextStyle(fontSize: 11.sp, color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ])),
          Text('$sign${item.points} pts',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: _color)),
        ]),
      ),
      if (showDivider) Divider(height: 1, indent: 64.w, color: AppColors.line),
    ]);
  }
}