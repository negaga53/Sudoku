import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/providers/multiplayer_provider.dart';
import 'package:sudoku_app/screens/multiplayer_game_screen.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/widgets/animated_background.dart';

/// Screen to create a new multiplayer game: pick difficulty, then wait.
class MultiplayerCreateScreen extends ConsumerStatefulWidget {
  const MultiplayerCreateScreen({super.key});

  @override
  ConsumerState<MultiplayerCreateScreen> createState() =>
      _MultiplayerCreateScreenState();
}

class _MultiplayerCreateScreenState
    extends ConsumerState<MultiplayerCreateScreen> {
  String _selectedDifficulty = 'easy';
  bool _created = false;

  static const _difficulties = [
    ('easy', Icons.sentiment_satisfied_rounded, Color(0xFF4CAF50)),
    ('medium', Icons.sentiment_neutral_rounded, Color(0xFFFFC107)),
    ('hard', Icons.sentiment_dissatisfied_rounded, Color(0xFFFF9800)),
    ('expert', Icons.whatshot_rounded, Color(0xFFF44336)),
  ];

  void _createGame() {
    ref.read(multiplayerProvider.notifier).createGame(
          mode: 'battle',
          difficulty: _selectedDifficulty,
        );
    setState(() => _created = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context);
    final mp = ref.watch(multiplayerProvider);

    // Navigate to game screen when game starts
    if (mp.status == MultiplayerStatus.inGame && mp.puzzle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MultiplayerGameScreen()),
          );
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_created && mp.gameId != null) {
          ref.read(multiplayerProvider.notifier).leaveGame();
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (_created && mp.gameId != null) {
                ref.read(multiplayerProvider.notifier).leaveGame();
              }
              Navigator.pop(context);
            },
          ),
          title: Text(
            l10n.get('createGame'),
            style: AppTextStyles.heading3.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
        body: AnimatedBackground(
          child: SafeArea(
            child: Center(
              child: _created
                  ? _buildWaiting(isDark, accent, l10n, mp)
                  : _buildDifficultyPicker(isDark, accent, l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyPicker(
      bool isDark, Color accent, AppLocalizations l10n) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.get('selectDifficulty'),
            style: AppTextStyles.heading3.copyWith(color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.get('modeLabel') + l10n.get('regularBattle'),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ..._difficulties.asMap().entries.map((entry) {
            final index = entry.key;
            final (diff, icon, color) = entry.value;
            final isSelected = _selectedDifficulty == diff;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDifficulty = diff),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withOpacity(0.15)
                            : surface.withOpacity(isDark ? 0.4 : 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : Colors.white.withOpacity(isDark ? 0.06 : 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 28),
                          const SizedBox(width: 16),
                          Text(
                            l10n.difficultyName(diff[0].toUpperCase() +
                                diff.substring(1)),
                            style:
                                AppTextStyles.button.copyWith(color: textColor),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: accent, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: Duration(milliseconds: 50 + index * 80),
                  )
                  .slideX(begin: 0.1, end: 0, curve: Curves.easeOut),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
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
                onPressed: _createGame,
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(l10n.get('createAndWait'),
                    style: AppTextStyles.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms)
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildWaiting(
    bool isDark,
    Color accent,
    AppLocalizations l10n,
    MultiplayerState mp,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: accent)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms, color: accent.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text(
            l10n.get('waitingForOpponent'),
            style: AppTextStyles.heading3.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (mp.gameId != null) ...[
            Text(
              '${l10n.get('gameIdLabel')}${mp.gameId}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            l10n.difficultyName(
              _selectedDifficulty[0].toUpperCase() +
                  _selectedDifficulty.substring(1),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
