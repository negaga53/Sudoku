import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';

/// A glassmorphism dialog shown when a game is won or lost.
///
/// - **Win**: confetti, star rating, final score, time, play-again / home buttons.
/// - **Game Over**: "Game Over" text, retry / home buttons.
class CompletionDialog extends ConsumerStatefulWidget {
  final GameStatus status;
  final int score;
  final int elapsedSeconds;
  final Difficulty difficulty;
  final int mistakes;
  final int maxMistakes;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;

  const CompletionDialog({
    super.key,
    required this.status,
    required this.score,
    required this.elapsedSeconds,
    required this.difficulty,
    required this.mistakes,
    required this.maxMistakes,
    required this.onPlayAgain,
    required this.onGoHome,
  });

  @override
  ConsumerState<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends ConsumerState<CompletionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    _entranceController.forward();

    if (widget.status == GameStatus.completed) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // --- Star rating ---
  int get _starRating {
    // Max possible score = baseScore * multiplier
    final maxPossible =
        (GameState.baseScore * widget.difficulty.scoreMultiplier).round();
    final ratio = maxPossible > 0 ? widget.score / maxPossible : 0.0;
    if (ratio > 0.8) return 3;
    if (ratio > 0.5) return 2;
    if (ratio > 0.0) return 1;
    return 0;
  }

  String get _formattedTime {
    final m = (widget.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (widget.elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWin = widget.status == GameStatus.completed;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Semi-transparent backdrop
          GestureDetector(
            onTap: () {}, // swallow taps
            child: Container(color: Colors.black54),
          ),

          // Confetti
          if (isWin)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.06,
              gravity: 0.2,
              colors: const [
                AppColors.gold,
                Color(0xFF6C63FF),
                Color(0xFF00BFA6),
                Color(0xFFFF6B6B),
                Color(0xFF4ECDC4),
              ],
            ),

          // Dialog
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildDialogCard(context, isDark, isWin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogCard(BuildContext context, bool isDark, bool isWin) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: surface.withOpacity(isDark ? 0.65 : 0.80),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                isWin ? l10n.congratulations : l10n.gameOver,
                style: AppTextStyles.heading2.copyWith(
                  color: isWin ? AppColors.gold : AppColors.darkTextError,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                isWin
                    ? l10n.puzzleSolved
                    : l10n.tooManyMistakes,
                style: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Stars (win only)
              if (isWin) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final filled = i < _starRating;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 40,
                        color: filled ? AppColors.gold : secondaryColor.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],

              // Stats
              if (isWin) ...[
                _StatRow(label: l10n.score, value: widget.score.toString(), color: textColor),
                const SizedBox(height: 8),
                _StatRow(label: l10n.time, value: _formattedTime, color: textColor),
                const SizedBox(height: 8),
                _StatRow(label: l10n.difficulty, value: l10n.difficultyName(widget.difficulty.name), color: textColor),
                const SizedBox(height: 8),
                _StatRow(
                  label: l10n.mistakes,
                  value: '${widget.mistakes}/${widget.maxMistakes > 100 ? '∞' : widget.maxMistakes}',
                  color: textColor,
                ),
                const SizedBox(height: 28),
              ],

              // Buttons
              _GradientButton(
                label: isWin ? l10n.playAgain : l10n.retry,
                icon: Icons.refresh_rounded,
                accent: accent,
                onTap: widget.onPlayAgain,
              ),
              const SizedBox(height: 12),
              _GradientButton(
                label: l10n.home,
                icon: Icons.home_rounded,
                accent: accent,
                outlined: true,
                onTap: widget.onGoHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: secondaryColor)),
        Text(value, style: AppTextStyles.score.copyWith(color: color)),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool outlined;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.accent,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label, style: AppTextStyles.button),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label, style: AppTextStyles.button),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
