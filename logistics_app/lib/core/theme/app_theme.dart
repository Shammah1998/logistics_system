import 'package:flutter/material.dart';
import 'package:logistics_app/core/utils/responsive.dart';

class AppTheme {
  // Brand Colors - Sharp modern palette
  static const Color primaryColor = Color(0xFF0f172a); // Slate 900 - dark
  static const Color primaryLight = Color(0xFF1e293b); // Slate 800
  static const Color accentColor = Color(0xFF0ea5e9); // Sky 500 - vibrant accent
  static const Color accentDark = Color(0xFF0284c7); // Sky 600
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color successColor = Color(0xFF10b981); // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color warningColor = Color(0xFFf59e0b); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color errorColor = Color(0xFFef4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0f172a); // Slate 900
  static const Color textSecondary = Color(0xFF64748b); // Slate 500
  static const Color textMuted = Color(0xFF94a3b8); // Slate 400
  
  // Border Colors
  static const Color borderColor = Color(0xFFe2e8f0); // Slate 200
  static const Color borderLight = Color(0xFFf1f5f9); // Slate 100
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF334155)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, accentDark],
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: backgroundColor,
    iconTheme: const IconThemeData(
      color: textPrimary,
      size: 24,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: errorColor),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: borderColor),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: primaryColor.withValues(alpha: 0.1),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: borderColor),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: borderLight,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      surface: Color(0xFF1e293b),
      error: errorColor,
    ),
    scaffoldBackgroundColor: const Color(0xFF0f172a),
  );

  // ==================== RESPONSIVE TEXT STYLES ====================
  
  /// Display/Hero text style - responsive
  static TextStyle displayStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontDisplay(context),
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -1,
    );
  }
  
  /// Title text style - responsive
  static TextStyle titleStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontTitle(context),
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -0.5,
    );
  }
  
  /// Heading text style - responsive
  static TextStyle headingStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontHeading(context),
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );
  }
  
  /// Subheading text style - responsive
  static TextStyle subheadingStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontXL(context),
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );
  }
  
  /// Large body text style - responsive
  static TextStyle bodyLargeStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontLG(context),
      fontWeight: FontWeight.w500,
      color: textPrimary,
    );
  }
  
  /// Regular body text style - responsive
  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontBody(context),
      fontWeight: FontWeight.w400,
      color: textPrimary,
    );
  }
  
  /// Small body text style - responsive
  static TextStyle bodySmallStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontSM(context),
      fontWeight: FontWeight.w400,
      color: textSecondary,
    );
  }
  
  /// Caption text style - responsive
  static TextStyle captionStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontXS(context),
      fontWeight: FontWeight.w500,
      color: textMuted,
    );
  }
  
  /// Label text style (for form fields) - responsive
  static TextStyle labelStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontSM(context),
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );
  }
  
  /// Button text style - responsive
  static TextStyle buttonStyle(BuildContext context) {
    return TextStyle(
      fontSize: Responsive.fontMD(context),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
  }
}
