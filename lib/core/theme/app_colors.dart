import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C5CE7); // violet from the mockup buttons
  static const primaryLight = Color(0xFF8E7CF0);
  static const accentPink = Color(0xFFF178B6); // gradient card pink
  static const accentOrange = Color(0xFFFFA45C); // gradient card orange

  static const background = Color(0xFFF7F7FB);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF1B1B23);
  static const textSecondary = Color(0xFF7A7A8C);

  static const success = Color(0xFF2ECC71); // "Accepted" pill
  static const warning = Color(0xFFF5A623); // "Shortlisted"/"Under Review" pill
  static const info = Color(0xFF6C5CE7); // "Applied" pill
  static const neutral = Color(0xFFB2B2C2); // "Closed" pill

  static const chipBackground = Color(0xFFF1F0FA);

  static const recommendedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accentPink, accentOrange],
  );
}
