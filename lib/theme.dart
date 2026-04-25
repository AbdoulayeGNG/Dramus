import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// ============================================================================
// DRAMUS COLOR PALETTE
// ============================================================================

class DramusColors {
  // Core Brand Colors
  static const Color darkPetroleum = Color(0xFF1E2330);
  static const Color primaryTeal = Color(0xFF00C2A8);
  static const Color deepTeal = Color(0xFF0D4C60);
  static const Color saleGreen = Color(0xFF23D0B0);
  static const Color premiumYellow = Color(0xFFF2B449);
  static const Color rentYellow = Color(0xFFF3C27B);
  static const Color notificationRed = Color(0xFFE85E5B);
  static const Color notificationGreen = Color(0xFF4CAF50);

  // Neutral Colors
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF6C737F);
  static const Color border = Color(0xFFE0E3E8);
  static const Color lightGray = Color(0xFFF2F4F7);
  static const Color mediumGray = Color(0xFFD1D5DC);
  static const Color white = Color(0xFFFFFFFF);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// ============================================================================
// THEMES
// ============================================================================

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: DramusColors.primaryTeal,
        onPrimary: DramusColors.white,
        primaryContainer: DramusColors.saleGreen,
        onPrimaryContainer: DramusColors.darkPetroleum,
        secondary: DramusColors.deepTeal,
        onSecondary: DramusColors.white,
        tertiary: DramusColors.premiumYellow,
        onTertiary: DramusColors.darkText,
        error: DramusColors.notificationRed,
        onError: DramusColors.white,
        errorContainer: Color(0xFFFEDEDB),
        onErrorContainer: DramusColors.notificationRed,
        surface: DramusColors.white,
        onSurface: DramusColors.darkText,
        surfaceContainerHighest: DramusColors.lightBackground,
        onSurfaceVariant: DramusColors.secondaryText,
        outline: DramusColors.border,
        shadow: Color(0x1A000000),
        inversePrimary: DramusColors.premiumYellow,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: DramusColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: DramusColors.darkPetroleum,
        foregroundColor: DramusColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: DramusColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: DramusColors.border, width: 1),
        ),
      ),
      textTheme: _buildTextTheme(),
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: DramusColors.primaryTeal,
        onPrimary: DramusColors.darkPetroleum,
        primaryContainer: DramusColors.deepTeal,
        onPrimaryContainer: DramusColors.primaryTeal,
        secondary: DramusColors.saleGreen,
        onSecondary: DramusColors.darkPetroleum,
        tertiary: DramusColors.premiumYellow,
        onTertiary: DramusColors.darkText,
        error: DramusColors.notificationRed,
        onError: DramusColors.darkText,
        errorContainer: Color(0xFF5B2C2A),
        onErrorContainer: Color(0xFFFEDEDB),
        surface: Color(0xFF1A1A1A),
        onSurface: Color(0xFFE8E8E8),
        surfaceContainerHighest: Color(0xFF2A2A2A),
        onSurfaceVariant: Color(0xFFB0B0B0),
        outline: Color(0xFF606060),
        shadow: Color(0xFF000000),
        inversePrimary: DramusColors.premiumYellow,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: DramusColors.darkPetroleum,
        foregroundColor: DramusColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
      ),
      textTheme: _buildTextTheme(),
    );

TextTheme _buildTextTheme() {
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w600,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
  );
}
