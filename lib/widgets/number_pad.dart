import 'package:flutter/material.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/utils/constants.dart';

class NumberPad extends StatelessWidget {
  /// Callback when a number button is tapped.
  final void Function(int number) onNumberTap;

  /// Map of number → remaining count (how many more of that number are needed).
  /// Keys 1-9. If null, counts are not shown.
  final Map<int, int>? remainingCounts;

  /// The number that matches the currently selected cell (highlighted).
  final int? activeNumber;

  const NumberPad({
    super.key,
    required this.onNumberTap,
    this.remainingCounts,
    this.activeNumber,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          final number = index + 1;
          final remaining = remainingCounts?[number];
          final isFullyPlaced = remaining != null && remaining <= 0;
          final isActive = activeNumber == number && !isFullyPlaced;

          return _NumberButton(
            number: number,
            remaining: remaining,
            isActive: isActive,
            isDisabled: isFullyPlaced,
            isDark: _isDark(context),
            onTap: isFullyPlaced ? null : () => onNumberTap(number),
          );
        }),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final int? remaining;
  final bool isActive;
  final bool isDisabled;
  final bool isDark;
  final VoidCallback? onTap;

  const _NumberButton({
    required this.number,
    this.remaining,
    this.isActive = false,
    this.isDisabled = false,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? AppColors.darkTextFilled : AppColors.lightTextFilled;
    final defaultBg = isDark
        ? AppColors.darkSurface.withOpacity(0.6)
        : AppColors.lightSurface.withOpacity(0.8);
    final disabledBg = isDark
        ? AppColors.darkSurface.withOpacity(0.25)
        : AppColors.lightSurface.withOpacity(0.35);

    final bgColor =
        isDisabled ? disabledBg : (isActive ? accentColor : defaultBg);
    final textColor = isDisabled
        ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
            .withOpacity(0.4)
        : isActive
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppConstants.fastAnimationDuration,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? null
                  : Border.all(
                      color: isDark
                          ? AppColors.darkGridLine.withOpacity(0.4)
                          : AppColors.lightGridLine.withOpacity(0.3),
                      width: 1,
                    ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.35),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  number.toString(),
                  style: AppTextStyles.numberPad.copyWith(color: textColor),
                ),
                if (remaining != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    remaining.toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: textColor.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
