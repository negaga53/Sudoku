import 'package:flutter/material.dart';
import 'package:sudoku_app/models/sudoku_board.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/animations/cell_animations.dart';
import 'package:sudoku_app/utils/constants.dart';

class SudokuCellWidget extends StatefulWidget {
  final SudokuCell cell;
  final void Function(int row, int col) onTap;

  /// Optional external shake controller. When null the widget creates its own.
  final AnimationController? shakeController;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.onTap,
    this.shakeController,
  });

  @override
  State<SudokuCellWidget> createState() => _SudokuCellWidgetState();
}

class _SudokuCellWidgetState extends State<SudokuCellWidget>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _popInController;
  late Animation<double> _popInAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _celebrateController;
  late Animation<double> _celebrateAnimation;

  bool _ownsShakeController = false;
  int _previousValue = 0;
  late Listenable _mergedAnimation;
  late Listenable _numberAnimation;

  @override
  void initState() {
    super.initState();

    // Shake
    if (widget.shakeController != null) {
      _shakeController = widget.shakeController!;
    } else {
      _shakeController = CellAnimations.createShakeController(this);
      _ownsShakeController = true;
    }
    _shakeAnimation = CellAnimations.shakeAnimation(_shakeController);

    // Pop-in
    _popInController = CellAnimations.createPopInController(this);
    _popInAnimation = CellAnimations.popInAnimation(_popInController);
    // Start fully visible so existing numbers don't animate during build.
    _popInController.value = 1.0;

    // Pulse
    _pulseController = CellAnimations.createPulseController(this);
    _pulseAnimation = CellAnimations.pulseAnimation(_pulseController);

    // Celebrate
    _celebrateController = CellAnimations.createCelebrateController(this);
    _celebrateAnimation = CellAnimations.celebrateAnimation(_celebrateController);

    _mergedAnimation = Listenable.merge(
        [_shakeAnimation, _popInAnimation, _pulseAnimation, _celebrateAnimation]);

    _numberAnimation = Listenable.merge(
        [_popInAnimation, _celebrateAnimation]);

    _previousValue = widget.cell.value;

    if (widget.cell.isSelected) {
      CellAnimations.startPulse(_pulseController);
    }
  }

  @override
  void didUpdateWidget(covariant SudokuCellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger pop-in when a new number is placed.
    if (widget.cell.value != 0 && widget.cell.value != _previousValue) {
      CellAnimations.playPopIn(_popInController);
    }
    _previousValue = widget.cell.value;

    // Error → shake
    if (widget.cell.state == CellState.error &&
        oldWidget.cell.state != CellState.error) {
      CellAnimations.playShake(_shakeController);
    }

    // Rejected placement → shake
    if (widget.cell.isConflict && !oldWidget.cell.isConflict &&
        widget.cell.state != CellState.error) {
      CellAnimations.playShake(_shakeController);
    }

    // Celebration (number fully placed)
    if (widget.cell.isCelebrating && !oldWidget.cell.isCelebrating) {
      CellAnimations.playCelebrate(_celebrateController);
    }

    // Selection pulse
    if (widget.cell.isSelected && !oldWidget.cell.isSelected) {
      CellAnimations.startPulse(_pulseController);
    } else if (!widget.cell.isSelected && oldWidget.cell.isSelected) {
      CellAnimations.stopPulse(_pulseController);
    }

    // Update external shake controller reference if it changed.
    if (widget.shakeController != null &&
        widget.shakeController != oldWidget.shakeController) {
      if (_ownsShakeController) {
        _shakeController.dispose();
        _ownsShakeController = false;
      }
      _shakeController = widget.shakeController!;
      _shakeAnimation = CellAnimations.shakeAnimation(_shakeController);
    }
  }

  @override
  void dispose() {
    if (_ownsShakeController) _shakeController.dispose();
    _popInController.dispose();
    _pulseController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor {
    final cell = widget.cell;
    if (cell.state == CellState.error || cell.isConflict) {
      return _isDark ? AppColors.darkCellError : AppColors.lightCellError;
    }
    if (cell.isCelebrating) {
      return _isDark
          ? AppColors.darkCellSameValue
          : AppColors.lightCellSameValue;
    }
    if (cell.isSelected) {
      return _isDark ? AppColors.darkCellSelected : AppColors.lightCellSelected;
    }
    if (cell.isSameValue) {
      return _isDark
          ? AppColors.darkCellSameValue
          : AppColors.lightCellSameValue;
    }
    if (cell.isHighlighted) {
      return _isDark
          ? AppColors.darkCellHighlighted
          : AppColors.lightCellHighlighted;
    }
    if (cell.isGiven) {
      return _isDark ? AppColors.darkCellGiven : AppColors.lightCellGiven;
    }
    return _isDark ? AppColors.darkCellDefault : AppColors.lightCellDefault;
  }

  Color get _textColor {
    final cell = widget.cell;
    if (cell.isCelebrating) {
      return const Color(0xFF4CAF50);
    }
    if (cell.state == CellState.error || cell.isConflict) {
      return _isDark ? AppColors.darkTextError : AppColors.lightTextError;
    }
    if (cell.isGiven) {
      return _isDark ? AppColors.darkTextGiven : AppColors.lightTextGiven;
    }
    if (cell.state == CellState.filled) {
      return _isDark ? AppColors.darkTextFilled : AppColors.lightTextFilled;
    }
    return _isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  }

  TextStyle get _cellTextStyle {
    final cell = widget.cell;
    final base =
        cell.isGiven ? AppTextStyles.cellNumberGiven : AppTextStyles.cellNumber;
    return base.copyWith(color: _textColor);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;

    return GestureDetector(
      onTap: () => widget.onTap(cell.row, cell.col),
      child: AnimatedBuilder(
        animation: _mergedAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: AppConstants.fastAnimationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _backgroundColor,
            border: cell.isSelected
                ? Border.all(
                    color: (_isDark
                            ? AppColors.darkTextFilled
                            : AppColors.lightTextFilled)
                        .withOpacity(0.8),
                    width: 2.0,
                  )
                : null,
            boxShadow: cell.isSelected
                ? [
                    BoxShadow(
                      color: (_isDark
                              ? AppColors.darkTextFilled
                              : AppColors.lightTextFilled)
                          .withOpacity(0.35),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: cell.isEmpty
                ? (cell.hasNotes ? _buildNotes(cell) : const SizedBox.shrink())
                : _buildNumber(cell),
          ),
        ),
      ),
    );
  }

  Widget _buildNumber(SudokuCell cell) {
    return AnimatedBuilder(
      animation: _numberAnimation,
      builder: (context, child) {
        final scale = _celebrateController.isAnimating
            ? _celebrateAnimation.value
            : _popInAnimation.value.clamp(0.0, 1.2);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Text(
        cell.value.toString(),
        style: _cellTextStyle,
      ),
    );
  }

  Widget _buildNotes(SudokuCell cell) {
    final noteColor =
        _isDark ? AppColors.darkTextNotes : AppColors.lightTextNotes;
    final noteStyle = AppTextStyles.cellNote.copyWith(color: noteColor);
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(3, (col) {
                final n = row * 3 + col + 1;
                return Expanded(
                  child: Center(
                    child: cell.notes.contains(n)
                        ? Text(n.toString(), style: noteStyle)
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
