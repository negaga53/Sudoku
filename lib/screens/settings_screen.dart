import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/providers/settings_provider.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';

/// Full settings screen with appearance and gameplay sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settings,
          style: AppTextStyles.heading3.copyWith(color: textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ==== Appearance ====
          _SectionTitle(title: l10n.appearance, isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            surface: surface,
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_rounded,
                title: l10n.darkMode,
                value: settings.isDarkMode,
                onChanged: (_) => notifier.toggleDarkMode(),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.brightness_auto_rounded,
                title: l10n.followSystemTheme,
                value: settings.followSystem,
                onChanged: (_) => notifier.toggleFollowSystem(),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _AccentColorPicker(
                selectedIndex: settings.accentColorIndex,
                onSelect: notifier.setAccentColor,
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _LanguageSelector(
                currentLocale: settings.locale,
                onSelect: notifier.setLocale,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==== Gameplay ====
          _SectionTitle(title: l10n.gameplay, isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            surface: surface,
            children: [
              _SwitchTile(
                icon: Icons.volume_up_rounded,
                title: l10n.soundEffects,
                value: settings.soundEnabled,
                onChanged: (_) => notifier.toggleSound(),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.vibration_rounded,
                title: l10n.hapticFeedback,
                value: settings.hapticEnabled,
                onChanged: (_) => notifier.toggleHaptic(),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.timer_outlined,
                title: l10n.showTimer,
                value: settings.showTimer,
                onChanged: (_) => notifier.toggleTimer(),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _MistakeLimitSelector(
                currentLimit: settings.mistakeLimit,
                onSelect: notifier.setMistakeLimit,
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.auto_fix_high_rounded,
                title: l10n.autoRemoveNotes,
                value: settings.autoRemoveNotes,
                onChanged: (_) => notifier.toggleAutoRemoveNotes(),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.format_color_fill_rounded,
                title: l10n.highlightIdentical,
                value: settings.highlightIdentical,
                onChanged: (_) => notifier.toggleHighlightIdentical(),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.warning_amber_rounded,
                title: l10n.highlightConflicts,
                value: settings.highlightConflicts,
                onChanged: (_) => notifier.toggleHighlightConflicts(),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
// Grouped card container
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Color surface;
  final List<Widget> children;

  const _SettingsCard({
    required this.isDark,
    required this.surface,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withOpacity(isDark ? 0.45 : 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.18),
            ),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divider
// ---------------------------------------------------------------------------

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      color: isDark ? AppColors.darkGridLine : AppColors.lightGridLine.withOpacity(0.3),
    );
  }
}

// ---------------------------------------------------------------------------
// Switch tile
// ---------------------------------------------------------------------------

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(color: textColor),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Switch(
              key: ValueKey(value),
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accent color picker
// ---------------------------------------------------------------------------

class _AccentColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isDark;

  const _AccentColorPicker({
    required this.selectedIndex,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Text(
                AppLocalizations.of(context).accentColor,
                style: AppTextStyles.body.copyWith(color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(AppColors.accentColors.length, (index) {
              final color = AppColors.accentColors[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black87,
                            width: 2.5,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mistake limit selector
// ---------------------------------------------------------------------------

class _MistakeLimitSelector extends StatelessWidget {
  final int currentLimit;
  final ValueChanged<int> onSelect;
  final bool isDark;

  const _MistakeLimitSelector({
    required this.currentLimit,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final options = [
      (value: 3, label: '3'),
      (value: 5, label: '5'),
      (value: -1, label: '∞'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.heart_broken_rounded, size: 22, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLocalizations.of(context).mistakeLimit,
              style: AppTextStyles.body.copyWith(color: textColor),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final isSelected = currentLimit == opt.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onSelect(opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : (isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.darkGridLine
                                  : AppColors.lightGridLine.withOpacity(0.3),
                            ),
                    ),
                    child: Text(
                      opt.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : textColor,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language selector
// ---------------------------------------------------------------------------

class _LanguageSelector extends StatelessWidget {
  final String currentLocale;
  final ValueChanged<String> onSelect;
  final bool isDark;

  const _LanguageSelector({
    required this.currentLocale,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final accent = Theme.of(context).colorScheme.primary;

    final options = [
      (value: 'en', label: l10n.english),
      (value: 'fr', label: l10n.french),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.language_rounded, size: 22, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.language,
              style: AppTextStyles.body.copyWith(color: textColor),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final isSelected = currentLocale == opt.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onSelect(opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : (isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.darkGridLine
                                  : AppColors.lightGridLine.withOpacity(0.3),
                            ),
                    ),
                    child: Text(
                      opt.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : textColor,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
