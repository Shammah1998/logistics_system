import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/utils/responsive.dart';
import 'package:logistics_app/core/services/api_service.dart';
import 'package:logistics_app/presentation/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _profile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _apiService.getProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final displayName = _profile['fullName'] ?? user?['fullName'] ?? 'Driver';
    final phone = _profile['phone'] ?? user?['phone'] ?? '';
    final vehicleType = _profile['vehicleType'] ?? '';
    final contentPadding = Responsive.spacingXL(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context, displayName, phone, vehicleType),
                  ),
                  
                  // Content
                  SliverPadding(
                    padding: EdgeInsets.all(contentPadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Vehicle Info
                        if (_profile['vehicleRegistration'] != null || _profile['licenseNumber'] != null)
                          _buildVehicleInfo(context),
                        
                        SizedBox(height: Responsive.spacingLG(context)),
                        
                        // Wallet Summary
                        _buildWalletCard(context),
                        
                        SizedBox(height: Responsive.spacingLG(context)),
                        
                        // Menu Items
                        _buildMenuSection(context),
                        
                        SizedBox(height: Responsive.spacingXXL(context)),
                        
                        // Logout Button
                        _buildLogoutButton(context),
                        
                        SizedBox(height: Responsive.spacingLG(context)),
                        
                        // Version
                        Center(
                          child: Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: Responsive.fontSM(context),
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: Responsive.spacingXL(context)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayName, String phone, String vehicleType) {
    final horizontalPadding = Responsive.spacingXL(context);
    final avatarSize = Responsive.avatarXL(context);
    
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
        children: [
          // Top Row
          Row(
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: Responsive.fontXL(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadProfile,
                icon: Icon(Icons.refresh, color: Colors.white70, size: Responsive.iconLG(context)),
              ),
            ],
          ),
          
          SizedBox(height: Responsive.spacingXXL(context)),
          
          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Responsive.radiusXL(context)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: Responsive.fontDisplay(context) - 4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          SizedBox(height: Responsive.spacingLG(context)),
          
          // Name
          Text(
            displayName,
            style: TextStyle(
              fontSize: Responsive.fontHeading(context),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: Responsive.spacingXS(context)),
          
          // Phone
          Text(
            phone,
            style: TextStyle(
              fontSize: Responsive.fontBody(context),
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          
          if (vehicleType.isNotEmpty) ...[
            SizedBox(height: Responsive.spacingMD(context)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacingMD(context) + 2,
                vertical: Responsive.spacingXS(context) + 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Responsive.radiusXL(context)),
              ),
              child: Text(
                vehicleType.toUpperCase(),
                style: TextStyle(
                  fontSize: Responsive.fontXS(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacingLG(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: TextStyle(
              fontSize: Responsive.fontBody(context),
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: Responsive.spacingMD(context)),
          if (_profile['vehicleRegistration'] != null)
            _buildInfoRow(context, Icons.directions_car_outlined, 'Registration', _profile['vehicleRegistration']),
          if (_profile['licenseNumber'] != null) ...[
            SizedBox(height: Responsive.spacingSM(context) + 2),
            _buildInfoRow(context, Icons.badge_outlined, 'License', _profile['licenseNumber']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final iconContainerSize = Responsive.avatarSM(context);
    
    return Row(
      children: [
        Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(Responsive.radiusSM(context) + 2),
          ),
          child: Icon(icon, size: Responsive.iconSM(context), color: AppTheme.textSecondary),
        ),
        SizedBox(width: Responsive.spacingMD(context)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontXS(context),
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.fontBody(context),
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    final balance = _profile['wallet']?['balance'] ?? 0;
    final iconContainerSize = Responsive.buttonMD(context);
    
    return Container(
      padding: EdgeInsets.all(Responsive.spacingLG(context)),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
      ),
      child: Row(
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: Responsive.iconMD(context) + 2,
            ),
          ),
          SizedBox(width: Responsive.spacingMD(context) + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    fontSize: Responsive.fontSM(context),
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ksh $balance',
                  style: TextStyle(
                    fontSize: Responsive.fontHeading(context),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white70, size: Responsive.iconLG(context)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: _showHelpDialog,
          ),
          _buildDivider(context),
          _buildMenuItem(
            context: context,
            icon: Icons.phone_outlined,
            title: 'Contact Support',
            onTap: _callSupport,
          ),
          _buildDivider(context),
          _buildMenuItem(
            context: context,
            icon: Icons.info_outline,
            title: 'About',
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final iconContainerSize = Responsive.buttonSM(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacingLG(context),
            vertical: Responsive.spacingMD(context) + 2,
          ),
          child: Row(
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(Responsive.radiusSM(context) + 2),
                ),
                child: Icon(icon, size: Responsive.iconMD(context), color: AppTheme.textSecondary),
              ),
              SizedBox(width: Responsive.spacingMD(context) + 2),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.fontMD(context),
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: Responsive.iconMD(context), color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.spacingLG(context)),
      child: const Divider(height: 1, color: AppTheme.borderLight),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: Icon(Icons.logout, size: Responsive.iconMD(context)),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          side: const BorderSide(color: AppTheme.errorColor),
          padding: EdgeInsets.symmetric(vertical: Responsive.spacingMD(context) + 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radiusXL(ctx))),
        ),
        padding: EdgeInsets.all(Responsive.spacingXL(ctx)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Responsive.containerSize(ctx, 40),
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: Responsive.spacingXL(ctx)),
            Text(
              'Help & Support',
              style: AppTheme.subheadingStyle(ctx),
            ),
            SizedBox(height: Responsive.spacingSM(ctx)),
            Text(
              'Need help? Contact us through:',
              style: TextStyle(
                fontSize: Responsive.fontBody(ctx),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: Responsive.spacingXL(ctx)),
            _buildContactOption(
              ctx,
              Icons.phone_outlined,
              'Call Support',
              '+254 700 000 000',
              _callSupport,
            ),
            SizedBox(height: Responsive.spacingMD(ctx)),
            _buildContactOption(
              ctx,
              Icons.email_outlined,
              'Email Support',
              'support@xobo.co.ke',
              _emailSupport,
            ),
            SizedBox(height: Responsive.spacingXL(ctx)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: AppTheme.backgroundColor,
      borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacingMD(context) + 2),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accentColor, size: Responsive.iconLG(context)),
              SizedBox(width: Responsive.spacingMD(context) + 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.fontBody(context),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSM(context),
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel:+254700000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone app')),
        );
      }
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri.parse('mailto:support@xobo.co.ke?subject=Driver%20App%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radiusXL(ctx))),
        title: Row(
          children: [
            Container(
              width: Responsive.buttonSM(ctx),
              height: Responsive.buttonSM(ctx),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(Responsive.radiusSM(ctx) + 2),
              ),
              child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: Responsive.iconMD(ctx)),
            ),
            SizedBox(width: Responsive.spacingMD(ctx)),
            Text('Xobo Driver', style: TextStyle(fontSize: Responsive.fontXL(ctx))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: Responsive.fontBody(ctx),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: Responsive.spacingMD(ctx)),
            Text(
              'Xobo Driver helps you manage deliveries, track earnings, and stay connected with your logistics network.',
              style: TextStyle(
                fontSize: Responsive.fontBody(ctx),
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
            SizedBox(height: Responsive.spacingLG(ctx)),
            Text(
              '© 2025 Xobo Logistics',
              style: TextStyle(
                fontSize: Responsive.fontSM(ctx),
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radiusXL(dialogContext))),
        title: Text('Log Out', style: TextStyle(fontSize: Responsive.fontXL(dialogContext))),
        content: Text('Are you sure you want to log out?', style: TextStyle(fontSize: Responsive.fontBody(dialogContext))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Show loading indicator
              if (!mounted) return;
              final loadingDialogContext = context;
              showDialog(
                context: loadingDialogContext,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Perform logout
              await ref.read(authProvider.notifier).signOut();
              
              // The main.dart will automatically navigate to login
              // because it watches authState.isAuthenticated
              // Use the dialog's context which is still valid
              if (mounted && loadingDialogContext.mounted) {
                Navigator.of(loadingDialogContext).pop(); // Close loading dialog
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
