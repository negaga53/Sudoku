import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/models/sudoku_board.dart';
import 'package:sudoku_app/providers/game_provider.dart';
import 'package:sudoku_app/providers/multiplayer_provider.dart';
import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/widgets/animated_background.dart';
import 'package:sudoku_app/widgets/game_controls.dart';
import 'package:sudoku_app/widgets/game_timer.dart';
import 'package:sudoku_app/widgets/multiplayer_completion_dialog.dart';
import 'package:sudoku_app/widgets/number_pad.dart';
import 'package:sudoku_app/widgets/score_display.dart';
import 'package:sudoku_app/widgets/sudoku_grid.dart';

/// Multiplayer game screen — identical gameplay to single-player but with
/// opponent event handling and a different completion dialog.
class MultiplayerGameScreen extends ConsumerStatefulWidget {
  const MultiplayerGameScreen({super.key});

  @override
  ConsumerState<MultiplayerGameScreen> createState() =>
      _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends ConsumerState<MultiplayerGameScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _showCompletion = false;
  bool _sentResult = false;

  /// Tracks whether the opponent finished before us.
  bool _opponentFinishedFirst = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    // Initialize the board from the multiplayer puzzle data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });

    // Listen for game completion
    ref.listenManual(
      gameProvider.select((s) => s.status),
      (prev, next) {
        if (next == GameStatus.completed || next == GameStatus.gameOver) {
          _handleLocalCompletion(next);
        }
      },
    );

