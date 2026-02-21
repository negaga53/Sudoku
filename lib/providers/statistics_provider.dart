import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/models/settings.dart';
import 'package:sudoku_app/services/storage_service.dart';

// ---------------------------------------------------------------------------
// Statistics notifier
// ---------------------------------------------------------------------------

class StatisticsNotifier extends StateNotifier<GameStatistics> {
  StatisticsNotifier() : super(StorageService.loadStatistics());

  /// Records the result of a completed (or lost) game and updates all
  /// cumulative statistics.
  void recordGameCompleted(
    Difficulty difficulty,
    int timeSeconds,
    int score,
    bool won,
  ) {
    final diffKey = difficulty.name;

    // Per-difficulty counters
    final gamesPerDiff = Map<String, int>.from(state.gamesPerDifficulty);
    gamesPerDiff[diffKey] = (gamesPerDiff[diffKey] ?? 0) + 1;

    final winsPerDiff = Map<String, int>.from(state.winsPerDifficulty);

    // Best / total times (tracked only for wins)
    final bestTimes = Map<String, int>.from(state.bestTimes);
    final totalTimes = Map<String, int>.from(state.totalTimes);

    int newStreak = state.currentStreak;
    int newBestStreak = state.bestStreak;
    int newGamesWon = state.gamesWon;
    int newHighScore = state.highScore;

    if (won) {
      newGamesWon++;
      winsPerDiff[diffKey] = (winsPerDiff[diffKey] ?? 0) + 1;

      // Update best time
      final prevBest = bestTimes[diffKey];
      if (prevBest == null || timeSeconds < prevBest) {
        bestTimes[diffKey] = timeSeconds;
      }

      // Accumulate total time for average calculation
      totalTimes[diffKey] = (totalTimes[diffKey] ?? 0) + timeSeconds;

      // Streak
      newStreak++;
      newBestStreak = max(newBestStreak, newStreak);

      // High score
      if (score > newHighScore) {
        newHighScore = score;
      }
    } else {
      // Loss breaks the streak
      newStreak = 0;
    }

    state = state.copyWith(
      gamesPlayed: state.gamesPlayed + 1,
      gamesWon: newGamesWon,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      bestTimes: bestTimes,
      totalTimes: totalTimes,
      gamesPerDifficulty: gamesPerDiff,
      winsPerDifficulty: winsPerDiff,
      highScore: newHighScore,
    );

    StorageService.saveStatistics(state);
  }

  /// Loads statistics from persistent storage.
  void loadStatistics() {
    state = StorageService.loadStatistics();
  }

  /// Persists current statistics to storage.
  void saveStatistics() {
    StorageService.saveStatistics(state);
  }

  /// Resets all statistics to their initial values.
  void resetStatistics() {
    state = GameStatistics();
    saveStatistics();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, GameStatistics>((ref) {
  return StatisticsNotifier();
});
