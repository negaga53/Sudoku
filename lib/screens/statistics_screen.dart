import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/models/settings.dart';
import 'package:sudoku_app/providers/statistics_provider.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/widgets/animated_background.dart';

/// Displays cumulative game statistics grouped by overall and per-difficulty
/// sections.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.statistics,
          style: AppTextStyles.heading3.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Reset statistics',
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // ---- Overall stats ----
              _SectionHeader(title: l10n.overall, isDark: isDark),
              const SizedBox(height: 10),
              _buildOverallRow(stats, isDark, accent, l10n),
              const SizedBox(height: 24),

              // ---- Win rate ring ----
              _WinRateIndicator(
                winRate: stats.winRate,
                isDark: isDark,
                accent: accent,
              ),
              const SizedBox(height: 28),

              // ---- Per-difficulty stats ----
              _SectionHeader(title: l10n.byDifficulty, isDark: isDark),
              const SizedBox(height: 10),
              ...Difficulty.values.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DifficultyStatCard(
                      difficulty: d,
                      stats: stats,
                      isDark: isDark,
                    ),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Overall grid ---
  Widget _buildOverallRow(GameStatistics stats, bool isDark, Color accent, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: stats.gamesPlayed.toString(),
            label: l10n.played,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '${(stats.winRate * 100).toStringAsFixed(0)}%',
            label: l10n.winRate,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: stats.currentStreak.toString(),
            label: l10n.streak,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: stats.bestStreak.toString(),
            label: l10n.bestStreak,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // --- Reset confirmation ---
  void _confirmReset(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetStatistics),
        content: Text(l10n.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(statisticsProvider.notifier).resetStatistics();
              Navigator.pop(ctx);
            },
            child: Text(l10n.reset, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single stat tile (glassmorphism)
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _StatTile({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: surface.withOpacity(isDark ? 0.45 : 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.18),
            ),
          ),
          child: Column(
            children: [
              Text(value, style: AppTextStyles.statValue.copyWith(color: textColor)),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.statLabel.copyWith(color: secondaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Win rate circular indicator
// ---------------------------------------------------------------------------

class _WinRateIndicator extends StatelessWidget {
  final double winRate;
  final bool isDark;
  final Color accent;

  const _WinRateIndicator({
    required this.winRate,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface.withOpacity(isDark ? 0.4 : 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.06 : 0.18),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: winRate,
                          strokeWidth: 8,
                          backgroundColor: isDark
                              ? AppColors.darkGridLine
                              : AppColors.lightGridLine.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation(accent),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${(winRate * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.heading2.copyWith(color: textColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context).winRate,
                  style: AppTextStyles.statLabel.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-difficulty stat card
// ---------------------------------------------------------------------------

class _DifficultyStatCard extends StatelessWidget {
  final Difficulty difficulty;
  final GameStatistics stats;
  final bool isDark;

  const _DifficultyStatCard({
    required this.difficulty,
    required this.stats,
    required this.isDark,
  });

  String _formatTime(int seconds) {
    if (seconds <= 0) return '--:--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static const _difficultyColors = {
    Difficulty.easy: Color(0xFF4CAF50),
    Difficulty.medium: Color(0xFFFFC107),
    Difficulty.hard: Color(0xFFFF9800),
    Difficulty.expert: Color(0xFFF44336),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final diffColor = _difficultyColors[difficulty] ?? Colors.grey;

    final key = difficulty.name;
    final bestTime = stats.bestTimeForDifficulty(key);
    final avgTime = stats.averageTimeForDifficulty(key);
    final wins = stats.winsPerDifficulty[key] ?? 0;
    final played = stats.gamesPerDifficulty[key] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface.withOpacity(isDark ? 0.4 : 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: diffColor.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: diffColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.difficultyName(difficulty.name),
                    style: AppTextStyles.button.copyWith(color: textColor),
                  ),
                  const Spacer(),
                  Text(
                    '$wins / $played ${l10n.wonGames}',
                    style: AppTextStyles.caption.copyWith(color: secondaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    label: l10n.bestLabel,
                    value: _formatTime(bestTime ?? 0),
                    isDark: isDark,
                  ),
                  _MiniStat(
                    label: l10n.average,
                    value: _formatTime(avgTime),
                    isDark: isDark,
                  ),
                  _MiniStat(
                    label: l10n.won,
                    value: wins.toString(),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        Text(value, style: AppTextStyles.score.copyWith(color: textColor)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(color: secondaryColor)),
      ],
    );
  }
}
