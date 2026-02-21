import 'package:flutter/material.dart';

class AppColors {
  // Accent color options (user can choose)
  static const List<Color> accentColors = [
    Color(0xFF6C63FF), // Purple (default)
    Color(0xFF00BFA6), // Teal
    Color(0xFFFF6B6B), // Coral
    Color(0xFF4ECDC4), // Mint
    Color(0xFFFFE66D), // Yellow
    Color(0xFFFF8A65), // Orange
  ];

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGridLine = Color(0xFFBDBDBD);
  static const Color lightBoxLine = Color(0xFF424242);
  static const Color lightCellDefault = Color(0xFFFFFFFF);
  static const Color lightCellSelected = Color(0xFFE8EAF6);
  static const Color lightCellHighlighted = Color(0xFFF3E5F5);
  static const Color lightCellSameValue = Color(0xFFD1C4E9);
  static const Color lightCellError = Color(0xFFFFCDD2);
  static const Color lightCellGiven = Color(0xFFF5F5F5);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightTextGiven = Color(0xFF1A1A2E);
  static const Color lightTextFilled = Color(0xFF6C63FF);
  static const Color lightTextError = Color(0xFFD32F2F);
  static const Color lightTextNotes = Color(0xFF9E9E9E);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0A0E21);
  static const Color darkSurface = Color(0xFF1A1F36);
  static const Color darkGridLine = Color(0xFF2E3452);
  static const Color darkBoxLine = Color(0xFF8A8FB5);
  static const Color darkCellDefault = Color(0xFF1A1F36);
  static const Color darkCellSelected = Color(0xFF2A2F56);
  static const Color darkCellHighlighted = Color(0xFF1E2344);
  static const Color darkCellSameValue = Color(0xFF2C2466);
  static const Color darkCellError = Color(0xFF3D1A1A);
  static const Color darkCellGiven = Color(0xFF1E2240);
  static const Color darkTextPrimary = Color(0xFFEEEEEE);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextGiven = Color(0xFFE0E0E0);
  static const Color darkTextFilled = Color(0xFF9C8FFF);
  static const Color darkTextError = Color(0xFFFF5252);
  static const Color darkTextNotes = Color(0xFF666688);

  // Gradient colors for backgrounds
  static const List<Color> lightGradient = [
    Color(0xFFE8EAF6),
    Color(0xFFF3E5F5),
    Color(0xFFE1F5FE),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0A0E21),
    Color(0xFF1A1040),
    Color(0xFF0D1B2A),
  ];

  // Success/Win colors
  static const Color success = Color(0xFF4CAF50);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
}
