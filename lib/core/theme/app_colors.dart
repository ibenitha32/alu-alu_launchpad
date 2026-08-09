import 'package:flutter/material.dart';

/// "Verification ledger" palette — deliberately not the sample mockup's
/// vibrant violet/pink/orange consumer-app gradient. Instead it's built
/// around a restrained deep-teal-and-paper system, with a single warm gold
/// accent held in reserve for verified-startup badges — so the palette
/// itself signals the platform's actual differentiator (the admin-enforced
/// verification gate) rather than being generic decoration.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0B5D52); // deep teal — primary actions, selected states
  static const primaryLight = Color(0xFF3F8A7E);
  static const ink = Color(0xFF17231F); // near-black ink, used for headings/text
  static const accentPink = Color(0xFFD98B6E); // clay accent — secondary emphasis (e.g. "Interview")
  static const accentOrange = Color(0xFFC9962F); // gold — reserved for verification/trust signals

  /// Alias kept for callers that specifically mean "the verified-startup
  /// badge color" rather than a generic accent — same value as accentOrange.
  static const verifiedGold = accentOrange;

  static const background = Color(0xFFF5F2EA); // warm paper, not stark white
  static const surface = Color(0xFFFFFDF8);

  static const textPrimary = ink;
  static const textSecondary = Color(0xFF5E6B67);

  static const success = Color(0xFF2F7D5A); // "Accepted" pill
  static const warning = Color(0xFFC08A2E); // "Shortlisted"/"Under Review" pill
  static const info = primary; // "Applied" pill
  static const neutral = Color(0xFFAFA99A); // "Closed" pill

  static const chipBackground = Color(0xFFEDE7D8);

  // Featured cards use a restrained two-tone ledger treatment (deep teal to
  // ink) instead of a three-color vivid gradient — closer to a stamped
  // document than a consumer social-feed card.
  static const recommendedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF102E29)],
  );
}
