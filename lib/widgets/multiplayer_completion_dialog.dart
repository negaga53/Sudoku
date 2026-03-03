import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';

/// Multiplayer game completion dialog.
///
/// Shows win/loss/opponent-left result with scores and retry/home buttons.
class MultiplayerCompletionDialog extends ConsumerStatefulWidget {
  final GameStatus localStatus;
  final int localScore;
  final int elapsedSeconds;
  final Difficulty difficulty;
  final int mistakes;
  final int maxMistakes;
  final bool opponentFinishedFirst;
  final bool opponentLeft;
  final int? opponentScore;
  final int? opponentTime;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;
  final bool waitingForRematch;

  const MultiplayerCompletionDialog({
    super.key,
    required this.localStatus,
    required this.localScore,
    required this.elapsedSeconds,
    required this.difficulty,
    required this.mistakes,
    required this.maxMistakes,
    required this.opponentFinishedFirst,
    required this.opponentLeft,
    this.opponentScore,
    this.opponentTime,
    required this.onRetry,
    required this.onGoHome,
    this.waitingForRematch = false,
  });

  @override
  ConsumerState<MultiplayerCompletionDialog> createState() =>
      _MultiplayerCompletionDialogState();
}

class _MultiplayerCompletionDialogState
    extends ConsumerState<MultiplayerCompletionDialog>
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

    if (_isWin) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  bool get _isWin {
    if (widget.opponentLeft) return true;
    if (widget.opponentFinishedFirst) return false;
    if (widget.localStatus == GameStatus.gameOver) return false;
    return widget.localStatus == GameStatus.completed;
  }

  String get _formattedTime {
    final m = (widget.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (widget.elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatOpponentTime() {
    if (widget.opponentTime == null) return '--:--';
    final m = (widget.opponentTime! ~/ 60).toString().padLeft(2, '0');
    final s = (widget.opponentTime! % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(color: Colors.black54),
          ),
          if (_isWin)
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
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildDialogCard(context, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogCard(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    String title;
    String subtitle;

    if (widget.opponentLeft) {
      title = l10n.get('youWin');
      subtitle = l10n.get('opponentLeftGame');
    } else if (_isWin) {
      title = l10n.get('youWin');
      subtitle = l10n.get('youFinishedFirst');
    } else if (widget.opponentFinishedFirst) {
      title = l10n.get('youLost');
      subtitle = l10n.get('opponentFinishedFirst');
    } else {
      title = l10n.gameOver;
      subtitle = l10n.tooManyMistakes;
    }

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
                title,
                style: AppTextStyles.heading2.copyWith(
                  color: _isWin ? AppColors.gold : AppColors.darkTextError,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Your stats
              _StatRow(
                label: l10n.get('yourScore'),
                value: widget.localScore.toString(),
                color: textColor,
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: l10n.get('yourTime'),
                value: _formattedTime,
                color: textColor,
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: l10n.mistakes,
                value:
                    '${widget.mistakes}/${widget.maxMistakes > 100 ? '∞' : widget.maxMistakes}',
                color: textColor,
              ),

              // Opponent stats (if available)
              if (widget.opponentScore != null ||
                  widget.opponentTime != null) ...[
                const SizedBox(height: 16),
                Divider(color: secondaryColor.withOpacity(0.3)),
                const SizedBox(height: 8),
                _StatRow(
                  label: l10n.get('opponentScore'),
                  value: widget.opponentScore?.toString() ?? '-',
                  color: textColor,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: l10n.get('opponentTime'),
                  value: _formatOpponentTime(),
                  color: textColor,
                ),
              ],

              const SizedBox(height: 28),

              // Buttons
              _GradientButton(
                label: widget.waitingForRematch
                    ? l10n.get('waitingForOpponent')
                    : l10n.retry,
                icon: widget.waitingForRematch
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                accent: accent,
                onTap: widget.waitingForRematch ? null : widget.onRetry,
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
// Internal widgets (same as completion_dialog.dart)
// ---------------------------------------------------------------------------

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: secondaryColor)),
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
  final VoidCallback? onTap;

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
