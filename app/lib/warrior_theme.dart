import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warrior Forge Theme - Brutalist Spartan Aesthetic
/// Colors: Obsidian black, Spartan bronze, Blood crimson, Iron gray
class WarriorTheme {
  WarriorTheme._();

  // === CORE PALETTE ===
  static const Color obsidian = Color(0xFF0A0A0A);
  static const Color obsidianLight = Color(0xFF141414);
  static const Color obsidianElevated = Color(0xFF1A1A1A);

  static const Color bronze = Color(0xFFB87333);
  static const Color bronzeDark = Color(0xFF8B5A2B);
  static const Color bronzeLight = Color(0xFFD4A76A);
  static const Color bronzeMuted = Color(0xFF6B4423);

  static const Color crimson = Color(0xFF8B0000);
  static const Color crimsonDark = Color(0xFF5C0000);
  static const Color crimsonLight = Color(0xFFB22222);

  static const Color iron = Color(0xFF4A4A4A);
  static const Color ironLight = Color(0xFF6B6B6B);
  static const Color ironDark = Color(0xFF2A2A2A);

  static const Color ash = Color(0xFFB0B0B0);
  static const Color ashLight = Color(0xFFD0D0D0);
  static const Color ashDark = Color(0xFF808080);

  static const Color gold = Color(0xFFD4AF37);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color copper = Color(0xFFB87333);

  // === SEMANTIC COLORS ===
  static const Color background = obsidian;
  static const Color surface = obsidianLight;
  static const Color surfaceElevated = obsidianElevated;

  static const Color primary = bronze;
  static const Color onPrimary = Color(0xFF0A0A0A);
  static const Color primaryContainer = bronzeMuted;
  static const Color onPrimaryContainer = bronzeLight;

  static const Color secondary = iron;
  static const Color onSecondary = ashLight;
  static const Color secondaryContainer = ironDark;
  static const Color onSecondaryContainer = ash;

  static const Color accent = crimson;
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentContainer = crimsonDark;
  static const Color onAccentContainer = Color(0xFFFF6B6B);

  static const Color error = crimson;
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = crimsonDark;
  static const Color onErrorContainer = Color(0xFFFF6B6B);

  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color warning = bronze;
  static const Color onWarning = Color(0xFF0A0A0A);

  static const Color onSurface = ashLight;
  static const Color onSurfaceVariant = ash;
  static const Color outline = iron;
  static const Color outlineVariant = ironDark;

  // === FIRE/STREAK COLORS ===
  static const Color fireCore = Color(0xFFFF4500);
  static const Color fireOuter = Color(0xFFFF8C00);
  static const Color fireEmber = Color(0xFFFF6347);
  static const Color streakFlame = Color(0xFFFF6B35);

  // === TYPOGRAPHY ===
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
    color: onSurface,
  );

  static TextStyle get displayMedium => GoogleFonts.spaceGrotesk(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: onSurface,
  );

  static TextStyle get displaySmall => GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    color: onSurface,
  );

  static TextStyle get headlineLarge => GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: onSurface,
  );

  static TextStyle get headlineMedium => GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: onSurface,
  );

  static TextStyle get headlineSmall => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: onSurface,
  );

  static TextStyle get titleLarge => GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: onSurface,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.25,
    color: onSurface,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: onSurface,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: onSurface,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: onSurface,
    height: 1.4,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: onSurfaceVariant,
    height: 1.3,
  );

  static TextStyle get labelLarge => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: onSurface,
  );

  static TextStyle get labelMedium => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: onSurface,
  );

  static TextStyle get labelSmall => GoogleFonts.spaceGrotesk(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: onSurfaceVariant,
  );

  // Special styles for warrior theme
  static TextStyle get oathText => GoogleFonts.cormorantGaramond(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.5,
    color: bronzeLight,
    height: 1.6,
  );

  static TextStyle get rankTitle => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 3,
    color: bronze,
  );

  static TextStyle get battleCry => GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 4,
    color: crimson,
  );

  // === SHAPE THEME ===
  static const double cornerSharp = 0;
  static const double cornerSubtle = 2;
  static const double cornerMinimal = 4;

  static RoundedRectangleBorder get shapeSharp =>
      const RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  static RoundedRectangleBorder get shapeSubtle => const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(cornerSubtle)),
  );

  static RoundedRectangleBorder get shapeMinimal =>
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(cornerMinimal)),
      );

  // === SHADOWS ===
  static List<BoxShadow> get shadowBronze => [
    BoxShadow(
      color: bronze.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowCrimson => [
    BoxShadow(
      color: crimson.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowDeep => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  // === GRADIENTS ===
  static LinearGradient get gradientBronze => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bronzeLight, bronze, bronzeDark],
  );

  static LinearGradient get gradientCrimson => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [crimsonLight, crimson, crimsonDark],
  );

  static LinearGradient get gradientDark => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [obsidianLight, obsidian, obsidian],
  );

  static LinearGradient get gradientFire => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [fireCore, fireOuter, Colors.transparent],
  );

  // === SPACING ===
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // === ANIMATION DURATIONS ===
  static const Duration durationQuick = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationDeliberate = Duration(milliseconds: 500);
  static const Duration durationCinematic = Duration(milliseconds: 800);

  // === EASING ===
  static const Curve easeWarrior = Cubic(0.4, 0.0, 0.2, 1);
  static const Curve easeImpact = Cubic(0.0, 0.0, 0.2, 1);
  static const Curve easeSword = Cubic(0.4, 0.0, 1, 1);

  // === THEME DATA ===
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      surface: surface,
      surfaceContainerHighest: surfaceElevated,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Colors.black,
    ),
    textTheme: TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineMedium,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: shapeSharp,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: shapeSharp,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: const BorderSide(color: outline, width: 1),
        shape: shapeSharp,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: shapeSharp,
        textStyle: labelMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: bodyMedium.copyWith(color: onSurfaceVariant),
    ),
    dividerTheme: const DividerThemeData(
      color: outline,
      thickness: 1,
      space: 32,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: bodyMedium,
      shape: shapeSharp,
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: shapeSharp,
      elevation: 0,
    ),
  );
}
