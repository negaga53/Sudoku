import 'package:flutter/material.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/utils/constants.dart';

class GameControls extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onToggleNotes;
  final VoidCallback onHint;
  final bool isNotesMode;
  final int hintsRemaining;
  final bool canUndo;
  final String? undoLabel;
  final String? eraseLabel;
  final String? notesLabel;
  final String? hintLabel;

  const GameControls({
    super.key,
    required this.onUndo,
    required this.onErase,
    required this.onToggleNotes,
    required this.onHint,
    this.isNotesMode = false,
    this.hintsRemaining = 3,
    this.canUndo = true,
    this.undoLabel,
    this.eraseLabel,
    this.notesLabel,
    this.hintLabel,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: Icons.undo_rounded,
          label: undoLabel ?? 'Undo',
          isDark: isDark,
          isDisabled: !canUndo,
          onTap: canUndo ? onUndo : null,
        ),
        _ControlButton(
          icon: Icons.backspace_outlined,
          label: eraseLabel ?? 'Erase',
          isDark: isDark,
          onTap: onErase,
        ),
        _ControlButton(
          icon: Icons.edit_outlined,
          label: notesLabel ?? 'Notes',
          isDark: isDark,
          isActive: isNotesMode,
          onTap: onToggleNotes,
        ),
        _ControlButton(
          icon: Icons.lightbulb_outline_rounded,
          label: hintLabel ?? 'Hint',
          isDark: isDark,
          badgeCount: hintsRemaining,
          isDisabled: hintsRemaining <= 0,
          onTap: hintsRemaining > 0 ? onHint : null,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isActive;
  final bool isDisabled;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isActive = false,
    this.isDisabled = false,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? AppColors.darkTextFilled : AppColors.lightTextFilled;

    final fgColor = isDisabled
        ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
            .withOpacity(0.4)
        : isActive
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final bgColor = isActive
        ? accentColor
        : isDark
            ? AppColors.darkSurface.withOpacity(0.5)
            : AppColors.lightSurface.withOpacity(0.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.fastAnimationDuration,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? null
              : Border.all(
                  color: isDark
                      ? AppColors.darkGridLine.withOpacity(0.3)
                      : AppColors.lightGridLine.withOpacity(0.25),
                  width: 1,
                ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: fgColor, size: 24),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: fgColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
