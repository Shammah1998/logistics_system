import 'package:flutter/material.dart';

/// Responsive utility class for adaptive UI across different screen sizes.
/// 
/// Provides breakpoints, adaptive spacing, fonts, icons, and container sizing
/// that scales proportionally with screen dimensions and respects system
/// accessibility settings like text scaling.
class Responsive {
  // Private constructor to prevent instantiation
  Responsive._();

  // ==================== BREAKPOINTS ====================
  
  /// Small phone breakpoint (< 360px width)
  static const double smallPhoneBreakpoint = 360;
  
  /// Normal phone breakpoint (360-600px width)
  static const double normalPhoneBreakpoint = 600;
  
  /// Tablet breakpoint (> 600px width)
  static const double tabletBreakpoint = 600;
  
  /// Large tablet breakpoint (> 900px width)
  static const double largeTabletBreakpoint = 900;

  // ==================== SCREEN SIZE CHECKS ====================
  
  /// Returns true if device is a small phone (width < 360px)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < smallPhoneBreakpoint;
  }
  
  /// Returns true if device is a normal phone (360px <= width < 600px)
  static bool isNormalPhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallPhoneBreakpoint && width < normalPhoneBreakpoint;
  }
  
  /// Returns true if device is a tablet (width >= 600px)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  /// Returns true if device is a large tablet (width >= 900px)
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeTabletBreakpoint;
  }
  
  /// Returns true if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Returns true if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // ==================== SCREEN DIMENSIONS ====================
  
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Get safe area padding (notch, status bar, navigation bar)
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Get keyboard height when visible
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // ==================== SCALE FACTORS ====================
  
  /// Get the scale factor based on screen width.
  /// Reference width is 375px (iPhone SE/8 size).
  /// Returns a multiplier to scale UI elements proportionally.
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Reference width is 375px (standard mobile design reference)
    return (width / 375).clamp(0.8, 1.4);
  }
  
  /// Get text scale factor from system settings
  static double textScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  // ==================== RESPONSIVE SPACING ====================
  
  /// Get horizontal padding based on screen width.
  /// Uses ~5% of screen width with min/max bounds.
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < smallPhoneBreakpoint) {
      return 16.0; // Minimum for small phones
    } else if (width < normalPhoneBreakpoint) {
      return width * 0.05; // 5% for normal phones (typically 18-30px)
    } else {
      return width * 0.06; // 6% for tablets (36px+)
    }
  }
  
  /// Get standard page padding as EdgeInsets
  static EdgeInsets pagePadding(BuildContext context) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
  
  /// Get responsive spacing based on a base value.
  /// Scales the base spacing proportionally with screen size.
  static double spacing(BuildContext context, double baseSpacing) {
    return baseSpacing * scaleFactor(context);
  }
  
  /// Get small spacing (typically 4-8px range)
  static double spacingXS(BuildContext context) => spacing(context, 4);
  
  /// Get small spacing (typically 8px range)
  static double spacingSM(BuildContext context) => spacing(context, 8);
  
  /// Get medium spacing (typically 12px range)
  static double spacingMD(BuildContext context) => spacing(context, 12);
  
  /// Get large spacing (typically 16px range)
  static double spacingLG(BuildContext context) => spacing(context, 16);
  
  /// Get extra large spacing (typically 20px range)
  static double spacingXL(BuildContext context) => spacing(context, 20);
  
  /// Get extra extra large spacing (typically 24px range)
  static double spacingXXL(BuildContext context) => spacing(context, 24);
  
  /// Get huge spacing (typically 32px range)
  static double spacingHuge(BuildContext context) => spacing(context, 32);

  // ==================== RESPONSIVE FONT SIZES ====================
  
  /// Get responsive font size based on base size.
  /// Respects system text scaling for accessibility.
  static double fontSize(BuildContext context, double baseFontSize) {
    final scale = scaleFactor(context);
    final textScale = textScaleFactor(context);
    // Apply screen scale but limit text scale factor impact to prevent
    // extremely large text that breaks layouts
    final effectiveTextScale = textScale.clamp(0.85, 1.3);
    return baseFontSize * scale * effectiveTextScale;
  }
  
  /// Extra small font size (10-11px range)
  static double fontXS(BuildContext context) => fontSize(context, 11);
  
  /// Small font size (12-13px range)
  static double fontSM(BuildContext context) => fontSize(context, 12);
  
  /// Body/regular font size (13-14px range)
  static double fontBody(BuildContext context) => fontSize(context, 14);
  
  /// Medium font size (14-15px range)
  static double fontMD(BuildContext context) => fontSize(context, 15);
  
  /// Large font size (16-18px range)
  static double fontLG(BuildContext context) => fontSize(context, 16);
  
  /// Extra large font size (18-20px range)
  static double fontXL(BuildContext context) => fontSize(context, 18);
  
  /// Heading font size (20-22px range)
  static double fontHeading(BuildContext context) => fontSize(context, 20);
  
  /// Title font size (24-28px range)
  static double fontTitle(BuildContext context) => fontSize(context, 28);
  
  /// Display font size (32-36px range)
  static double fontDisplay(BuildContext context) => fontSize(context, 36);

  // ==================== RESPONSIVE ICON SIZES ====================
  
  /// Get responsive icon size based on base size.
  static double iconSize(BuildContext context, double baseSize) {
    return baseSize * scaleFactor(context);
  }
  
  /// Small icon size (18-20px range)
  static double iconSM(BuildContext context) => iconSize(context, 18);
  
  /// Medium icon size (20-22px range)
  static double iconMD(BuildContext context) => iconSize(context, 20);
  
  /// Large icon size (22-24px range)
  static double iconLG(BuildContext context) => iconSize(context, 24);
  
  /// Extra large icon size (28-32px range)
  static double iconXL(BuildContext context) => iconSize(context, 28);

  // ==================== RESPONSIVE CONTAINER SIZES ====================
  
  /// Get responsive container size based on base size.
  static double containerSize(BuildContext context, double baseSize) {
    return baseSize * scaleFactor(context);
  }
  
  /// Small avatar size (36-40px)
  static double avatarSM(BuildContext context) => containerSize(context, 36);
  
  /// Medium avatar size (44-48px)
  static double avatarMD(BuildContext context) => containerSize(context, 48);
  
  /// Large avatar size (56-64px)
  static double avatarLG(BuildContext context) => containerSize(context, 64);
  
  /// Extra large avatar size (72-80px)
  static double avatarXL(BuildContext context) => containerSize(context, 80);
  
  /// Small button/icon container (36-40px)
  static double buttonSM(BuildContext context) => containerSize(context, 40);
  
  /// Medium button/icon container (44-48px)
  static double buttonMD(BuildContext context) => containerSize(context, 44);
  
  /// Large button/icon container (52-56px)
  static double buttonLG(BuildContext context) => containerSize(context, 56);

  // ==================== RESPONSIVE BORDER RADIUS ====================
  
  /// Get responsive border radius based on base value.
  static double radius(BuildContext context, double baseRadius) {
    return baseRadius * scaleFactor(context);
  }
  
  /// Small border radius (8px range)
  static double radiusSM(BuildContext context) => radius(context, 8);
  
  /// Medium border radius (12px range)
  static double radiusMD(BuildContext context) => radius(context, 12);
  
  /// Large border radius (16px range)
  static double radiusLG(BuildContext context) => radius(context, 16);
  
  /// Extra large border radius (20px range)
  static double radiusXL(BuildContext context) => radius(context, 20);

  // ==================== MIN TAP TARGET SIZE ====================
  
  /// Minimum touch target size for accessibility (44dp recommended)
  static double minTapTarget(BuildContext context) {
    return 44.0 * scaleFactor(context);
  }

  // ==================== HELPER METHODS ====================
  
  /// Returns a value based on screen size category.
  /// Useful for selecting different values for different screen sizes.
  static T valueByScreenSize<T>({
    required BuildContext context,
    required T small,
    required T normal,
    T? tablet,
  }) {
    if (isSmallPhone(context)) return small;
    if (isTablet(context)) return tablet ?? normal;
    return normal;
  }
  
  /// Returns a value based on orientation.
  static T valueByOrientation<T>({
    required BuildContext context,
    required T portrait,
    required T landscape,
  }) {
    return isLandscape(context) ? landscape : portrait;
  }
  
  /// Get available height after accounting for safe areas and optional
  /// elements like headers or tab bars.
  static double availableHeight(
    BuildContext context, {
    double headerHeight = 0,
    double bottomNavHeight = 0,
    bool excludeStatusBar = true,
    bool excludeBottomInset = true,
  }) {
    final mediaQuery = MediaQuery.of(context);
    double height = mediaQuery.size.height;
    
    if (excludeStatusBar) {
      height -= mediaQuery.padding.top;
    }
    if (excludeBottomInset) {
      height -= mediaQuery.padding.bottom;
    }
    
    height -= headerHeight;
    height -= bottomNavHeight;
    
    return height;
  }
}

