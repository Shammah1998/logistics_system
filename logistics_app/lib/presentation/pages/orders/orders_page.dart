import 'package:flutter/material.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/utils/responsive.dart';
import 'package:logistics_app/core/services/api_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _apiService.getOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  List<dynamic> _getFilteredOrders(String filter) {
    if (filter == 'all') return _orders;
    if (filter == 'active') {
      return _orders.where((o) => 
        o['status'] == 'pending' || o['status'] == 'in_transit'
      ).toList();
    }
    return _orders.where((o) => o['status'] == 'delivered').toList();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate available height dynamically
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final isLandscape = Responsive.isLandscape(context);
    final headerHeight = statusBarHeight + Responsive.spacingLG(context) + Responsive.spacingLG(context) + 24; // padding + text + padding
    final tabBarHeight = Responsive.spacingXL(context) * 2 + 56; // padding + tabbar container
    final contentPadding = Responsive.spacingXL(context);
    final bottomNavHeight = mediaQuery.padding.bottom + 70; // Bottom nav approximate height
    
    // In landscape, use more available height
    final heightMultiplier = isLandscape ? 0.85 : 0.7;
    final availableHeight = mediaQuery.size.height - headerHeight - tabBarHeight - contentPadding * 2 - bottomNavHeight;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),
                  
                  // Tab Bar
                  SliverToBoxAdapter(
                    child: _buildTabBar(context),
                  ),
                  
                  // Content
                  SliverPadding(
                    padding: EdgeInsets.all(contentPadding),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: availableHeight.clamp(
                          isLandscape ? 200 : 300, 
                          mediaQuery.size.height * heightMultiplier,
                        ),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersList(context, 'all'),
                            _buildOrdersList(context, 'active'),
                            _buildOrdersList(context, 'completed'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + Responsive.spacingLG(context),
        left: Responsive.spacingXL(context),
        right: Responsive.spacingXL(context),
        bottom: Responsive.spacingLG(context),
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Row(
        children: [
          Text(
            'My Orders',
            style: TextStyle(
              fontSize: Responsive.fontHeading(context),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadOrders,
            icon: Icon(Icons.refresh, color: Colors.white70, size: Responsive.iconLG(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radiusXL(context))),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.spacingXL(context),
            Responsive.spacingXL(context),
            Responsive.spacingXL(context),
            0,
          ),
          child: Container(
            padding: EdgeInsets.all(Responsive.spacingXS(context)),
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.radiusSM(context) + 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: TextStyle(
                fontSize: Responsive.fontSM(context),
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: Responsive.fontSM(context),
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'All (${_orders.length})'),
                Tab(text: 'Active (${_getFilteredOrders('active').length})'),
                Tab(text: 'Completed (${_getFilteredOrders('completed').length})'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, String filter) {
    final orders = _getFilteredOrders(filter);
    
    if (orders.isEmpty) {
      return _buildEmptyState(context, filter);
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: orders.length,
      itemBuilder: (ctx, index) {
        return _OrderCard(order: orders[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    String message = 'No orders yet';
    String subtitle = 'Your orders will appear here';
    IconData icon = Icons.inbox_outlined;
    
    if (filter == 'active') {
      message = 'No active orders';
      subtitle = 'Active deliveries will appear here';
      icon = Icons.local_shipping_outlined;
    } else if (filter == 'completed') {
      message = 'No completed orders';
      subtitle = 'Completed deliveries will appear here';
      icon = Icons.check_circle_outline;
    }
    
    final emptyIconSize = Responsive.avatarXL(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: emptyIconSize,
            height: emptyIconSize,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(Responsive.radiusXL(context)),
            ),
            child: Icon(icon, size: Responsive.iconXL(context) + 12, color: AppTheme.textMuted),
          ),
          SizedBox(height: Responsive.spacingXL(context)),
          Text(
            message,
            style: TextStyle(
              fontSize: Responsive.fontLG(context),
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: Responsive.spacingXS(context) + 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: Responsive.fontBody(context),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final drops = order['drops'] as List? ?? [];
    final status = order['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final iconContainerSize = Responsive.buttonMD(context);
    final routeDotSize = Responsive.containerSize(context, 10);
    
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.spacingMD(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(context, order),
          borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
          child: Padding(
            padding: EdgeInsets.all(Responsive.spacingLG(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
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
                    SizedBox(width: Responsive.spacingMD(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['id']?.toString().substring(0, 8) ?? ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: Responsive.fontBody(context),
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order['created_at']?.toString().split('T')[0] ?? '',
                            style: TextStyle(
                              fontSize: Responsive.fontSM(context),
                              color: AppTheme.textMuted,
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
                
                SizedBox(height: Responsive.spacingLG(context)),
                
                // Route
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: routeDotSize,
                          height: routeDotSize,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 2,
                          height: Responsive.containerSize(context, 24),
                          color: AppTheme.borderColor,
                        ),
                        Container(
                          width: routeDotSize,
                          height: routeDotSize,
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.errorColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: Responsive.spacingMD(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['pickup_address']?['address'] ?? 'Pickup location',
                            style: TextStyle(
                              fontSize: Responsive.fontSM(context),
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Responsive.spacingMD(context) + 2),
                          Text(
                            drops.isNotEmpty 
                                ? '${drops.length} drop${drops.length > 1 ? 's' : ''}'
                                : 'Drop location',
                            style: TextStyle(
                              fontSize: Responsive.fontSM(context),
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(vertical: Responsive.spacingMD(context)),
                  child: const Divider(height: 1, color: AppTheme.borderLight),
                ),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ksh ${order['total_amount'] ?? 0}',
                      style: TextStyle(
                        fontSize: Responsive.fontLG(context),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: Responsive.fontSM(context),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        SizedBox(width: Responsive.spacingXS(context)),
                        Icon(Icons.arrow_forward, size: Responsive.iconSM(context) - 2, color: AppTheme.accentColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radiusXL(ctx))),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetCtx, scrollController) => ListView(
            controller: scrollController,
            padding: EdgeInsets.all(Responsive.spacingXL(sheetCtx)),
            children: [
              // Handle
              Center(
                child: Container(
                  width: Responsive.containerSize(sheetCtx, 40),
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: Responsive.spacingXL(sheetCtx)),
              
              // Header
              Row(
                children: [
                  Container(
                    width: Responsive.avatarMD(sheetCtx),
                    height: Responsive.avatarMD(sheetCtx),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(Responsive.radiusMD(sheetCtx)),
                    ),
                    child: Icon(Icons.receipt_long, color: Colors.white, size: Responsive.iconLG(sheetCtx)),
                  ),
                  SizedBox(width: Responsive.spacingMD(sheetCtx) + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['id']?.toString().substring(0, 8) ?? ''}',
                          style: TextStyle(
                            fontSize: Responsive.fontXL(sheetCtx),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          order['created_at']?.toString().split('T')[0] ?? '',
                          style: TextStyle(
                            fontSize: Responsive.fontSM(sheetCtx),
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacingMD(sheetCtx),
                      vertical: Responsive.spacingXS(sheetCtx) + 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Responsive.radiusSM(sheetCtx)),
                    ),
                    child: Text(
                      order['status']?.toString().toUpperCase() ?? 'PENDING',
                      style: TextStyle(
                        fontSize: Responsive.fontSM(sheetCtx),
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(order['status']),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: Responsive.spacingXXL(sheetCtx)),
              
              // Amount
              Container(
                padding: EdgeInsets.all(Responsive.spacingLG(sheetCtx)),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(sheetCtx)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: Responsive.fontBody(sheetCtx),
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Ksh ${order['total_amount'] ?? 0}',
                      style: TextStyle(
                        fontSize: Responsive.fontHeading(sheetCtx),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: Responsive.spacingXL(sheetCtx)),
              
              // Pickup
              Text(
                'Pickup Location',
                style: TextStyle(
                  fontSize: Responsive.fontBody(sheetCtx),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: Responsive.spacingSM(sheetCtx)),
              Container(
                padding: EdgeInsets.all(Responsive.spacingMD(sheetCtx) + 2),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(sheetCtx)),
                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: Responsive.containerSize(sheetCtx, 10), color: AppTheme.successColor),
                    SizedBox(width: Responsive.spacingMD(sheetCtx)),
                    Expanded(
                      child: Text(
                        order['pickup_address']?['address'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: Responsive.fontBody(sheetCtx),
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: Responsive.spacingLG(sheetCtx)),
              
              // Drops
              Text(
                'Drop Locations',
                style: TextStyle(
                  fontSize: Responsive.fontBody(sheetCtx),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: Responsive.spacingSM(sheetCtx)),
              ...(order['drops'] as List? ?? []).map((drop) => Container(
                margin: EdgeInsets.only(bottom: Responsive.spacingSM(sheetCtx)),
                padding: EdgeInsets.all(Responsive.spacingMD(sheetCtx) + 2),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(Responsive.radiusMD(sheetCtx)),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: Responsive.iconSM(sheetCtx), color: AppTheme.errorColor),
                    SizedBox(width: Responsive.spacingMD(sheetCtx)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drop['recipient_name'] ?? 'Recipient',
                            style: TextStyle(
                              fontSize: Responsive.fontBody(sheetCtx),
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            drop['address']?['address'] ?? 'Address',
                            style: TextStyle(
                              fontSize: Responsive.fontSM(sheetCtx),
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacingSM(sheetCtx),
                        vertical: Responsive.spacingXS(sheetCtx),
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(drop['status']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Responsive.radiusSM(sheetCtx) - 2),
                      ),
                      child: Text(
                        drop['status']?.toString().toUpperCase() ?? '',
                        style: TextStyle(
                          fontSize: Responsive.fontXS(sheetCtx) - 1,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(drop['status']),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
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