    // Listen for opponent events
    ref.listenManual(
      multiplayerProvider,
      (prev, next) {
        // Handle rematch: a new game_start resets the screen
        if (next.status == MultiplayerStatus.inGame &&
            prev?.status != MultiplayerStatus.inGame &&
            _showCompletion) {
          _handleRematchStart();
          return;
        }

        if (!_showCompletion) {
          if (next.opponentCompleted && !(prev?.opponentCompleted ?? false)) {
            _handleOpponentCompleted();
          }
          if (next.opponentGameOver && !(prev?.opponentGameOver ?? false)) {
            // Opponent lost — doesn't end our game, just info
          }
          if (next.opponentLeft && !(prev?.opponentLeft ?? false)) {
            _handleOpponentLeft();
          }
        }
      },
    );
  }

  void _initializeGame() {
    final mp = ref.read(multiplayerProvider);
    if (mp.puzzle == null || mp.solution == null) return;

    // Map difficulty string to enum
    Difficulty difficulty;
    switch (mp.difficulty) {
      case 'medium':
        difficulty = Difficulty.medium;
      case 'hard':
        difficulty = Difficulty.hard;
      case 'expert':
        difficulty = Difficulty.expert;
      default:
        difficulty = Difficulty.easy;
    }

    // Use the game provider's special initializer for multiplayer
    ref.read(gameProvider.notifier).startMultiplayerGame(
          difficulty: difficulty,
          puzzle: mp.puzzle!,
          solution: mp.solution!,
        );
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseGame();
    } else if (state == AppLifecycleState.resumed) {
      final gs = ref.read(gameProvider);
      if (gs.status == GameStatus.paused) {
        _resumeGame();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gs = ref.read(gameProvider);
      if (gs.status == GameStatus.inProgress) {
        ref.read(gameProvider.notifier).tick();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _pauseGame() {
    ref.read(gameProvider.notifier).pauseGame();
    _stopTimer();
  }

  void _resumeGame() {
    ref.read(gameProvider.notifier).resumeGame();
    _startTimer();
  }

  // --- Completion handling ---

  void _handleLocalCompletion(GameStatus status) {
    if (_showCompletion) return;
    _stopTimer();

    final gs = ref.read(gameProvider);

    if (!_sentResult) {
      _sentResult = true;
      if (status == GameStatus.completed) {
        ref.read(multiplayerProvider.notifier).notifyCompleted(
              score: gs.calculatedScore,
              time: gs.elapsedSeconds,
            );
      } else if (status == GameStatus.gameOver) {
        ref.read(multiplayerProvider.notifier).notifyGameOver();
      }
    }

    setState(() => _showCompletion = true);
  }

  void _handleOpponentCompleted() {
    // Opponent finished the puzzle first
    _opponentFinishedFirst = true;
    // Don't stop the game — let the player keep playing.
    // Show result when they finish or via a notification.
    // If our game is still running, the completion dialog will show
    // "opponent finished first" info when we also complete.

    // If the game is still in progress, force show completion
    final gs = ref.read(gameProvider);
    if (gs.status == GameStatus.inProgress || gs.status == GameStatus.paused) {
      _stopTimer();
      setState(() => _showCompletion = true);
    }
  }

  void _handleOpponentLeft() {
    if (_showCompletion) return;
    _stopTimer();
    setState(() => _showCompletion = true);
  }

  void _handleRematchStart() {
    setState(() {
      _showCompletion = false;
      _sentResult = false;
      _opponentFinishedFirst = false;
    });
    _initializeGame();
  }

  void _exitGame() {
    ref.read(multiplayerProvider.notifier).leaveGame();
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(gameProvider.select((s) => (
          status: s.status,
          activeNumber: s.activeNumber,
          selectedRow: s.selectedRow,
          selectedCol: s.selectedCol,
          isNotesMode: s.isNotesMode,
          difficulty: s.difficulty,
          hintsRemaining: s.maxHints - s.hintsUsed,
          canUndo: s.canUndo,
          hasSelection: s.hasSelection,
          hasActiveNumber: s.hasActiveNumber,
        )));

    final board = ref.watch(boardProvider);
    final remainingCounts = ref.watch(remainingCountProvider);
    final gameNotifier = ref.read(gameProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final mp = ref.watch(multiplayerProvider);

    int? activeNumber = ui.activeNumber;
    if (activeNumber == null && ui.hasSelection) {
      final cell = board.getCell(ui.selectedRow!, ui.selectedCol!);
      if (cell.value != 0) activeNumber = cell.value;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitGame();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: _exitGame,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              const SizedBox(width: 6),
              Text(
                l10n.difficultyName(ui.difficulty.name),
                style: AppTextStyles.heading3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          actions: [
            const GameTimer(),
            const SizedBox(width: 12),
          ],
        ),
        body: AnimatedBackground(
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 4),
                    const ScoreDisplay(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SudokuGrid(
                        board: board,
                        onCellTap: (row, col) =>
                            gameNotifier.selectCell(row, col),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GameControls(
                      onUndo: gameNotifier.undo,
                      onErase: gameNotifier.erase,
                      onToggleNotes: gameNotifier.toggleNotesMode,
                      onHint: gameNotifier.useHint,
                      isNotesMode: ui.isNotesMode,
                      hintsRemaining: ui.hintsRemaining,
                      canUndo: ui.canUndo,
                      undoLabel: l10n.undo,
                      eraseLabel: l10n.erase,
                      notesLabel: l10n.notes,
                      hintLabel: l10n.hint,
                    ),
                    const SizedBox(height: 16),
                    NumberPad(
                      onNumberTap: gameNotifier.handleNumberPadTap,
                      remainingCounts: remainingCounts,
                      activeNumber: activeNumber,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                if (_showCompletion)
                  Positioned.fill(
                    child: Builder(builder: (context) {
                      final gs = ref.read(gameProvider);
                      return MultiplayerCompletionDialog(
                        localStatus: gs.status,
                        localScore: gs.calculatedScore,
                        elapsedSeconds: gs.elapsedSeconds,
                        difficulty: gs.difficulty,
                        mistakes: gs.mistakes,
                        maxMistakes: gs.maxMistakes,
                        opponentFinishedFirst: _opponentFinishedFirst,
                        opponentLeft: mp.opponentLeft,
                        opponentScore: mp.opponentScore,
                        opponentTime: mp.opponentTime,
                        waitingForRematch: mp.waitingForRematch,
                        onRetry: () {
                          ref
                              .read(multiplayerProvider.notifier)
                              .requestRematch();
                        },
                        onGoHome: () {
                          ref
                              .read(multiplayerProvider.notifier)
                              .disconnect();
                          if (context.mounted) {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          }
                        },
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
