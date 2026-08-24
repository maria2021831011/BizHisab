import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFF4DA3FF);

  // Secondary
  static const Color secondary = Color(0xFF00C853);
  static const Color secondaryDark = Color(0xFF009624);

  // Income
  static const Color income = Color(0xFF00C853);
  static const Color incomeLight = Color(0xFFE8F5E9);

  // Expense
  static const Color expense = Color(0xFFE53935);
  static const Color expenseLight = Color(0xFFFFEBEE);

  // Supplier (amber/orange brand used for supplier-related chrome —
  // mirrors the existing `due` orange but distinct enough to mean
  // "this is about suppliers" rather than "this is a due amount").
  static const Color supplier = Color(0xFFFF6F00);
  static const Color supplierLight = Color(0xFFFFF1E0);

  // Profit
  static const Color profit = Color(0xFF1A73E8);
  static const Color profitLight = Color(0xFFE3F2FD);

  // Due
  static const Color due = Color(0xFFFF9800);
  static const Color dueLight = Color(0xFFFFF3E0);

  // Neutral
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkDivider = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF4DA3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft gradient used by the AI Insight card so it visually stands out
  /// from the regular metric cards.
  static const LinearGradient aiInsightGradient = LinearGradient(
    colors: [Color(0xFFF1F5FF), Color(0xFFE7ECFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
