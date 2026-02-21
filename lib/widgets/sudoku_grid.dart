import 'package:flutter/material.dart';
import 'package:sudoku_app/models/sudoku_board.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/utils/constants.dart';
import 'package:sudoku_app/widgets/sudoku_cell.dart';

class SudokuGrid extends StatelessWidget {
  final SudokuBoard board;
  final void Function(int row, int col) onCellTap;

  const SudokuGrid({
    super.key,
    required this.board,
    required this.onCellTap,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);

    final gridLineColor =
        isDark ? AppColors.darkGridLine : AppColors.lightGridLine;
    final boxLineColor =
        isDark ? AppColors.darkBoxLine : AppColors.lightBoxLine;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor.withOpacity(isDark ? 0.85 : 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: boxLineColor.withOpacity(0.5),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildGrid(
                context,
                constraints.maxWidth,
                gridLineColor,
                boxLineColor,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    double size,
    Color gridLineColor,
    Color boxLineColor,
  ) {
    return CustomPaint(
      foregroundPainter: _GridLinePainter(
        gridLineColor: gridLineColor,
        boxLineColor: boxLineColor,
      ),
      child: Column(
        children: List.generate(AppConstants.gridSize, (row) {
          return Expanded(
            child: Row(
              children: List.generate(AppConstants.gridSize, (col) {
                return Expanded(
                  child: RepaintBoundary(
                    child: SudokuCellWidget(
                      cell: board.getCell(row, col),
                      onTap: onCellTap,
                    ),
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

/// Paints thin inner lines and thick box-boundary lines on top of the grid.
class _GridLinePainter extends CustomPainter {
  final Color gridLineColor;
  final Color boxLineColor;

  _GridLinePainter({
    required this.gridLineColor,
    required this.boxLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final thinPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final thickPaint = Paint()
      ..color = boxLineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final cellW = size.width / AppConstants.gridSize;
    final cellH = size.height / AppConstants.gridSize;

    // Vertical lines
    for (int i = 1; i < AppConstants.gridSize; i++) {
      final x = i * cellW;
      final paint = (i % AppConstants.boxSize == 0) ? thickPaint : thinPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (int i = 1; i < AppConstants.gridSize; i++) {
      final y = i * cellH;
      final paint = (i % AppConstants.boxSize == 0) ? thickPaint : thinPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinePainter oldDelegate) =>
      gridLineColor != oldDelegate.gridLineColor ||
      boxLineColor != oldDelegate.boxLineColor;
}
