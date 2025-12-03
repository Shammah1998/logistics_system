import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/utils/responsive.dart';
import 'package:logistics_app/presentation/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  String _selectedCountryCode = '+254';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Capture context before async operation
      final ctx = context;
      final iconSize = Responsive.iconMD(ctx);
      final spacingMD = Responsive.spacingMD(ctx);
      final radiusMD = Responsive.radiusMD(ctx);
      final spacingLG = Responsive.spacingLG(ctx);
      
      try {
        final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
        await ref.read(authProvider.notifier).signIn(
              fullPhoneNumber,
              _pinController.text,
            );
        // Navigation is handled by main.dart watching auth state
      } catch (e) {
        if (mounted && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: iconSize),
                  SizedBox(width: spacingMD),
                  Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
              margin: EdgeInsets.all(spacingLG),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final horizontalPadding = Responsive.horizontalPadding(context);
    final isLandscape = Responsive.isLandscape(context);
    
    // Adjust spacing for landscape mode
    final topSpacing = isLandscape ? size.height * 0.04 : size.height * 0.08;
    final middleSpacing = isLandscape ? size.height * 0.03 : size.height * 0.06;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - bottomPadding,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: isLandscape
                        ? _buildLandscapeLayout(context, topSpacing, middleSpacing)
                        : _buildPortraitLayout(context, topSpacing, middleSpacing),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPortraitLayout(BuildContext context, double topSpacing, double middleSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: topSpacing),
        
        // Brand Header
        _buildBrandHeader(context),
        
        SizedBox(height: middleSpacing),
        
        // Login Card
        _buildLoginCard(context),
        
        SizedBox(height: Responsive.spacingHuge(context)),
        
        // Stats Section
        _buildStatsSection(context),
        
        SizedBox(height: Responsive.spacingXXL(context)),
      ],
    );
  }
  
  Widget _buildLandscapeLayout(BuildContext context, double topSpacing, double middleSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: topSpacing),
        
        // In landscape, show header and login side by side if space permits
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildBrandHeader(context),
            ),
            SizedBox(width: Responsive.spacingXL(context)),
            Expanded(
              flex: 1,
              child: _buildLoginCard(context),
            ),
          ],
        ),
        
        SizedBox(height: Responsive.spacingXL(context)),
        
        // Stats Section
        _buildStatsSection(context),
        
        SizedBox(height: Responsive.spacingLG(context)),
      ],
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    final logoSize = Responsive.containerSize(context, 56);
    final iconSize = Responsive.iconSize(context, 28);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(Responsive.radiusMD(context)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.local_shipping_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
        
        SizedBox(height: Responsive.spacingXXL(context)),
        
        // Welcome Text
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacingMD(context),
            vertical: Responsive.spacingXS(context) + 2,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Responsive.radiusXL(context)),
          ),
          child: Text(
            'Driver Portal',
            style: TextStyle(
              fontSize: Responsive.fontSM(context),
              fontWeight: FontWeight.w600,
              color: AppTheme.accentColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        SizedBox(height: Responsive.spacingMD(context)),
        
        Text(
          'Welcome back',
          style: AppTheme.titleStyle(context),
        ),
        
        SizedBox(height: Responsive.spacingSM(context)),
        
        Text(
          'Sign in to access your dashboard and manage deliveries.',
          style: TextStyle(
            fontSize: Responsive.fontMD(context),
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final cardPadding = Responsive.spacingXXL(context);
    final borderRadius = Responsive.radiusXL(context);
    final fieldBorderRadius = Responsive.radiusMD(context);
    final fieldPadding = Responsive.spacingLG(context);
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone Field
          Text(
            'Phone number',
            style: AppTheme.labelStyle(context),
          ),
          SizedBox(height: Responsive.spacingSM(context)),
          Row(
            children: [
              // Country Code
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.spacingMD(context) + 2,
                    vertical: fieldPadding,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🇰🇪', style: TextStyle(fontSize: Responsive.fontXL(context))),
                      SizedBox(width: Responsive.spacingXS(context) + 2),
                      Text(
                        _selectedCountryCode,
                        style: TextStyle(
                          fontSize: Responsive.fontBody(context),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: Responsive.spacingXS(context)),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: Responsive.iconSM(context),
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: Responsive.spacingMD(context)),
              
              // Phone Input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: Responsive.fontMD(context),
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '712 345 678',
                    hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: fieldPadding,
                      vertical: fieldPadding,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your phone number';
                    }
                    if (value.length < 9) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: Responsive.spacingXL(context)),
          
          // PIN Field
          Text(
            'PIN',
            style: AppTheme.labelStyle(context),
          ),
          SizedBox(height: Responsive.spacingSM(context)),
          TextFormField(
            controller: _pinController,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: Responsive.fontMD(context),
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: '• • • •',
              hintStyle: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: fieldPadding,
                vertical: fieldPadding,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted,
                  size: Responsive.iconMD(context),
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your PIN';
              }
              if (value.length < 4) {
                return 'PIN must be at least 4 digits';
              }
              return null;
            },
          ),
          
          SizedBox(height: Responsive.spacingXXL(context)),
          
          // Sign In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: fieldPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                ),
                elevation: 0,
                disabledBackgroundColor: AppTheme.textMuted.withValues(alpha: 0.3),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: Responsive.iconMD(context),
                      width: Responsive.iconMD(context),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Sign in',
                      style: AppTheme.buttonStyle(context),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacingXL(context)),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(Responsive.radiusLG(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join our driver network',
            style: TextStyle(
              fontSize: Responsive.fontSM(context),
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: Responsive.spacingLG(context)),
          Row(
            children: [
              _buildStatItem(context, '450+', 'Daily Jobs'),
              _buildStatDivider(context),
              _buildStatItem(context, '120', 'Drivers'),
              _buildStatDivider(context),
              _buildStatItem(context, '98%', 'On-time'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.fontHeading(context) + 2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.spacingXS(context)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontXS(context),
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      height: Responsive.containerSize(context, 32),
      width: 1,
      color: Colors.white24,
    );
  }

  void _showCountryPicker() {
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
              'Select Country',
              style: AppTheme.subheadingStyle(ctx),
            ),
            SizedBox(height: Responsive.spacingLG(ctx)),
            ListTile(
              leading: Text('🇰🇪', style: TextStyle(fontSize: Responsive.fontTitle(ctx))),
              title: Text('Kenya', style: TextStyle(fontWeight: FontWeight.w500, fontSize: Responsive.fontBody(ctx))),
              trailing: Text('+254', style: TextStyle(color: AppTheme.textSecondary, fontSize: Responsive.fontBody(ctx))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radiusMD(ctx))),
              onTap: () {
                setState(() => _selectedCountryCode = '+254');
                Navigator.pop(ctx);
              },
            ),
            SizedBox(height: Responsive.spacingXL(ctx)),
          ],
        ),
      ),
    );
  }
}
