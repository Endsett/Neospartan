import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LaconicTheme {
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color spartanBronze = Color(0xFFCD7F32);
  static const Color ironGray = Color(0xFF333333);
  static const Color boneWhite = Color(0xFFE5E5E5);

  static ThemeData get theme {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: spartanBronze,
      colorScheme: ColorScheme.dark(
        primary: spartanBronze,
        secondary: ironGray,
        surface: Colors.black,
        onPrimary: Colors.white,
        onSurface: boneWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: spartanBronze,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: deepBlack,
        elevation: 20,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(
          color: spartanBronze,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        bodyLarge: const TextStyle(
          color: boneWhite,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: spartanBronze,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const BeveledRectangleBorder(),
        ),
      ),
    );
  }
}
