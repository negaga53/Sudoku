import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  /// Returns a fully configured [ThemeData] based on the brightness and accent color.
  ///
  /// [isDark] – whether to use dark mode colors.
  /// [accentColorIndex] – index into [AppColors.accentColors] (clamped to valid range).
  static ThemeData getTheme(bool isDark, int accentColorIndex) {
    final accent = AppColors.accentColors[
        accentColorIndex.clamp(0, AppColors.accentColors.length - 1)];

    if (isDark) {
      return _buildTheme(
        brightness: Brightness.dark,
        accent: accent,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        error: AppColors.darkTextError,
      );
    } else {
      return _buildTheme(
        brightness: Brightness.light,
        accent: accent,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        error: AppColors.lightTextError,
      );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color accent,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color error,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: accent.withAlpha(204), // 0.8 opacity
      onSecondary: isDark ? Colors.black : Colors.white,
      surface: surface,
      onSurface: textPrimary,
      error: error,
      onError: Colors.white,
    );

    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: textPrimary),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: textPrimary),
      displaySmall: baseTextTheme.displaySmall?.copyWith(color: textPrimary),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: textPrimary),
      headlineMedium:
          baseTextTheme.headlineMedium?.copyWith(color: textPrimary),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: textPrimary),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: textPrimary),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: textPrimary),
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: textPrimary),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: textSecondary),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: textPrimary),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: textSecondary),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 2 : 1,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon
      iconTheme: IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // Bottom Navigation / Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withAlpha(51), // 0.2 opacity
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent);
          }
          return IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkGridLine : AppColors.lightGridLine,
        thickness: 1,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withAlpha(102); // 0.4 opacity
          }
          return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
        }),
      ),
    );
  }
}
