import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/auth_models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  List<CashbackTransaction> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AuthService().addListener(_onAuthChange);
    _loadData();
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() => _profile = AuthService().cachedProfile);
  }

  Future<void> _loadData({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AuthService().getProfile(forceRefresh: refresh),
        AuthService().getTransactions(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile;
        _transactions = results[1] as List<CashbackTransaction>;
        _loading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        context.go('/login');
        return;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load your profile. Pull down to retry.';
      });
    }
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _displayName(UserProfile p) =>
      p.name?.split(' ').first ?? p.phone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: kOrange,
          onRefresh: () => _loadData(refresh: true),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: kOrange))
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 52, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _loadData(refresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(p)),
        SliverToBoxAdapter(child: _buildBalanceCard(p)),
        SliverToBoxAdapter(child: _buildRedeemCard()),
        if (_transactions.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildTransactionsHeader()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildTransactionTile(_transactions[i]),
              childCount: _transactions.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ] else ...[
          SliverToBoxAdapter(child: _buildEmptyTransactions()),
        ],
      ],
    );
  }

  Widget _buildHeader(UserProfile p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()},',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                _displayName(p),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const Spacer(),
          Image.asset('assets/images/animated_logo.png', height: 36),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(UserProfile p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kOrange, kOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kOrange.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Cashback Balance',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Available',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'RM ${_fmt(p.totalPoints)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.totalPoints > 0
                ? 'Ready to redeem on your next visit'
                : 'Earn cashback on your next purchase',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kOrangeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: kOrange, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to redeem',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Tell our staff your phone number at the counter — your cashback will be applied automatically.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        'Transaction History',
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A)),
      ),
    );
  }

  Widget _buildTransactionTile(CashbackTransaction tx) {
    final isEarn = tx.type == 'earn';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isEarn
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn ? Icons.add_rounded : Icons.remove_rounded,
              color: isEarn ? Colors.green.shade600 : Colors.red.shade400,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ??
                      (isEarn ? 'Cashback Earned' : 'Cashback Redeemed'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A)),
                ),
                if (tx.storeAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.storeAddress!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatDate(tx.date),
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Text(
            '${isEarn ? '+' : '-'}RM ${_fmt(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isEarn ? Colors.green.shade600 : Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: kOrangeBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: kOrange, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your cashback history will appear here after your first purchase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
