import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/models/sudoku_board.dart';
import 'package:sudoku_app/services/puzzle_generator.dart';
import 'package:sudoku_app/providers/settings_provider.dart';

// ---------------------------------------------------------------------------
// Game notifier
// ---------------------------------------------------------------------------

class GameNotifier extends StateNotifier<GameState> {
  final Ref _ref;
  SudokuBoard _board;
  Timer? _errorClearTimer;

  GameNotifier(this._ref)
      : _board = SudokuBoard(),
        super(GameState());

  @override
  void dispose() {
    _errorClearTimer?.cancel();
    _celebrationClearTimer?.cancel();
    super.dispose();
  }

  /// The current board. Exposed via [boardProvider].
  SudokuBoard get board => _board;

  // -----------------------------------------------------------------------
  // New game
  // -----------------------------------------------------------------------

  /// Generates a new puzzle for [difficulty], initialises the board and
  /// resets all game state.
  void startNewGame(Difficulty difficulty) {
    final result = PuzzleGenerator.generatePuzzle(difficulty);
    final settings = _ref.read(settingsProvider);

    _board = SudokuBoard();

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final puzzleValue = result.puzzle[r][c];
        final solutionValue = result.solution[r][c];

        _board.setCell(
          r,
          c,
          SudokuCell(
            row: r,
            col: c,
            value: puzzleValue,
            solution: solutionValue,
            state: puzzleValue != 0 ? CellState.given : CellState.empty,
          ),
        );
      }
    }

    state = GameState(
      difficulty: difficulty,
      status: GameStatus.inProgress,
      maxMistakes: settings.mistakeLimit == -1
          ? 999 // effectively unlimited
          : settings.mistakeLimit,
      gameId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  // -----------------------------------------------------------------------
  // Multiplayer game (puzzle provided by server)
  // -----------------------------------------------------------------------

  /// Initialises the board from a pre-generated puzzle/solution pair.
  /// Used for multiplayer so both players get the same grid.
  void startMultiplayerGame({
    required Difficulty difficulty,
    required List<List<int>> puzzle,
    required List<List<int>> solution,
  }) {
    final settings = _ref.read(settingsProvider);
    _board = SudokuBoard();

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final puzzleValue = puzzle[r][c];
        final solutionValue = solution[r][c];

        _board.setCell(
          r,
          c,
          SudokuCell(
            row: r,
            col: c,
            value: puzzleValue,
            solution: solutionValue,
            state: puzzleValue != 0 ? CellState.given : CellState.empty,
          ),
        );
      }
    }

    state = GameState(
      difficulty: difficulty,
      status: GameStatus.inProgress,
      maxMistakes: settings.mistakeLimit == -1
          ? 999
          : settings.mistakeLimit,
      gameId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  // -----------------------------------------------------------------------
  // Number-first selection (select number from pad, then tap cell)
  // -----------------------------------------------------------------------

  /// Handles a number pad tap using current game state.
  ///
  /// If an empty cell is selected, this attempts placement directly.
  /// Otherwise it toggles/updates number-first selection mode.
  void handleNumberPadTap(int number) {
    if (state.status != GameStatus.inProgress) return;

    final hasSelection = state.hasSelection;
    final selectedCell = hasSelection
        ? _board.getCell(state.selectedRow!, state.selectedCol!)
        : null;

    final selectedCellIsEmpty =
        selectedCell != null && selectedCell.value == 0 && !selectedCell.isGiven;

    if (selectedCellIsEmpty) {
      if (state.activeNumber == number) {
        state = state.copyWith(clearActiveNumber: true);
        _updateHighlights();
        return;
      }

      // Cell-first mode:
      // 1) select the tapped panel number, then
      // 2) attempt placement into the selected cell.
      // placeNumber() handles:
      // - correct placement,
      // - obvious-conflict rejection feedback,
      // - non-obvious wrong-entry error flow.
      state = state.copyWith(activeNumber: number);
      _updateHighlights();
      placeNumber(number);
      return;
    }

    final selectedValue = selectedCell?.value ?? 0;
    final effectiveActiveNumber =
        state.activeNumber ?? (selectedValue != 0 ? selectedValue : null);

    if (effectiveActiveNumber == number) {
      clearSelection();
      return;
    }

    selectNumber(number);
  }

  /// Pre-selects [number] from the number pad. If the same number is
  /// tapped again, it deselects. This clears cell selection and highlights
  /// all cells with that number.
  void selectNumber(int number) {
    if (state.status != GameStatus.inProgress) return;

    if (state.activeNumber == number) {
      // Deselect
      state = state.copyWith(clearActiveNumber: true, clearSelection: true);
    } else {
      state = state.copyWith(activeNumber: number, clearSelection: true);
    }
    _updateHighlights();
  }

  // -----------------------------------------------------------------------
  // Cell selection
  // -----------------------------------------------------------------------

  /// Selects the cell at ([row], [col]). If an [activeNumber] is set,
  /// places that number immediately instead of just selecting.
  void selectCell(int row, int col) {
    if (state.status != GameStatus.inProgress) return;

    if (state.hasActiveNumber) {
      final tappedCell = _board.getCell(row, col);
      if (tappedCell.value != 0) {
        // Tapped a filled cell while in number-first mode → switch to its
        // number, unless that number is already fully placed.
        if (_isNumberFullyPlaced(tappedCell.value)) {
          state = state.copyWith(
            selectedRow: row,
            selectedCol: col,
            clearActiveNumber: true,
          );
        } else {
          state = state.copyWith(
            selectedRow: row,
            selectedCol: col,
            activeNumber: tappedCell.value,
          );
        }
        _updateHighlights();
        return;
      }
      // Number-first mode: place the pre-selected number on the tapped cell
      state = state.copyWith(selectedRow: row, selectedCol: col);
      placeNumber(state.activeNumber!);
      // Re-apply number-first highlights after placement
      _updateHighlights();
      return;
    }

    final cell = _board.getCell(row, col);
    if (cell.value != 0) {
      // Don't enter number-first mode for a fully placed number.
      if (_isNumberFullyPlaced(cell.value)) {
        state = state.copyWith(
          selectedRow: row,
          selectedCol: col,
          clearActiveNumber: true,
        );
      } else {
        // Tapped a filled cell → enter number-first mode with that number
        state = state.copyWith(
          selectedRow: row,
          selectedCol: col,
          activeNumber: cell.value,
        );
      }
    } else {
      state = state.copyWith(
        selectedRow: row,
        selectedCol: col,
        clearActiveNumber: true,
      );
    }
    _updateHighlights();
  }

  // -----------------------------------------------------------------------
  // Number placement
  // -----------------------------------------------------------------------

  /// Places [number] on the currently selected cell. Behaves differently
  /// depending on notes mode and correctness.
  ///
  /// Returns without placing if the number visibly conflicts with another
  /// cell in the same row, column, or 3×3 box (i.e. another cell already
  /// shows that number there).
  void placeNumber(int number) {
    if (!state.hasSelection) return;
    if (state.status != GameStatus.inProgress) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    final cell = _board.getCell(row, col);

    // Cannot edit given cells
    if (cell.isGiven) return;

    // Cannot overwrite correctly placed numbers
    if (cell.isCorrect && cell.state == CellState.filled) return;

    // --- Prevent obviously invalid placement ---
    // Check if the same number already exists in the row, column, or box.
    if (!state.isNotesMode && _hasVisibleConflict(row, col, number)) {
      _showRejectionFeedback(row, col, number);
      return;
    }

    // Notes mode ---------------------------------------------------------
    if (state.isNotesMode) {
      final previousNotes = Set<int>.from(cell.notes);
      final newNotes = Set<int>.from(cell.notes);

      if (newNotes.contains(number)) {
        newNotes.remove(number);
      } else {
        newNotes.add(number);
      }

      // Clear value if one exists so notes can show
      final previousValue = cell.value;
      _board.setCell(
        row,
        col,
        cell.copyWith(
          value: 0,
          state: CellState.empty,
          notes: newNotes,
        ),
      );

      final history = List<GameMove>.from(state.moveHistory)
        ..add(GameMove(
          row: row,
          col: col,
          previousValue: previousValue,
          newValue: 0,
          previousNotes: previousNotes,
          newNotes: newNotes,
          wasNotesMode: true,
        ));

      state = state.copyWith(moveHistory: history);
      _updateHighlights();
      return;
    }

    // Normal mode --------------------------------------------------------
    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    if (number == cell.solution) {
      // Correct placement
      _board.setCell(
        row,
        col,
        cell.copyWith(
          value: number,
          state: CellState.filled,
          notes: <int>{},
          isConflict: false,
        ),
      );

      final settings = _ref.read(settingsProvider);
      if (settings.autoRemoveNotes) {
        _autoRemoveNotes(row, col, number);
      }

      final history = List<GameMove>.from(state.moveHistory)
        ..add(GameMove(
          row: row,
          col: col,
          previousValue: previousValue,
          newValue: number,
          previousNotes: previousNotes,
          newNotes: <int>{},
        ));

      // Batch all state changes into a single emission.
      final numberDone = _isNumberFullyPlaced(number);
      if (numberDone) _celebrateNumber(number);

      final boardComplete = _board.isBoardComplete();

      state = state.copyWith(
        moveHistory: history,
        clearActiveNumber: numberDone ? true : false,
        status: boardComplete ? GameStatus.completed : null,
        score: boardComplete ? state.calculatedScore : null,
      );
    } else {
      // Wrong placement
      _board.setCell(
        row,
        col,
        cell.copyWith(
          value: number,
          state: CellState.error,
          notes: <int>{},
        ),
      );

      final newMistakes = state.mistakes + 1;

      final history = List<GameMove>.from(state.moveHistory)
        ..add(GameMove(
          row: row,
          col: col,
          previousValue: previousValue,
          newValue: number,
          previousNotes: previousNotes,
          newNotes: <int>{},
        ));

      final settings = _ref.read(settingsProvider);
      final effectiveMax = settings.mistakeLimit == -1 ? 999 : settings.mistakeLimit;

      if (newMistakes >= effectiveMax) {
        state = state.copyWith(
          mistakes: newMistakes,
          status: GameStatus.gameOver,
          moveHistory: history,
        );
      } else {
        state = state.copyWith(
          mistakes: newMistakes,
          moveHistory: history,
        );
      }

      if (settings.highlightConflicts) {
        _checkConflicts(row, col, number);
      }

      _scheduleErrorClear();
    }

    _updateHighlights();
  }

  // -----------------------------------------------------------------------
  // Erase
  // -----------------------------------------------------------------------

  /// Erases the value or notes in the selected cell.
  void erase() {
    if (state.status != GameStatus.inProgress) return;

    void clearActiveNumberSelection() {
      if (state.hasActiveNumber) {
        state = state.copyWith(clearActiveNumber: true);
        _updateHighlights();
      }
    }

    if (!state.hasSelection) {
      clearActiveNumberSelection();
      return;
    }

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    final cell = _board.getCell(row, col);

    if (cell.isGiven) {
      clearActiveNumberSelection();
      return;
    }
    if (cell.isEmpty && !cell.hasNotes) {
      clearActiveNumberSelection();
      return;
    }

    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    _board.setCell(
      row,
      col,
      cell.copyWith(
        value: 0,
        state: CellState.empty,
        notes: <int>{},
        isConflict: false,
      ),
    );

    final history = List<GameMove>.from(state.moveHistory)
      ..add(GameMove(
        row: row,
        col: col,
        previousValue: previousValue,
        newValue: 0,
        previousNotes: previousNotes,
        newNotes: <int>{},
      ));

    state = state.copyWith(moveHistory: history, clearActiveNumber: true);
    _updateHighlights();
  }

  // -----------------------------------------------------------------------
  // Undo
  // -----------------------------------------------------------------------

  /// Undoes the last move from history.
  void undo() {
    if (!state.canUndo) return;
    if (state.status != GameStatus.inProgress) return;

    final history = List<GameMove>.from(state.moveHistory);
    final lastMove = history.removeLast();

    final cell = _board.getCell(lastMove.row, lastMove.col);

    _board.setCell(
      lastMove.row,
      lastMove.col,
      cell.copyWith(
        value: lastMove.previousValue ?? 0,
        state: (lastMove.previousValue ?? 0) == 0
            ? CellState.empty
            : CellState.filled,
        notes: lastMove.previousNotes ?? <int>{},
        isConflict: false,
      ),
    );

    state = state.copyWith(moveHistory: history);
    _updateHighlights();
  }

  // -----------------------------------------------------------------------
  // Notes mode
  // -----------------------------------------------------------------------

  /// Toggles pencil-mark (notes) mode.
  void toggleNotesMode() {
    if (state.status != GameStatus.inProgress) return;
    state = state.copyWith(isNotesMode: !state.isNotesMode);
  }

  /// Clears both the cell selection and the active number.
  void clearSelection() {
    state = state.copyWith(clearActiveNumber: true, clearSelection: true);
    _updateHighlights();
  }

  // -----------------------------------------------------------------------
  // Hint
  // -----------------------------------------------------------------------

  /// Reveals the correct value for the currently selected cell.
  void useHint() {
    if (!state.hasSelection) return;
    if (!state.canUseHint) return;
    if (state.status != GameStatus.inProgress) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    final cell = _board.getCell(row, col);

    // Don't waste a hint on a given or already-correct cell
    if (cell.isGiven) return;
    if (cell.value == cell.solution) return;

    final previousValue = cell.value;
    final previousNotes = Set<int>.from(cell.notes);

    _board.setCell(
      row,
      col,
      cell.copyWith(
        value: cell.solution,
        state: CellState.filled,
        notes: <int>{},
        isConflict: false,
      ),
    );

    final settings = _ref.read(settingsProvider);
    if (settings.autoRemoveNotes) {
      _autoRemoveNotes(row, col, cell.solution);
    }

    final history = List<GameMove>.from(state.moveHistory)
      ..add(GameMove(
        row: row,
        col: col,
        previousValue: previousValue,
        newValue: cell.solution,
        previousNotes: previousNotes,
        newNotes: <int>{},
      ));

    state = state.copyWith(
      hintsUsed: state.hintsUsed + 1,
      moveHistory: history,
      clearActiveNumber: _isNumberFullyPlaced(cell.solution) ? true : false,
      status: _board.isBoardComplete() ? GameStatus.completed : null,
      score: _board.isBoardComplete() ? state.calculatedScore : null,
    );

    if (_isNumberFullyPlaced(cell.solution)) {
      _celebrateNumber(cell.solution);
    }

    _updateHighlights();
  }

  // -----------------------------------------------------------------------
  // Timer
  // -----------------------------------------------------------------------

  /// Called every second to increment the elapsed time.
  void tick() {
    if (state.status != GameStatus.inProgress) return;
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
  }

  // -----------------------------------------------------------------------
  // Pause / resume
  // -----------------------------------------------------------------------

  void pauseGame() {
    if (state.status != GameStatus.inProgress) return;
    state = state.copyWith(status: GameStatus.paused);
  }

  void resumeGame() {
    if (state.status != GameStatus.paused) return;
    state = state.copyWith(status: GameStatus.inProgress);
  }

  // -----------------------------------------------------------------------
  // Internal helpers
  // -----------------------------------------------------------------------

  /// Updates highlighting for every cell based on the current selection
  /// or active number. Mutates cells in-place to avoid unnecessary object
  /// allocation – the UI rebuild is driven by the [state] change, not by
  /// cell identity.
  void _updateHighlights() {
    final settings = _ref.read(settingsProvider);
    final hasSelection = state.hasSelection;
    final selRow = state.selectedRow;
    final selCol = state.selectedCol;
    final selectedValue =
        hasSelection ? _board.getCell(selRow!, selCol!).value : 0;
    final selBox = hasSelection ? _board.getCell(selRow!, selCol!).box : -1;
    final activeNum = state.activeNumber;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _board.getCell(r, c);

        final isSelected = hasSelection && r == selRow && c == selCol;

        final isHighlighted = hasSelection &&
            !isSelected &&
            (r == selRow || c == selCol || cell.box == selBox);

        bool isSameValue = false;
        if (activeNum != null && !hasSelection) {
          isSameValue = cell.value == activeNum && cell.value != 0;
        } else if (settings.highlightIdentical &&
            hasSelection &&
            selectedValue != 0) {
          isSameValue =
              cell.value == selectedValue && !(r == selRow && c == selCol);
        }

        // Only allocate a new cell if something actually changed.
        if (cell.isSelected != isSelected ||
            cell.isHighlighted != isHighlighted ||
            cell.isSameValue != isSameValue) {
          _board.setCell(
            r,
            c,
            cell.copyWith(
              isSelected: isSelected,
              isHighlighted: isHighlighted,
              isSameValue: isSameValue,
            ),
          );
        }
      }
    }
  }

  /// Marks cells that conflict with [value] at ([row], [col]).
  void _checkConflicts(int row, int col, int value) {
    // Clear previous conflicts
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _board.getCell(r, c);
        if (cell.isConflict) {
          _board.setCell(r, c, cell.copyWith(isConflict: false));
        }
      }
    }

    if (value == 0) return;

    void markIfConflict(int r, int c) {
      if (r == row && c == col) return;
      final cell = _board.getCell(r, c);
      if (cell.value == value) {
        _board.setCell(r, c, cell.copyWith(isConflict: true));
      }
    }

    // Check row
    for (int c = 0; c < 9; c++) {
      markIfConflict(row, c);
    }
    // Check column
    for (int r = 0; r < 9; r++) {
      markIfConflict(r, col);
    }
    // Check 3×3 box (skip cells already visited in row/col)
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      if (r == row) continue;
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (c == col) continue;
        markIfConflict(r, c);
      }
    }
  }

  /// Schedules automatic clearing of error / conflict highlighting.
  void _scheduleErrorClear() {
    _errorClearTimer?.cancel();
    _errorClearTimer = Timer(const Duration(seconds: 2), () {
      _clearErrors();
    });
  }

  /// Clears all conflict flags on the board (keeps error state on the
  /// wrongly placed cell itself so the user remembers to erase it).
  void _clearErrors() {
    bool changed = false;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _board.getCell(r, c);
        if (cell.isConflict) {
          _board.setCell(r, c, cell.copyWith(isConflict: false));
          changed = true;
        }
      }
    }
    if (changed) {
      // Trigger UI rebuild via boardVersion bump.
      state = state.copyWith(boardVersion: state.boardVersion + 1);
    }
  }

  /// Returns `true` if placing [number] at ([row], [col]) would visibly
  /// conflict with an existing number in the same row, column, or 3×3 box.
  bool _hasVisibleConflict(int row, int col, int number) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (c != col && _board.getCell(row, c).value == number) return true;
    }
    // Check column
    for (int r = 0; r < 9; r++) {
      if (r != row && _board.getCell(r, col).value == number) return true;
    }
    // Check 3×3 box
    final bRow = (row ~/ 3) * 3;
    final bCol = (col ~/ 3) * 3;
    for (int r = bRow; r < bRow + 3; r++) {
      for (int c = bCol; c < bCol + 3; c++) {
        if ((r != row || c != col) && _board.getCell(r, c).value == number) {
          return true;
        }
      }
    }
    return false;
  }

  /// Shows visual feedback when a placement is rejected due to a visible
  /// conflict: marks conflicting cells and the selected cell with
  /// [isConflict] so the UI can shake / highlight them briefly.
  void _showRejectionFeedback(int row, int col, int number) {
    _checkConflicts(row, col, number);

    // Also mark the selected cell itself so the cell widget can shake it.
    final cell = _board.getCell(row, col);
    _board.setCell(row, col, cell.copyWith(isConflict: true));

    _scheduleErrorClear();

    // Trigger UI rebuild via boardVersion bump.
    state = state.copyWith(boardVersion: state.boardVersion + 1);
  }

  /// Returns `true` if all 9 instances of [number] are correctly placed.
  bool _isNumberFullyPlaced(int number) {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _board.getCell(r, c);
        if (cell.value == number && cell.isCorrect) count++;
      }
    }
    return count >= 9;
  }

  /// Marks all cells containing [number] as celebrating and schedules
  /// clearing the flag after a short delay.
  void _celebrateNumber(int number) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _board.getCell(r, c);
        if (cell.value == number && cell.isCorrect) {
          _board.setCell(r, c, cell.copyWith(isCelebrating: true));
        }
      }
    }
    _scheduleCelebrationClear();
  }

  Timer? _celebrationClearTimer;

  /// Clears celebration flags after a brief delay.
  void _scheduleCelebrationClear() {
    _celebrationClearTimer?.cancel();
    _celebrationClearTimer = Timer(const Duration(milliseconds: 800), () {
      bool changed = false;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          final cell = _board.getCell(r, c);
          if (cell.isCelebrating) {
            _board.setCell(r, c, cell.copyWith(isCelebrating: false));
            changed = true;
          }
        }
      }
      if (changed) state = state.copyWith(boardVersion: state.boardVersion + 1);
    });
  }

  /// Removes [value] from notes in the same row, column, and box as
  /// ([row], [col]).
  void _autoRemoveNotes(int row, int col, int value) {
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (r == row && c == col) continue;

        final sameRow = r == row;
        final sameCol = c == col;
        final sameBox = r >= boxRow &&
            r < boxRow + 3 &&
            c >= boxCol &&
            c < boxCol + 3;

        if (sameRow || sameCol || sameBox) {
          final cell = _board.getCell(r, c);
          if (cell.notes.contains(value)) {
            final updatedNotes = Set<int>.from(cell.notes)..remove(value);
            _board.setCell(r, c, cell.copyWith(notes: updatedNotes));
          }
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Primary game state provider.
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});

