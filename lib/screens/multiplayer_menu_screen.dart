import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/providers/multiplayer_provider.dart';
import 'package:sudoku_app/screens/multiplayer_lobby_screen.dart';
import 'package:sudoku_app/screens/multiplayer_create_screen.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/widgets/animated_background.dart';

/// Submenu for online 2-player modes.
class MultiplayerMenuScreen extends ConsumerStatefulWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  ConsumerState<MultiplayerMenuScreen> createState() =>
      _MultiplayerMenuScreenState();
}

class _MultiplayerMenuScreenState extends ConsumerState<MultiplayerMenuScreen> {
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future(_connectIfNeeded);
  }

  Future<void> _connectIfNeeded() async {
    final mp = ref.read(multiplayerProvider);
    if (mp.status == MultiplayerStatus.disconnected) {
      setState(() {
        _connecting = true;
        _error = null;
      });
      await ref.read(multiplayerProvider.notifier).connect();
      if (mounted) {
        final state = ref.read(multiplayerProvider);
        setState(() {
          _connecting = false;
          _error = state.errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context);
    final mp = ref.watch(multiplayerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            ref.read(multiplayerProvider.notifier).disconnect();
            Navigator.pop(context);
          },
        ),
        title: Text(
          l10n.get('online2Players'),
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
            child: _connecting
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: accent),
                      const SizedBox(height: 16),
                      Text(
                        l10n.get('connectingToServer'),
                        style: AppTextStyles.body.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  )
                : _error != null || mp.status == MultiplayerStatus.disconnected
                    ? _buildError(isDark, accent, l10n)
                    : _buildMenu(isDark, accent, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, Color accent, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
          const SizedBox(height: 16),
          Text(
            _error ?? l10n.get('connectionFailed'),
            style: AppTextStyles.body.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(multiplayerProvider.notifier).disconnect();
              _connectIfNeeded();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(bool isDark, Color accent, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accent, accent.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              l10n.get('online2Players'),
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(
                letterSpacing: 2,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),

          const SizedBox(height: 48),

          // Regular Battle button
          _MultiplayerMenuButton(
            icon: Icons.sports_esports_rounded,
            label: l10n.get('regularBattle'),
            subtitle: l10n.get('regularBattleDesc'),
            isDark: isDark,
            accent: accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MultiplayerLobbyScreen(mode: 'battle'),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 14),

          // Create Game button
          _MultiplayerMenuButton(
            icon: Icons.add_circle_outline_rounded,
            label: l10n.get('createGame'),
            subtitle: l10n.get('createGameDesc'),
            isDark: isDark,
            accent: accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MultiplayerCreateScreen(),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu button with subtitle
// ---------------------------------------------------------------------------

class _MultiplayerMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _MultiplayerMenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.button.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: secondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
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
