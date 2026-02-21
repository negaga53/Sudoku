import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/providers/game_provider.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';

/// Displays the current score on the left and mistake indicators on the right.
///
/// The score animates smoothly between values using an [ImplicitlyAnimatedWidget].
/// Mistakes are shown as filled / empty circle indicators.
class ScoreDisplay extends ConsumerWidget {
  const ScoreDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculatedScore = ref.watch(
      gameProvider.select((s) => s.calculatedScore),
    );
    final mistakes = ref.watch(
      gameProvider.select((s) => s.mistakes),
    );
    final maxMistakes = ref.watch(
      gameProvider.select((s) => s.maxMistakes),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Score ---
          Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: 4),
              _AnimatedScore(
                score: calculatedScore,
                style: AppTextStyles.score.copyWith(color: textColor),
              ),
            ],
          ),

          // --- Mistakes ---
          Row(
            children: [
              Text(
                '${l10n.mistakes}: ',
                style: AppTextStyles.caption.copyWith(color: secondaryColor),
              ),
              _MistakeIndicators(
                current: mistakes,
                max: maxMistakes > 100 ? -1 : maxMistakes,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Smoothly transitions between score values using [TweenAnimationBuilder].
class _AnimatedScore extends StatelessWidget {
  final int score;
  final TextStyle style;

  const _AnimatedScore({required this.score, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: score, end: score),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(value.toString(), style: style);
      },
    );
  }
}

/// Shows mistake count as filled / empty red indicators.
///
/// When [max] is -1 (unlimited), shows the count as plain text.
class _MistakeIndicators extends StatelessWidget {
  final int current;
  final int max;

  const _MistakeIndicators({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.darkTextError : AppColors.lightTextError;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (max == -1) {
      // Unlimited mode — just show the count.
      return Text(
        '$current',
        style: AppTextStyles.score.copyWith(color: errorColor),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (index) {
        final filled = index < current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              filled ? Icons.close_rounded : Icons.circle_outlined,
              key: ValueKey('${index}_$filled'),
              size: filled ? 16 : 12,
              color: filled ? errorColor : mutedColor.withOpacity(0.4),
            ),
          ),
        );
      }),
    );
  }
}