/// Provides only the elapsed seconds, so that widgets that only care about
/// time (e.g. GameTimer) can watch this instead of the full [gameProvider]
/// and avoid triggering unrelated rebuilds.
final elapsedSecondsProvider = Provider<int>((ref) {
  return ref.watch(gameProvider.select((s) => s.elapsedSeconds));
});

/// Exposes the current [SudokuBoard] reactively. Uses selective watchers
/// so that timer ticks do not trigger unnecessary re-evaluations.
final boardProvider = Provider<SudokuBoard>((ref) {
  // Re-evaluate when board-affecting state changes.
  ref.watch(gameProvider.select((s) => s.moveHistory.length));
  ref.watch(gameProvider.select((s) => s.hintsUsed));
  ref.watch(gameProvider.select((s) => s.gameId));
  ref.watch(gameProvider.select((s) => s.selectedRow));
  ref.watch(gameProvider.select((s) => s.selectedCol));
  ref.watch(gameProvider.select((s) => s.activeNumber));
  ref.watch(gameProvider.select((s) => s.mistakes));
  ref.watch(gameProvider.select((s) => s.boardVersion));
  return ref.read(gameProvider.notifier).board;
});

/// Provides a map of number → remaining count for digits 1-9.
/// A number is "remaining" if it has not yet been correctly placed in all
/// nine positions on the board.
final remainingCountProvider = Provider<Map<int, int>>((ref) {
  // Only re-evaluate when moves change, hints are used, or a new game starts.
  // Watching the full gameProvider would re-evaluate on every timer tick.
  ref.watch(gameProvider.select((s) => s.moveHistory.length));
  ref.watch(gameProvider.select((s) => s.hintsUsed));
  ref.watch(gameProvider.select((s) => s.gameId));
  final board = ref.read(gameProvider.notifier).board;

  // Single-pass O(81) instead of O(9×81).
  final counts = <int, int>{
    for (int n = 1; n <= 9; n++) n: 9,
  };
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      final cell = board.getCell(r, c);
      if (cell.value != 0 && cell.isCorrect) {
        counts[cell.value] = counts[cell.value]! - 1;
      }
    }
  }

  return counts;
});
