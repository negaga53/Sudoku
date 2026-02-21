import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/providers/game_provider.dart';
import 'package:sudoku_app/providers/statistics_provider.dart';
import 'package:sudoku_app/theme/app_colors.dart';
import 'package:sudoku_app/theme/app_text_styles.dart';
import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/widgets/animated_background.dart';
import 'package:sudoku_app/widgets/completion_dialog.dart';
import 'package:sudoku_app/widgets/game_controls.dart';
import 'package:sudoku_app/widgets/game_timer.dart';
import 'package:sudoku_app/widgets/number_pad.dart';
import 'package:sudoku_app/widgets/score_display.dart';
import 'package:sudoku_app/widgets/sudoku_grid.dart';

/// The main gameplay screen.
///
/// Owns a periodic [Timer] that calls [GameNotifier.tick] every second while
/// the game is in progress, and automatically pauses/disposes it.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _showCompletion = false;
  bool _userPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _startTimer();

    // If resuming a saved/paused game (e.g. from Continue), transition
    // back to inProgress so the board is interactive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = ref.read(gameProvider);
      if (gameState.status == GameStatus.paused) {
        ref.read(gameProvider.notifier).resumeGame();
      }
    });

    // Listen for game completion/game-over to show the completion dialog.
    ref.listenManual(
      gameProvider.select((s) => s.status),
      (prev, next) {
        if (next == GameStatus.completed || next == GameStatus.gameOver) {
          _checkCompletion(next);
        }
      },
    );
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
    // Pause when app goes to background.
    if (state == AppLifecycleState.paused) {
      _pauseGame();
    } else if (state == AppLifecycleState.resumed) {
      // Resume when app returns to foreground, unless the user explicitly
      // pressed the pause button (which shows a dismiss-able overlay).
      final gameState = ref.read(gameProvider);
      if (gameState.status == GameStatus.paused && !_userPaused) {
        _resumeGame();
      }
    }
  }

  // --- Timer management ---

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gameState = ref.read(gameProvider);
      if (gameState.status == GameStatus.inProgress) {
        ref.read(gameProvider.notifier).tick();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _pauseGame() {
    final notifier = ref.read(gameProvider.notifier);
    notifier.pauseGame();
    _stopTimer();
  }

  void _resumeGame() {
    _userPaused = false;
    final notifier = ref.read(gameProvider.notifier);
    notifier.resumeGame();
    _startTimer();
  }

  // --- Navigation helpers ---

  void _exitGame() {
    // Game is auto-saved, so just pause and pop.
    final gameState = ref.read(gameProvider);
    if (gameState.status == GameStatus.inProgress) {
      ref.read(gameProvider.notifier).pauseGame();
    }
    _stopTimer();
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _handlePause() {
    final gameState = ref.read(gameProvider);
    if (gameState.status == GameStatus.inProgress) {
      _userPaused = true;
      _pauseGame();
      _showPauseOverlay();
    }
  }

  void _showPauseOverlay() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause_circle_filled_rounded,
                  size: 72,
                  color: isDark ? Colors.white70 : Colors.black54),
              const SizedBox(height: 16),
              Text(
                l10n.paused,
                style: AppTextStyles.heading2.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _resumeGame();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.resume),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Completion handling ---

  void _checkCompletion(GameStatus status) {
    if (_showCompletion) return;

    if (status == GameStatus.completed || status == GameStatus.gameOver) {
      _stopTimer();

      // Record statistics
      final gameState = ref.read(gameProvider);
      final statsNotifier = ref.read(statisticsProvider.notifier);
      statsNotifier.recordGameCompleted(
        gameState.difficulty,
        gameState.elapsedSeconds,
        gameState.calculatedScore,
        status == GameStatus.completed,
      );

      setState(() => _showCompletion = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the fields the build method needs — NOT elapsedSeconds.
    // The GameTimer and ScoreDisplay widgets handle their own subscriptions.
    // Using a record selector: records have value equality, so timer ticks
    // (which only change elapsedSeconds) will NOT trigger a rebuild.
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

    // Safety: if the game is paused but we're actively building (app is
    // visible) and it's not a user-initiated pause, auto-resume so the
    // game doesn't get stuck in an unresponsive state.
    if (ui.status == GameStatus.paused && !_userPaused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resumeGame();
      });
    }

    // Active number for highlighting in the number pad.
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
          title: Text(
            l10n.difficultyName(ui.difficulty.name),
            style: AppTextStyles.heading3.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          actions: [
            const GameTimer(),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.pause_rounded),
              onPressed: _handlePause,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: AnimatedBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // --- Main content ---
                Column(
                  children: [
                    const SizedBox(height: 4),
                    const ScoreDisplay(),
                    const SizedBox(height: 8),

                    // Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SudokuGrid(
                        board: board,
                        onCellTap: (row, col) => gameNotifier.selectCell(row, col),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Controls
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

                    // Number pad
                    NumberPad(
                      onNumberTap: gameNotifier.handleNumberPadTap,
                      remainingCounts: remainingCounts,
                      activeNumber: activeNumber,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

                // --- Completion overlay ---
                if (_showCompletion)
                  Positioned.fill(
                    child: Builder(builder: (context) {
                      // Read full state once for the dialog.
                      final gs = ref.read(gameProvider);
                      return CompletionDialog(
                        status: gs.status,
                        score: gs.calculatedScore,
                        elapsedSeconds: gs.elapsedSeconds,
                        difficulty: gs.difficulty,
                        mistakes: gs.mistakes,
                        maxMistakes: gs.maxMistakes,
                        onPlayAgain: () {
                          setState(() => _showCompletion = false);
                          gameNotifier.startNewGame(ui.difficulty);
                          _startTimer();
                        },
                        onGoHome: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
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
