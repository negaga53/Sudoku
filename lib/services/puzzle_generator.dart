/// Sudoku puzzle generator.
///
/// Generates a fully solved 9×9 board using randomised backtracking, then
/// removes cells according to the requested difficulty while ensuring the
/// resulting puzzle has a unique solution.
library;

import 'dart:math';

import '../models/game_state.dart';
import 'puzzle_solver.dart';

// ---------------------------------------------------------------------------
// Result container
// ---------------------------------------------------------------------------

/// Holds the generated puzzle, its solution, and how many clues remain.
class PuzzleResult {
  /// The puzzle board with removed cells set to `0`.
  final List<List<int>> puzzle;

  /// The complete solution.
  final List<List<int>> solution;

  /// The number of filled (non-zero) cells in [puzzle].
  final int clueCount;

  PuzzleResult({
    required this.puzzle,
    required this.solution,
    required this.clueCount,
  });
}

// ---------------------------------------------------------------------------
// Generator
// ---------------------------------------------------------------------------

class PuzzleGenerator {
  static final _random = Random();

  /// Generates a complete, valid 9×9 Sudoku solution.
  static List<List<int>> generateSolution() {
    final board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(board);
    return board;
  }

  /// Generates a puzzle for the given [difficulty].
  ///
  /// The returned [PuzzleResult] contains both the puzzle (with blanks) and
  /// the full solution, along with the number of clues left on the board.
  static PuzzleResult generatePuzzle(Difficulty difficulty) {
    final solution = generateSolution();
    final puzzle = _copyBoard(solution);

    final minClues = difficulty.clueRange; // lower bound
    final maxClues = difficulty.maxClues; // upper bound
    final targetClues = minClues + _random.nextInt(maxClues - minClues + 1);

    _removeNumbers(puzzle, targetClues);

    return PuzzleResult(
      puzzle: puzzle,
      solution: solution,
      clueCount: targetClues,
    );
  }

  // -------------------------------------------------------------------------
  // Board filling
  // -------------------------------------------------------------------------

  /// Fills [board] in place with a complete valid Sudoku using randomised
  /// backtracking.
  static bool _fillBoard(List<List<int>> board) {
    final empty = _findEmpty(board);
    if (empty == null) return true; // board is complete

    final (row, col) = empty;
    final numbers = _shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9]);

    for (final num in numbers) {
      if (_isValid(board, row, col, num)) {
        board[row][col] = num;
        if (_fillBoard(board)) return true;
        board[row][col] = 0;
      }
    }

    return false;
  }

  // -------------------------------------------------------------------------
  // Cell removal
  // -------------------------------------------------------------------------

  /// Removes numbers from a filled [board] until only [targetClues] remain,
  /// while guaranteeing the puzzle still has a unique solution.
  static void _removeNumbers(List<List<int>> board, int targetClues) {
    // Build a shuffled list of all 81 cell positions.
    final positions = <(int, int)>[
      for (int r = 0; r < 9; r++)
        for (int c = 0; c < 9; c++) (r, c),
    ];
    _shuffleList(positions);

    var currentClues = 81;

    for (final (row, col) in positions) {
      if (currentClues <= targetClues) break;

      final saved = board[row][col];
      if (saved == 0) continue; // already empty

      board[row][col] = 0;

      // Verify uniqueness on a copy so the working board is untouched.
      if (PuzzleSolver.hasUniqueSolution(board)) {
        currentClues--;
      } else {
        // Removing this cell creates ambiguity — put it back.
        board[row][col] = saved;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  /// Returns `true` if placing [num] at ([row], [col]) is valid.
  static bool _isValid(List<List<int>> board, int row, int col, int num) {
    return PuzzleSolver.isValidPlacement(board, row, col, num);
  }

  // -------------------------------------------------------------------------
  // Utility helpers
  // -------------------------------------------------------------------------

  /// Returns a new list containing the elements of [list] in random order.
  static List<T> _shuffle<T>(List<T> list) {
    final copy = List<T>.from(list);
    _shuffleList(copy);
    return copy;
  }

  /// Shuffles [list] in place using the Fisher–Yates algorithm.
  static void _shuffleList<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  /// Finds the first empty cell (value `0`) scanning left-to-right,
  /// top-to-bottom.
  static (int, int)? _findEmpty(List<List<int>> board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) return (r, c);
      }
    }
    return null;
  }

  /// Deep-copies a 9×9 board.
  static List<List<int>> _copyBoard(List<List<int>> board) {
    return [for (final row in board) [...row]];
  }
}
