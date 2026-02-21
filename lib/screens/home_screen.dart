import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/providers/game_provider.dart';
import 'package:sudoku_app/providers/statistics_provider.dart';
import 'package:sudoku_app/screens/difficulty_screen.dart';
import 'package:sudoku_app/screens/game_screen.dart';
import 'package:sudoku_app/screens/settings_screen.dart';
import 'package:sudoku_app/screens/statistics_screen.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/widgets/animated_background.dart';

/// The app's main menu / landing screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final stats = ref.watch(statisticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    final hasSavedGame = gameState.status == GameStatus.inProgress ||
        gameState.status == GameStatus.paused;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // ---- App title ----
                  _buildTitle(isDark, accent, l10n.appTitle),
                  const SizedBox(height: 48),

                  // ---- Menu buttons ----
                  _MenuButton(
                    icon: Icons.play_arrow_rounded,
                    label: l10n.newGame,
                    isDark: isDark,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DifficultyScreen(),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                  if (hasSavedGame) ...[
                    const SizedBox(height: 14),
                    _MenuButton(
                      icon: Icons.play_circle_outline_rounded,
                      label: l10n.continueGame,
                      isDark: isDark,
                      accent: accent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                  ],

                  const SizedBox(height: 14),
                  _MenuButton(
                    icon: Icons.bar_chart_rounded,
                    label: l10n.statistics,
                    isDark: isDark,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatisticsScreen(),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 14),
                  _MenuButton(
                    icon: Icons.settings_rounded,
                    label: l10n.settings,
                    isDark: isDark,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 40),

                  // ---- High score ----
                  if (stats.highScore > 0)
                    Text(
                      '${l10n.highScore}: ${stats.highScore}',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool isDark, Color accent, String title) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [accent, accent.withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTextStyles.heading1.copyWith(
          fontSize: 42,
          letterSpacing: 4,
          shadows: [
            Shadow(
              color: accent.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .scaleXY(begin: 0.85, end: 1.0, curve: Curves.easeOutBack);
  }
}

// ---------------------------------------------------------------------------
// Menu button — glassmorphism card style
// ---------------------------------------------------------------------------

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: surface.withOpacity(isDark ? 0.45 : 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.06 : 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTextStyles.button.copyWith(color: textColor),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textColor.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
