// lib/utils/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1A6B3A);       // Deep forest green
  static const Color primaryLight = Color(0xFF2D9B55);
  static const Color primaryDark = Color(0xFF0F4023);
  static const Color accent = Color(0xFFE8A020);         // Coffee gold
  static const Color accentLight = Color(0xFFF5C460);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F0);
  static const Color cardBg = Color(0xFFFFFFFF);

  // DNA Verified = Blue, Non-Verified = Green
  static const Color dnaVerifiedColor = Color(0xFF1565C0);
  static const Color nonVerifiedColor = Color(0xFF2E7D32);

  // Map Colors
  static const Color polygonFill = Color(0x331A6B3A);
  static const Color polygonBorder = Color(0xFF1A6B3A);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: cardBg,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: Color(0xFF999999),
          type: BottomNavigationBarType.fixed,
          elevation: 16,
        ),
      );
}

class AppConstants {
  // Center of Batangas province
  static const double batangasCenterLat = 13.8667;
  static const double batangasCenterLng = 121.1167;
  static const double defaultZoom = 10.5;
  static const double farmZoom = 15.0;
  static const double treeZoom = 17.0;

  // Google Maps API Key - Replace with your actual key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Admin credentials (mock - replace with real auth in production)
  static const String adminUsername = 'admin';
  static const String adminPassword = 'liberica2024';
}