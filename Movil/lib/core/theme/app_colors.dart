import 'package:flutter/material.dart';

/// Colores de la aplicación Spazio
/// Basados en el diseño web con primary #137fec
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF137FEC);
  static const Color primaryLight = Color(0xFF4DA3F7);
  static const Color primaryDark = Color(0xFF0D5AAB);
  
  // Background colors
  static const Color background = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF101922);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1A2332);
  static const Color dark = Color(0xFF101922);
  
  // Text colors
  static const Color textPrimary = Color(0xFF101922);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // Availability status
  static const Color available = Color(0xFF10B981);
  static const Color unavailable = Color(0xFFEF4444);
  static const Color pending = Color(0xFFF59E0B);
  
  // Glassmorphism colors
  static const Color glassWhite = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x40000000);
  static const Color glassBlue = Color(0x30137FEC);
  
  // Gradient colors
  static const Color gradientStart = Color(0xFF137FEC);
  static const Color gradientEnd = Color(0xFF6366F1); // Indigo
  
  // Border & divider
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  
  // Shadow
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  
  // Booking status colors
  static Color getBookingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return success;
      case 'pending':
        return pending;
      case 'cancelled':
        return error;
      case 'completed':
        return textSecondary;
      default:
        return textTertiary;
    }
  }
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF137FEC),
      Color(0xFF4F46E5),
    ],
  );
}
