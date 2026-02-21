/// Sudoku puzzle solver using efficient backtracking.
///
/// Provides methods for solving boards, counting solutions,
/// validating placements, and finding candidate values.
library;

class PuzzleSolver {
  /// Solves the given [board] in place using backtracking.
  ///
  /// Empty cells are represented by `0`. Returns `true` if a solution
  /// was found, `false` if the board is unsolvable.
  static bool solve(List<List<int>> board) {
    final empty = _findEmpty(board);
    if (empty == null) return true;

    final (row, col) = empty;
    final candidates = getCandidates(board, row, col);

    for (final num in candidates) {
      board[row][col] = num;
      if (solve(board)) return true;
      board[row][col] = 0;
    }

    return false;
  }

  /// Counts the number of solutions for [board], stopping early once
  /// [maxCount] solutions have been found.
  ///
  /// This is useful for verifying puzzle uniqueness without exhaustively
  /// enumerating all possibilities.
  static int countSolutions(List<List<int>> board, {int maxCount = 2}) {
    return _countSolutionsHelper(board, maxCount, 0);
  }

  static int _countSolutionsHelper(
    List<List<int>> board,
    int maxCount,
    int found,
  ) {
    final empty = _findEmpty(board);
    if (empty == null) return found + 1;

    final (row, col) = empty;

    for (int num = 1; num <= 9; num++) {
      if (!isValidPlacement(board, row, col, num)) continue;

      board[row][col] = num;
      found = _countSolutionsHelper(board, maxCount, found);
      board[row][col] = 0;

      if (found >= maxCount) return found;
    }

    return found;
  }

  /// Returns `true` if the [board] has exactly one solution.
  static bool hasUniqueSolution(List<List<int>> board) {
    final copy = _copyBoard(board);
    return countSolutions(copy, maxCount: 2) == 1;
  }

  /// Checks whether placing [num] at ([row], [col]) is valid according
  /// to standard Sudoku rules (row, column, and 3×3 box constraints).
  ///
  /// Does not consider the current value at ([row], [col]) — it purely
  /// checks the rest of the board for conflicts.
  static bool isValidPlacement(
    List<List<int>> board,
    int row,
    int col,
    int num,
  ) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == num) return false;
    }

    // Check column
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == num) return false;
    }

    // Check 3×3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (r != row && c != col && board[r][c] == num) return false;
      }
    }

    return true;
  }

  /// Returns the set of valid candidate numbers for the cell at
  /// ([row], [col]).
  ///
  /// If the cell is already filled (non-zero), returns an empty set.
  static Set<int> getCandidates(List<List<int>> board, int row, int col) {
    if (board[row][col] != 0) return {};

    final candidates = <int>{};
    for (int num = 1; num <= 9; num++) {
      if (isValidPlacement(board, row, col, num)) {
        candidates.add(num);
      }
    }
    return candidates;
  }

  /// Returns a list of (row, col) positions that conflict with placing
  /// [num] at ([row], [col]).
  ///
  /// A conflict is any cell in the same row, column, or 3×3 box that
  /// already contains [num].
  static List<(int, int)> getConflicts(
    List<List<int>> board,
    int row,
    int col,
    int num,
  ) {
    final conflicts = <(int, int)>[];

    // Row conflicts
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == num) {
        conflicts.add((row, c));
      }
    }

    // Column conflicts
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == num) {
        conflicts.add((r, col));
      }
    }

    // Box conflicts (avoid duplicates with row/column)
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (r != row && c != col && board[r][c] == num) {
          // Only add if not already found via row or column scan
          if (r != row && c != col) {
            conflicts.add((r, c));
          }
        }
      }
    }

    return conflicts;
  }

  /// Validates the entire board state.
  ///
  /// Returns `true` if no filled cell violates Sudoku rules. Empty cells
  /// (value `0`) are ignored.
  static bool isBoardValid(List<List<int>> board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final num = board[r][c];
        if (num == 0) continue;
        if (num < 1 || num > 9) return false;
        if (!isValidPlacement(board, r, c, num)) return false;
      }
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Finds the first empty cell (value `0`) scanning left-to-right,
  /// top-to-bottom. Returns `null` if the board is full.
  static (int, int)? _findEmpty(List<List<int>> board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) return (r, c);
      }
    }
    return null;
  }

  /// Creates a deep copy of a 9×9 board.
  static List<List<int>> _copyBoard(List<List<int>> board) {
    return [for (final row in board) [...row]];
  }
}
