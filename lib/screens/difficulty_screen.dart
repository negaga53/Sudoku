import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/providers/game_provider.dart';
import 'package:sudoku_app/providers/statistics_provider.dart';
import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/screens/game_screen.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/widgets/animated_background.dart';

/// Lets the user pick a difficulty before starting a new game.
class DifficultyScreen extends ConsumerWidget {
  const DifficultyScreen({super.key});

  static const _difficulties = [
    _DifficultyInfo(
      difficulty: Difficulty.easy,
      label: 'Easy',
      description: '38-45 clues • Score ×1',
      icon: Icons.sentiment_satisfied_rounded,
      color: Color(0xFF4CAF50),
    ),
    _DifficultyInfo(
      difficulty: Difficulty.medium,
      label: 'Medium',
      description: '30-37 clues • Score ×1.5',
      icon: Icons.sentiment_neutral_rounded,
      color: Color(0xFFFFC107),
    ),
    _DifficultyInfo(
      difficulty: Difficulty.hard,
      label: 'Hard',
      description: '25-29 clues • Score ×2',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: Color(0xFFFF9800),
    ),
    _DifficultyInfo(
      difficulty: Difficulty.expert,
      label: 'Expert',
      description: '17-24 clues • Score ×3',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFF44336),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.selectDifficulty,
          style: AppTextStyles.heading3.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                ..._difficulties.asMap().entries.map((entry) {
                  final index = entry.key;
                  final info = entry.value;
                  final bestTime =
                      stats.bestTimeForDifficulty(info.difficulty.name);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _DifficultyCard(
                      info: info,
                      bestTime: bestTime,
                      isDark: isDark,
                      onTap: () async {
                        // Show loading popup
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.black38,
                          builder: (ctx) {
                            final dlgDark =
                                Theme.of(ctx).brightness == Brightness.dark;
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 24),
                                decoration: BoxDecoration(
                                  color: dlgDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                        color: info.color),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.generatingPuzzle,
                                      style: AppTextStyles.body.copyWith(
                                        color: dlgDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        // Let the dialog render before blocking with puzzle generation
                        await Future.delayed(
                            const Duration(milliseconds: 100));

                        ref
                            .read(gameProvider.notifier)
                            .startNewGame(info.difficulty);

                        if (context.mounted) {
                          Navigator.pop(context); // dismiss dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GameScreen(),
                            ),
                          );
                        }
                      },
                    )
                        .animate()
                        .fadeIn(
                          duration: 450.ms,
                          delay: Duration(milliseconds: 100 + index * 100),
                        )
                        .slideX(
                          begin: 0.12,
                          end: 0,
                          curve: Curves.easeOut,
                          duration: 450.ms,
                          delay: Duration(milliseconds: 100 + index * 100),
                        ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _DifficultyInfo {
  final Difficulty difficulty;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _DifficultyInfo({
    required this.difficulty,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class _DifficultyCard extends StatelessWidget {
  final _DifficultyInfo info;
  final int? bestTime;
  final bool isDark;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.info,
    this.bestTime,
    required this.isDark,
    required this.onTap,
  });

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final localizedLabel = l10n.difficultyName(info.difficulty.name);
    String localizedDesc;
    switch (info.difficulty) {
      case Difficulty.easy: localizedDesc = l10n.easyDesc;
      case Difficulty.medium: localizedDesc = l10n.mediumDesc;
      case Difficulty.hard: localizedDesc = l10n.hardDesc;
      case Difficulty.expert: localizedDesc = l10n.expertDesc;
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface.withOpacity(isDark ? 0.45 : 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: info.color.withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: info.color.withOpacity(isDark ? 0.12 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: info.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(info.icon, color: info.color, size: 28),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedLabel,
                        style:
                            AppTextStyles.heading3.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        localizedDesc,
                        style: AppTextStyles.caption
                            .copyWith(color: secondaryColor),
                      ),
                      if (bestTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.emoji_events_rounded,
                                size: 14, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              '${l10n.bestLabel}: ${_formatTime(bestTime!)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: textColor.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
