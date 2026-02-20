import 'package:flutter/material.dart';

/// Palet warna premium untuk SIA Indekos Mobile.
/// Menggunakan skema warna indigo-teal yang profesional dan modern.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ── Primary (Indigo Gelap) ──────────────────────────────────
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF0D1642);

  // ── Secondary (Teal) ───────────────────────────────────────
  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4DB6AC);
  static const Color secondaryDark = Color(0xFF00695C);

  // ── Accent ─────────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6F00); // Amber gelap

  // ── Background ─────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color surfaceDark = Color(0xFF121212);

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Colors.white;
  static const Color textHint = Color(0xFF9CA3AF);

  // ── Status Pembayaran ──────────────────────────────────────
  static const Color statusLunas = Color(0xFF10B981);     // Hijau
  static const Color statusMenunggak = Color(0xFFEF4444); // Merah
  static const Color statusPending = Color(0xFFF59E0B);   // Kuning
  static const Color statusInfo = Color(0xFF3B82F6);      // Biru

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D1642),
      Color(0xFF1A237E),
      Color(0xFF283593),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEEF2FF),
      Color(0xFFF0F9FF),
    ],
  );

  // ── Divider & Border ───────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // ── Shadow ─────────────────────────────────────────────────
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
}
