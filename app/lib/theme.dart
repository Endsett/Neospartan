import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Digital Agoge Design System
/// Blood & Bronze color palette with zero-radius brutalist aesthetics
class LaconicTheme {
  LaconicTheme._();

  // ============ BLOOD & BRONZE PALETTE ============

  // Surface Hierarchy (Dark to Light)
  static const Color surface = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0e0e0e);
  static const Color surfaceContainerLow = Color(0xFF1b1b1b);
  static const Color surfaceContainer = Color(0xFF1f1f1f);
  static const Color surfaceContainerHigh = Color(0xFF2a2a2a);
  static const Color surfaceContainerHighest = Color(0xFF353535);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceVariant = Color(0xFF353535);
  static const Color surfaceDim = Color(0xFF131313);

  // Primary - Blood (Actions, Path of Action)
  static const Color primary = Color(0xFFffb4ac);
  static const Color onPrimary = Color(0xFF690006);
  static const Color primaryContainer = Color(0xFF9e1b1b);
  static const Color onPrimaryContainer = Color(0xFFffafa7);
  static const Color primaryFixed = Color(0xFFffdad6);
  static const Color primaryFixedDim = Color(0xFFffb4ac);
  static const Color onPrimaryFixed = Color(0xFF410002);
  static const Color onPrimaryFixedVariant = Color(0xFF8f0e12);
  static const Color inversePrimary = Color(0xFFb22a27);

  // Secondary - Bronze (Optimal State)
  static const Color secondary = Color(0xFFffb779);
  static const Color onSecondary = Color(0xFF4c2700);
  static const Color secondaryContainer = Color(0xFF955200);
  static const Color onSecondaryContainer = Color(0xFFffd9bc);
  static const Color secondaryFixed = Color(0xFFffdcc1);
  static const Color secondaryFixedDim = Color(0xFFffb779);
  static const Color onSecondaryFixed = Color(0xFF2e1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6c3a00);

  // Tertiary - Warm Accent
  static const Color tertiary = Color(0xFFffb4aa);
  static const Color onTertiary = Color(0xFF5f1410);
  static const Color tertiaryContainer = Color(0xFF8b342c);
  static const Color onTertiaryContainer = Color(0xFFffafa5);
  static const Color tertiaryFixed = Color(0xFFffdad5);
  static const Color tertiaryFixedDim = Color(0xFFffb4aa);
  static const Color onTertiaryFixed = Color(0xFF410001);
  static const Color onTertiaryFixedVariant = Color(0xFF7e2b23);

  // Background & Surface
  static const Color background = Color(0xFF131313);
  static const Color onBackground = Color(0xFFe2e2e2);
  static const Color onSurface = Color(0xFFe2e2e2);
  static const Color onSurfaceVariant = Color(0xFFe1bebb);
  static const Color inverseSurface = Color(0xFFe2e2e2);
  static const Color inverseOnSurface = Color(0xFF303030);
  static const Color surfaceTint = Color(0xFFffb4ac);

  // Outlines (Ghost Borders)
  static const Color outline = Color(0xFFa98986);
  static const Color outlineVariant = Color(0xFF59413e);

  // Error
  static const Color error = Color(0xFFffb4ab);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000a);
  static const Color onErrorContainer = Color(0xFFffdad6);

  // Legacy aliases for backward compatibility
  static const Color deepBlack = surfaceContainerLowest;
  static const Color surfaceBlack = surface;
  static const Color surfaceElevated = surfaceContainerHigh;
  static const Color surfaceOverlay = surfaceContainerHighest;
  static const Color spartanBronze = secondary;
  static const Color warmGold = secondary;
  static const Color brightGold = secondary;
  static const Color darkGold = secondaryContainer;
  static const Color emberRed = primary;
  static const Color ironGray = surfaceContainerHigh;
  static const Color steelGray = outline;
  static const Color mistGray = outlineVariant;
  static const Color boneWhite = onSurface;
  static const Color pureWhite = onSurface;
  static const Color iceBlue = tertiary;
  static const Color mossGreen = secondary;

  // ============ TYPOGRAPHY ============
  static TextTheme _buildTextTheme(TextTheme base) {
    final headlineFont = GoogleFonts.spaceGrotesk();
    final bodyFont = GoogleFonts.inter();
    final labelFont = GoogleFonts.workSans();

    return base.copyWith(
      // Display - Aggressive, wide, modern (Space Grotesk)
      displayLarge: headlineFont.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w900,
        color: onSurface,
        letterSpacing: -0.02,
        height: 1.0,
      ),
      displayMedium: headlineFont.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.02,
        height: 1.0,
      ),
      displaySmall: headlineFont.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.02,
        height: 1.0,
      ),

      // Headlines - Space Grotesk
      headlineLarge: headlineFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.02,
        height: 1.2,
      ),
      headlineMedium: headlineFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.02,
        height: 1.2,
      ),
      headlineSmall: headlineFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.02,
        height: 1.2,
      ),

      // Titles - Space Grotesk
      titleLarge: headlineFont.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.01,
      ),
      titleMedium: headlineFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.01,
      ),
      titleSmall: headlineFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
        letterSpacing: -0.01,
      ),

      // Body - Inter (Scientific, neutral, precise)
      bodyLarge: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
        height: 1.6,
        letterSpacing: 0,
      ),
      bodyMedium: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodySmall: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: outline,
        height: 1.4,
        letterSpacing: 0,
      ),

      // Labels - Work Sans (Analytical, uppercase, +5% letter-spacing)
      labelLarge: labelFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: 0.05,
      ),
      labelMedium: labelFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: onSurfaceVariant,
        letterSpacing: 0.05,
      ),
      labelSmall: labelFont.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: outline,
        letterSpacing: 0.1,
      ),
    );
  }

  // ============ COMPONENT DECORATIONS ============

  /// Zero-radius card decoration with tonal layering
  static BoxDecoration agogeCard({
    Color? color,
    bool elevated = false,
    bool hasBorder = false,
    Color? borderColor,
  }) => BoxDecoration(
    color: color ?? surfaceContainer,
    borderRadius: BorderRadius.zero,
    border: hasBorder || borderColor != null
        ? Border.all(
            color: borderColor ?? outlineVariant.withValues(alpha: 0.15),
            width: 1,
          )
        : null,
    boxShadow: elevated
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ]
        : null,
  );

  /// Surface container hierarchy levels
  static BoxDecoration surfaceLowest() => BoxDecoration(
    color: surfaceContainerLowest,
    borderRadius: BorderRadius.zero,
  );

  static BoxDecoration surfaceLow() => BoxDecoration(
    color: surfaceContainerLow,
    borderRadius: BorderRadius.zero,
  );

  static BoxDecoration surfaceContainerDeco() =>
      BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.zero);

  static BoxDecoration surfaceHigh() => BoxDecoration(
    color: surfaceContainerHigh,
    borderRadius: BorderRadius.zero,
  );

  static BoxDecoration surfaceHighest() => BoxDecoration(
    color: surfaceContainerHighest,
    borderRadius: BorderRadius.zero,
  );

  /// Ghost border decoration
  static BoxDecoration ghostBorder({Color? color}) => BoxDecoration(
    border: Border.all(
      color: (color ?? outlineVariant).withValues(alpha: 0.15),
      width: 1,
    ),
    borderRadius: BorderRadius.zero,
  );

  /// Smoldering gradient for CTAs
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryContainer],
  );

  /// Secondary gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [secondary, secondaryContainer],
  );

  // ============ SPACING SYSTEM ============
  static const double spaceXxs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;
  static const double space3xl = 64;

  // ============ THEME DATA ============
  static ThemeData get theme {
    final base = ThemeData.dark();

    return ThemeData.dark().copyWith(
      // Material 3 is default in newer Flutter versions
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
        surfaceTint: surfaceTint,
        brightness: Brightness.dark,
      ),
      textTheme: _buildTextTheme(base.textTheme),

      appBarTheme: AppBarTheme(
        backgroundColor: background.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: surfaceContainerLowest,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: primary,
          letterSpacing: -0.02,
        ),
        iconTheme: const IconThemeData(color: primary),
        actionsIconTheme: const IconThemeData(color: primary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: secondary,
        unselectedItemColor: surfaceBright,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05,
        ),
      ),

      cardTheme: const CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outlineVariant, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: outlineVariant, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: outlineVariant, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: secondary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 14),
        hintStyle: const TextStyle(color: outline, fontSize: 14),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: secondary,
        inactiveTrackColor: surfaceContainerHighest,
        thumbColor: secondary,
        overlayColor: secondary.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: secondary,
        labelStyle: const TextStyle(
          color: onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: onSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: outlineVariant),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: surfaceContainerHigh,
        thickness: 1,
        space: 24,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceContainerHigh,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
        contentTextStyle: GoogleFonts.inter(color: onSurface, fontSize: 14),
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
