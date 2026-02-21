enum Difficulty { easy, medium, hard, expert }
enum GameStatus { notStarted, inProgress, paused, completed, gameOver }

extension DifficultyExtension on Difficulty {
  String get name {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  double get scoreMultiplier {
    switch (this) {
      case Difficulty.easy:
        return 1.0;
      case Difficulty.medium:
        return 1.5;
      case Difficulty.hard:
        return 2.0;
      case Difficulty.expert:
        return 3.0;
    }
  }

  int get clueRange {
    switch (this) {
      case Difficulty.easy:
        return 38;
      case Difficulty.medium:
        return 30;
      case Difficulty.hard:
        return 25;
      case Difficulty.expert:
        return 17;
    }
  }

  int get maxClues {
    switch (this) {
      case Difficulty.easy:
        return 45;
      case Difficulty.medium:
        return 37;
      case Difficulty.hard:
        return 29;
      case Difficulty.expert:
        return 24;
    }
  }
}

class GameMove {
  final int row;
  final int col;
  final int? previousValue;
  final int? newValue;
  final Set<int>? previousNotes;
  final Set<int>? newNotes;
  final bool wasNotesMode;

  GameMove({
    required this.row,
    required this.col,
    this.previousValue,
    this.newValue,
    this.previousNotes,
    this.newNotes,
    this.wasNotesMode = false,
  });
}

class GameState {
  final Difficulty difficulty;
  final GameStatus status;
  final int mistakes;
  final int maxMistakes;
  final int hintsUsed;
  final int maxHints;
  final int score;
  final int elapsedSeconds;
  final bool isNotesMode;
  final int? selectedRow;
  final int? selectedCol;
  final int? activeNumber; // Number-first mode: pre-selected number from pad
  final List<GameMove> moveHistory;
  final String? gameId;
  final int boardVersion; // Incremented on asynchronous board mutations

  static const int baseScore = 10000;
  static const int mistakePenalty = 100;
  static const int hintPenalty = 150;
  static const int timePenaltyPerSecond = 1;

  GameState({
    this.difficulty = Difficulty.easy,
    this.status = GameStatus.notStarted,
    this.mistakes = 0,
    this.maxMistakes = 3,
    this.hintsUsed = 0,
    this.maxHints = 3,
    this.score = 0,
    this.elapsedSeconds = 0,
    this.isNotesMode = false,
    this.selectedRow,
    this.selectedCol,
    this.activeNumber,
    List<GameMove>? moveHistory,
    this.gameId,
    this.boardVersion = 0,
  }) : moveHistory = moveHistory ?? [];

  int get calculatedScore {
    int raw = baseScore -
        (elapsedSeconds * timePenaltyPerSecond) -
        (mistakes * mistakePenalty) -
        (hintsUsed * hintPenalty);
    return (raw.clamp(0, baseScore) * difficulty.scoreMultiplier).round();
  }

  bool get isGameOver => mistakes >= maxMistakes;
  bool get hasSelection => selectedRow != null && selectedCol != null;
  bool get hasActiveNumber => activeNumber != null;
  bool get canUndo => moveHistory.isNotEmpty;
  bool get canUseHint => hintsUsed < maxHints;

  GameState copyWith({
    Difficulty? difficulty,
    GameStatus? status,
    int? mistakes,
    int? maxMistakes,
    int? hintsUsed,
    int? maxHints,
    int? score,
    int? elapsedSeconds,
    bool? isNotesMode,
    int? selectedRow,
    int? selectedCol,
    int? activeNumber,
    List<GameMove>? moveHistory,
    String? gameId,
    int? boardVersion,
    bool clearSelection = false,
    bool clearActiveNumber = false,
  }) {
    return GameState(
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      mistakes: mistakes ?? this.mistakes,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      maxHints: maxHints ?? this.maxHints,
      score: score ?? this.score,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isNotesMode: isNotesMode ?? this.isNotesMode,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      activeNumber: clearActiveNumber ? null : (activeNumber ?? this.activeNumber),
      moveHistory: moveHistory ?? this.moveHistory,
      gameId: gameId ?? this.gameId,
      boardVersion: boardVersion ?? this.boardVersion,
    );
  }
}
