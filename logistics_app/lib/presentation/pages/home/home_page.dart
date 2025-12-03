import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/utils/responsive.dart';
import 'package:logistics_app/core/services/api_service.dart';
import 'package:logistics_app/presentation/widgets/bottom_nav_bar.dart';
import 'package:logistics_app/presentation/pages/orders/orders_page.dart';
import 'package:logistics_app/presentation/pages/earnings/earnings_page.dart';
import 'package:logistics_app/presentation/pages/profile/profile_page.dart';
import 'package:logistics_app/presentation/providers/auth_provider.dart';

// Online status provider
final onlineStatusProvider = StateProvider<bool>((ref) => false);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeContent(),
          OrdersPage(),
          EarningsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _wallet = {};
  List<dynamic> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final wallet = await _apiService.getWallet();
    final orders = await _apiService.getOrders();
    
    setState(() {
      _wallet = wallet;
      _recentOrders = orders.take(3).toList();
      _isLoading = false;
    });
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    // Capture context before async operation
    final ctx = context;
    final iconSize = Responsive.iconMD(ctx);
    final spacingMD = Responsive.spacingMD(ctx);
    final radiusMD = Responsive.radiusMD(ctx);
    final spacingLG = Responsive.spacingLG(ctx);
    
    final success = await _apiService.updateOnlineStatus(value);
    if (success) {
      ref.read(onlineStatusProvider.notifier).state = value;
      if (mounted && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  value ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: iconSize,
                ),
                SizedBox(width: spacingMD),
                Text(value ? 'You are now online' : 'You are now offline'),
              ],
            ),
            backgroundColor: value ? AppTheme.successColor : AppTheme.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
            margin: EdgeInsets.all(spacingLG),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isOnline = ref.watch(onlineStatusProvider);
    final displayName = user?['fullName'] ?? 'Driver';
    final contentPadding = Responsive.spacingXL(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Custom App Bar
                  SliverToBoxAdapter(
                    child: _buildHeader(context, displayName, isOnline),
                  ),
                  
                  // Content
                  SliverPadding(
                    padding: EdgeInsets.all(contentPadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Today Stats
                        _buildTodayStats(context),
                        
                        SizedBox(height: Responsive.spacingXXL(context)),
                        
                        // Recent Orders
                        _buildRecentOrders(context),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayName, bool isOnline) {
    final avatarSize = Responsive.avatarMD(context);
    final horizontalPadding = Responsive.spacingXL(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + Responsive.spacingLG(context),
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: Responsive.spacingXXL(context),
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            children: [
              // Avatar
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
                ),
                child: Center(
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: Responsive.fontHeading(context),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.spacingMD(context) + 2),
              
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: Responsive.fontSM(context),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: Responsive.fontXL(context),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Refresh
              IconButton(
                onPressed: _loadData,
                icon: Icon(Icons.refresh, color: Colors.white70, size: Responsive.iconLG(context)),
              ),
            ],
          ),
          
          SizedBox(height: Responsive.spacingXL(context)),
          
          // Online Status Card
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacingLG(context),
              vertical: Responsive.spacingMD(context),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: Responsive.containerSize(context, 10),
                  height: Responsive.containerSize(context, 10),
                  decoration: BoxDecoration(
                    color: isOnline ? AppTheme.successColor : Colors.white54,
                    shape: BoxShape.circle,
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: AppTheme.successColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                SizedBox(width: Responsive.spacingMD(context)),
                Expanded(
                  child: Text(
                    isOnline ? 'You are Online' : 'You are Offline',
                    style: TextStyle(
                      fontSize: Responsive.fontBody(context),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: isOnline,
                    onChanged: _toggleOnlineStatus,
                    activeThumbColor: AppTheme.successColor,
                    activeTrackColor: AppTheme.successColor.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context) {
    final deliveries = _recentOrders.where((o) => o['status'] == 'delivered').length;
    final earned = _wallet['totalEarned'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Summary',
          style: TextStyle(
            fontSize: Responsive.fontLG(context),
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: Responsive.spacingMD(context)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.local_shipping_outlined,
                iconColor: AppTheme.accentColor,
                value: deliveries.toString(),
                label: 'Deliveries',
              ),
            ),
            SizedBox(width: Responsive.spacingMD(context)),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppTheme.successColor,
                value: 'Ksh $earned',
                label: 'Earned',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final iconContainerSize = Responsive.buttonSM(context);
    
    return Container(
      padding: EdgeInsets.all(Responsive.spacingLG(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radiusSM(context) + 2),
            ),
            child: Icon(icon, color: iconColor, size: Responsive.iconMD(context)),
          ),
          SizedBox(height: Responsive.spacingMD(context)),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.fontHeading(context),
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSM(context),
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: Responsive.fontLG(context),
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (_recentOrders.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to orders tab - handled by parent
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: Responsive.fontSM(context),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: Responsive.spacingMD(context)),
        
        if (_recentOrders.isEmpty)
          _buildEmptyState(context)
        else
          ..._recentOrders.map((order) => _buildOrderCard(context, order)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.inbox_outlined,
              size: Responsive.iconXL(context) + 4,
              color: AppTheme.textMuted,
            ),
          ),
          SizedBox(height: Responsive.spacingLG(context)),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: Responsive.fontMD(context),
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: Responsive.spacingXS(context)),
          Text(
            'New orders will appear here',
            style: TextStyle(
              fontSize: Responsive.fontSM(context),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
            ),
            child: Icon(Icons.local_shipping_outlined, color: statusColor, size: Responsive.iconMD(context) + 2),
          ),
          SizedBox(width: Responsive.spacingMD(context) + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['id']?.toString().substring(0, 8) ?? ''}',
                  style: TextStyle(
                    fontSize: Responsive.fontBody(context),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: Responsive.spacingXS(context)),
                Text(
                  'Ksh ${order['total_amount'] ?? 0}',
                  style: TextStyle(
                    fontSize: Responsive.fontSM(context),
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacingSM(context) + 2,
              vertical: Responsive.spacingXS(context) + 1,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radiusSM(context) - 2),
            ),
            child: Text(
              status.toString().toUpperCase(),
              style: TextStyle(
                fontSize: Responsive.fontXS(context) - 1,
                fontWeight: FontWeight.w600,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successColor;
      case 'in_transit':
        return AppTheme.accentColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textMuted;
    }
  }
}
