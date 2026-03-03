import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/models/multiplayer_game.dart';
import 'package:sudoku_app/providers/multiplayer_provider.dart';
import 'package:sudoku_app/screens/multiplayer_game_screen.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/widgets/animated_background.dart';

/// Lists available games for a given mode; allows joining.
class MultiplayerLobbyScreen extends ConsumerStatefulWidget {
  final String mode;

  const MultiplayerLobbyScreen({super.key, required this.mode});

  @override
  ConsumerState<MultiplayerLobbyScreen> createState() =>
      _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState
    extends ConsumerState<MultiplayerLobbyScreen> {
  @override
  void initState() {
    super.initState();
    // Request list on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    ref.read(multiplayerProvider.notifier).listGames(mode: widget.mode);
  }

  void _joinGame(String gameId) {
    ref.read(multiplayerProvider.notifier).joinGame(gameId: gameId);
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.get('regularBattle'),
          style: AppTextStyles.heading3.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: mp.availableGames.isEmpty
              ? _buildEmpty(isDark, accent, l10n)
              : _buildList(isDark, accent, l10n, mp.availableGames),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color accent, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.get('noGamesAvailable'),
            style: AppTextStyles.body.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.get('refresh')),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isDark, Color accent, AppLocalizations l10n,
      List<MultiplayerGame> games) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final diffLabel = l10n.difficultyName(
          game.difficulty[0].toUpperCase() + game.difficulty.substring(1),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _joinGame(game.gameId),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: surface.withOpacity(isDark ? 0.45 : 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          Colors.white.withOpacity(isDark ? 0.06 : 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(isDark ? 0.25 : 0.06),
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
                        child: Icon(Icons.sports_esports_rounded,
                            color: accent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.gameId,
                              style: AppTextStyles.button
                                  .copyWith(color: textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              diffLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.login_rounded, color: accent, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(
                duration: 350.ms,
                delay: Duration(milliseconds: 50 + index * 60),
              )
              .slideX(begin: 0.08, end: 0, curve: Curves.easeOut),
        );
      },
    );
  }
}
