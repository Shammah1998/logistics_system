import 'package:flutter/material.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/utils/responsive.dart';
import 'package:logistics_app/core/services/api_service.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _wallet = {};
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    final wallet = await _apiService.getWallet();
    setState(() {
      _wallet = wallet;
      _transactions = wallet['transactions'] ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentPadding = Responsive.spacingXL(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: CustomScrollView(
                slivers: [
                  // Header with Balance
                  SliverToBoxAdapter(child: _buildHeader(context)),

                  // Content
                  SliverPadding(
                    padding: EdgeInsets.all(contentPadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Quick Actions
                        _buildQuickActions(context),

                        SizedBox(height: Responsive.spacingXXL(context)),

                        // Transactions
                        _buildTransactionsSection(context),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final balance = (_wallet['balance'] ?? 0).toDouble();
    final pending = (_wallet['pendingBalance'] ?? 0).toDouble();
    final total = (_wallet['totalEarned'] ?? 0).toDouble();
    final horizontalPadding = Responsive.spacingXL(context);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + Responsive.spacingLG(context),
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: Responsive.spacingXXL(context),
      ),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            children: [
              Text(
                'Earnings',
                style: TextStyle(
                  fontSize: Responsive.fontHeading(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadWallet,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white70,
                  size: Responsive.iconLG(context),
                ),
              ),
            ],
          ),

          SizedBox(height: Responsive.spacingXXL(context)),

          // Balance Card
          Container(
            padding: EdgeInsets.all(Responsive.spacingXL(context)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Responsive.radiusXL(context)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: Responsive.fontSM(context),
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: Responsive.spacingSM(context)),
                Text(
                  'Ksh ${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: Responsive.fontDisplay(context),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: Responsive.spacingXL(context)),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceStat(
                        context,
                        'Pending',
                        'Ksh ${pending.toStringAsFixed(0)}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: Responsive.containerSize(context, 36),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildBalanceStat(
                        context,
                        'Total Earned',
                        'Ksh ${total.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.fontLG(context),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: Responsive.spacingXS(context)),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.fontSM(context),
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Withdraw',
            color: AppTheme.successColor,
            onTap: _showWithdrawDialog,
          ),
        ),
        SizedBox(width: Responsive.spacingMD(context)),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.receipt_long_outlined,
            label: 'Statements',
            color: AppTheme.accentColor,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statements feature coming soon')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final iconContainerSize = Responsive.buttonMD(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Responsive.radiusMD(context) + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.radiusMD(context) + 2),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.spacingLG(context),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              Responsive.radiusMD(context) + 2,
            ),
            border: Border.all(
              color: AppTheme.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.radiusMD(context),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: Responsive.iconMD(context) + 2,
                ),
              ),
              SizedBox(height: Responsive.spacingSM(context) + 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSM(context),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: Responsive.fontLG(context),
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: Responsive.spacingMD(context)),

        if (_transactions.isEmpty)
          _buildEmptyTransactions(context)
        else
          ..._transactions.map((tx) => _buildTransactionCard(context, tx)),
      ],
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    final emptyIconSize = Responsive.avatarLG(context);

    return Container(
      padding: EdgeInsets.all(Responsive.spacingHuge(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: emptyIconSize,
            height: emptyIconSize,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: Responsive.iconXL(context) + 4,
              color: AppTheme.textMuted,
            ),
          ),
          SizedBox(height: Responsive.spacingLG(context)),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: Responsive.fontMD(context),
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: Responsive.spacingXS(context)),
          Text(
            'Your earnings will appear here',
            style: TextStyle(
              fontSize: Responsive.fontSM(context),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    final color = isCredit ? AppTheme.successColor : AppTheme.errorColor;
    final iconContainerSize = Responsive.buttonMD(context);

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.spacingSM(context) + 2),
      padding: EdgeInsets.all(Responsive.spacingMD(context) + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radiusMD(context) + 2),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: Responsive.iconMD(context),
            ),
          ),
          SizedBox(width: Responsive.spacingMD(context) + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? 'Transaction',
                  style: TextStyle(
                    fontSize: Responsive.fontBody(context),
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx['created_at']?.toString().split('T')[0] ?? '',
                  style: TextStyle(
                    fontSize: Responsive.fontSM(context),
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}Ksh ${tx['amount']}',
            style: TextStyle(
              fontSize: Responsive.fontMD(context),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Responsive.radiusXL(ctx)),
          ),
        ),
        padding: EdgeInsets.only(
          left: Responsive.spacingXL(ctx),
          right: Responsive.spacingXL(ctx),
          top: Responsive.spacingXL(ctx),
          bottom:
              MediaQuery.of(ctx).viewInsets.bottom + Responsive.spacingXL(ctx),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: Responsive.containerSize(ctx, 40),
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: Responsive.spacingXL(ctx)),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Withdraw Funds',
                  style: TextStyle(
                    fontSize: Responsive.fontXL(ctx),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.textMuted,
                    size: Responsive.iconLG(ctx),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),

            // Available balance
            Container(
              padding: EdgeInsets.all(Responsive.spacingMD(ctx) + 2),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.successColor,
                    size: Responsive.iconMD(ctx),
                  ),
                  SizedBox(width: Responsive.spacingSM(ctx) + 2),
                  Text(
                    'Available: Ksh ${_wallet['balance'] ?? 0}',
                    style: TextStyle(
                      fontSize: Responsive.fontBody(ctx),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.spacingXL(ctx)),

            // Amount Field
            Text('Amount', style: AppTheme.labelStyle(ctx)),
            SizedBox(height: Responsive.spacingSM(ctx)),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: Responsive.fontMD(ctx),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'Ksh ',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx)),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx)),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx)),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),

            SizedBox(height: Responsive.spacingLG(ctx)),

            // Phone Field
            Text('M-Pesa Number', style: AppTheme.labelStyle(ctx)),
            SizedBox(height: Responsive.spacingSM(ctx)),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontSize: Responsive.fontMD(ctx),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '0712 345 678',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx)),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx)),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx)),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),

            SizedBox(height: Responsive.spacingXXL(ctx)),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  final phone = phoneController.text;

                  if (amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text('Enter a valid amount'),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.radiusMD(ctx),
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text('Enter M-Pesa number'),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.radiusMD(ctx),
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  // Capture context before async operation
                  final scaffoldContext = ctx;
                  Navigator.pop(scaffoldContext);

                  final result = await _apiService.requestWithdrawal(
                    amount,
                    phone,
                  );

                  if (mounted && scaffoldContext.mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Request submitted'),
                        backgroundColor: result['success'] == true
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.radiusMD(scaffoldContext),
                          ),
                        ),
                      ),
                    );

                    if (result['success'] == true) {
                      _loadWallet();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.spacingLG(ctx),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.radiusMD(ctx),
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text('Withdraw', style: AppTheme.buttonStyle(ctx)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
