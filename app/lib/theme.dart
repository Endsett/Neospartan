import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LaconicTheme {
  LaconicTheme._();

  // ============ CORE COLORS ============
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color surfaceBlack = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceOverlay = Color(0xFF2A2A2A);

  // Bronze/Gold Evolution
  static const Color spartanBronze = Color(0xFFCD7F32);
  static const Color warmGold = Color(0xFFD4A84B);
  static const Color brightGold = Color(0xFFE8C547);
  static const Color darkGold = Color(0xFF8B6914);

  // Accent Colors
  static const Color emberRed = Color(0xFFFF4500);
  static const Color iceBlue = Color(0xFF4FC3F7);
  static const Color mossGreen = Color(0xFF7CB342);

  // Neutrals
  static const Color ironGray = Color(0xFF333333);
  static const Color steelGray = Color(0xFF555555);
  static const Color mistGray = Color(0xFF888888);
  static const Color boneWhite = Color(0xFFE5E5E5);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ============ GRADIENTS ============
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [spartanBronze, warmGold, brightGold],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [darkGold, spartanBronze, warmGold],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceBlack, deepBlack],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E), Color(0xFF141414)],
    stops: [0.0, 0.5, 1.0],
  );

  // ============ GLASSMORPHISM ============
  static BoxDecoration glassCard({double radius = 16}) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF2A2A2A).withOpacity(0.8),
        const Color(0xFF1A1A1A).withOpacity(0.6),
      ],
    ),
    border: Border.all(
      color: const Color(0xFF3A3A3A).withOpacity(0.5),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: spartanBronze.withOpacity(0.05),
        blurRadius: 40,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration glassCardElevated({double radius = 20}) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF323232).withOpacity(0.9),
        const Color(0xFF202020).withOpacity(0.7),
      ],
    ),
    border: Border.all(color: warmGold.withOpacity(0.2), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 30,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: spartanBronze.withOpacity(0.1),
        blurRadius: 60,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration glassButton({bool isActive = true}) => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: isActive
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [spartanBronze, warmGold],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF3A3A3A), const Color(0xFF2A2A2A)],
          ),
    boxShadow: isActive
        ? [
            BoxShadow(
              color: spartanBronze.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ]
        : null,
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

  // ============ TYPOGRAPHY ============
  static TextTheme _buildTextTheme(TextTheme base) {
    final displayFont = GoogleFonts.oswald();
    final bodyFont = GoogleFonts.inter();

    return base.copyWith(
      displayLarge: displayFont.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: brightGold,
        letterSpacing: 2,
        height: 1.1,
      ),
      displayMedium: displayFont.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: warmGold,
        letterSpacing: 1.5,
        height: 1.2,
      ),
      displaySmall: displayFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: spartanBronze,
        letterSpacing: 1,
        height: 1.3,
      ),
      headlineLarge: bodyFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: boneWhite,
        letterSpacing: 0.5,
      ),
      headlineMedium: bodyFont.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: boneWhite,
      ),
      headlineSmall: bodyFont.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: mistGray,
      ),
      titleLarge: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: boneWhite,
      ),
      titleMedium: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: boneWhite,
      ),
      titleSmall: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mistGray,
        letterSpacing: 0.5,
      ),
      bodyLarge: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: boneWhite,
        height: 1.6,
      ),
      bodyMedium: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mistGray,
        height: 1.5,
      ),
      bodySmall: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: steelGray,
        height: 1.4,
      ),
      labelLarge: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: boneWhite,
        letterSpacing: 1,
      ),
      labelMedium: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: mistGray,
        letterSpacing: 0.5,
      ),
      labelSmall: bodyFont.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: steelGray,
        letterSpacing: 1,
      ),
    );
  }

  // ============ THEME DATA ============
  static ThemeData get theme {
    final base = ThemeData.dark();

    return ThemeData.dark().copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: spartanBronze,
      colorScheme: const ColorScheme.dark(
        primary: spartanBronze,
        secondary: warmGold,
        surface: surfaceBlack,
        surfaceContainerHighest: surfaceElevated,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: boneWhite,
        error: emberRed,
        onError: pureWhite,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: deepBlack,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: brightGold,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: boneWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceBlack,
        selectedItemColor: warmGold,
        unselectedItemColor: mistGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceBlack.withOpacity(0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ironGray.withOpacity(0.3), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: spartanBronze,
          foregroundColor: deepBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: boneWhite,
          side: const BorderSide(color: ironGray, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: warmGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceOverlay.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ironGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ironGray.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: warmGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emberRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: mistGray, fontSize: 14),
        hintStyle: const TextStyle(color: steelGray, fontSize: 14),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: spartanBronze,
        inactiveTrackColor: ironGray.withOpacity(0.3),
        thumbColor: brightGold,
        overlayColor: spartanBronze.withOpacity(0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceOverlay,
        selectedColor: spartanBronze.withOpacity(0.2),
        labelStyle: const TextStyle(color: boneWhite, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: warmGold, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: ironGray.withOpacity(0.3)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ironGray.withOpacity(0.3),
        thickness: 1,
        space: 24,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: warmGold.withOpacity(0.2)),
        ),
      ),
    );
  }
}
