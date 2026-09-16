import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _balance = 2847.50;
  bool _showBalance = true;

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: '1',
      type: 'Visa',
      last4: '4242',
      holder: 'Alexey Volkov',
      expiry: '12/28',
      isDefault: true,
      color: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1F71), Color(0xFF414BB2)],
      ),
    ),
    PaymentMethod(
      id: '2',
      type: 'WeChat Pay',
      last4: '微信支付',
      holder: 'Linked',
      expiry: '',
      color: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF07C160), Color(0xFF06AD56)],
      ),
    ),
    PaymentMethod(
      id: '3',
      type: 'Yandex Pay',
      last4: 'Яндекс',
      holder: 'Linked',
      expiry: '',
      color: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF0000), Color(0xFFFFCC00)],
      ),
    ),
    PaymentMethod(
      id: '4',
      type: 'Apple Pay',
      last4: '',
      holder: 'iPhone 15 Pro',
      expiry: '',
      color: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D1D1F), Color(0xFF424245)],
      ),
    ),
  ];

  final List<Transaction> _transactions = [
    Transaction(id: '1', title: 'Nike Dunk Low Purchase', amount: -129.00, date: 'Today, 14:32', type: TransactionType.purchase, status: 'Completed'),
    Transaction(id: '2', title: 'Sale - Adidas Samba', amount: 75.00, date: 'Today, 11:15', type: TransactionType.sale, status: 'Completed'),
    Transaction(id: '3', title: 'Wallet Top-up', amount: 500.00, date: 'Yesterday', type: TransactionType.topup, status: 'Completed'),
    Transaction(id: '4', title: 'Group Buy Refund', amount: 18.50, date: 'Yesterday', type: TransactionType.refund, status: 'Completed'),
    Transaction(id: '5', title: 'Seller Payout', amount: 234.00, date: '2 days ago', type: TransactionType.sale, status: 'Completed'),
    Transaction(id: '6', title: 'AR Try-On Purchase', amount: -89.00, date: '3 days ago', type: TransactionType.purchase, status: 'Completed'),
    Transaction(id: '7', title: 'Dewu Auth Fee', amount: -15.00, date: '4 days ago', type: TransactionType.fee, status: 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            _buildQuickActions(),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Cards'),
                Tab(text: 'Transactions'),
                Tab(text: 'Rewards'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentMethods(),
                  _buildTransactions(),
                  _buildRewards(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Wallet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.background,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showBalance ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.background.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showBalance = !_showBalance),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showBalance ? '£${_balance.toStringAsFixed(2)}' : '£••••••',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: AppTheme.background,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, color: AppTheme.background, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '+12.5% this month',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.background,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: AppTheme.background, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Gold Member',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.background,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(Icons.arrow_downward, 'Top Up', AppTheme.success),
          _buildQuickAction(Icons.arrow_upward, 'Withdraw', AppTheme.info),
          _buildQuickAction(Icons.send, 'Transfer', AppTheme.warning),
          _buildQuickAction(Icons.qr_code_scanner, 'Scan Pay', AppTheme.accent),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ..._paymentMethods.map((method) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 110,
            decoration: BoxDecoration(
              gradient: method.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            method.type,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (method.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.holder,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method.last4.isNotEmpty ? '•••• ${method.last4}' : '',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          if (method.expiry.isNotEmpty)
                            Text(
                              method.expiry,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Card pattern
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: 20,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Payment Method'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getTxColor(tx.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getTxIcon(tx.type), color: _getTxColor(tx.type), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.date,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.amount.isNegative ? '' : '+'}£${tx.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: tx.amount.isNegative ? AppTheme.textPrimary : AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.status,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewards() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'S8LL Points',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.background,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '12,480',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.background,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '= £124.80 in rewards',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.background,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ways to Earn',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildRewardItem(Icons.shopping_bag, 'Make a Purchase', '+100 points per £10 spent', 80),
        _buildRewardItem(Icons.sell, 'Sell an Item', '+200 points per sale', 60),
        _buildRewardItem(Icons.reviews, 'Leave a Review', '+50 points', 100),
        _buildRewardItem(Icons.people, 'Refer a Friend', '+500 points bonus', 30),
        _buildRewardItem(Icons.live_tv, 'Watch Live Stream', '+25 points per 10 min', 45),
        const SizedBox(height: 24),
        const Text(
          'Available Rewards',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildRewardCard('£10 Off', '1,000 pts', Icons.discount),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRewardCard('Free Auth', '2,000 pts', Icons.verified_user),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRewardCard('Free Shipping', '3,000 pts', Icons.local_shipping),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRewardCard('£50 Cash', '5,000 pts', Icons.payments),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardItem(IconData icon, String title, String subtitle, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(String title, String cost, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cost,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTxIcon(TransactionType type) {
    switch (type) {
      case TransactionType.purchase:
        return Icons.shopping_bag;
      case TransactionType.sale:
        return Icons.sell;
      case TransactionType.topup:
        return Icons.arrow_downward;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.fee:
        return Icons.receipt;
    }
  }

  Color _getTxColor(TransactionType type) {
    switch (type) {
      case TransactionType.purchase:
        return AppTheme.info;
      case TransactionType.sale:
        return AppTheme.success;
      case TransactionType.topup:
        return AppTheme.accent;
      case TransactionType.refund:
        return AppTheme.warning;
      case TransactionType.fee:
        return AppTheme.textMuted;
    }
  }
}

enum TransactionType { purchase, sale, topup, refund, fee }

class PaymentMethod {
  final String id;
  final String type;
  final String last4;
  final String holder;
  final String expiry;
  final bool isDefault;
  final Gradient color;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.holder,
    required this.expiry,
    this.isDefault = false,
    required this.color,
  });
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String date;
  final TransactionType type;
  final String status;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
  });
}
