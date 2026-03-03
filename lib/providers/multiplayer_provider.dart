import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sudoku_app/models/multiplayer_game.dart';
import 'package:sudoku_app/services/multiplayer_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum MultiplayerStatus {
  disconnected,
  connecting,
  connected,
  waitingForPlayer,
  inGame,
}

class MultiplayerState {
  final MultiplayerStatus status;
  final String? gameId;
  final String? errorMessage;
  final List<MultiplayerGame> availableGames;
  final List<List<int>>? puzzle;
  final List<List<int>>? solution;
  final String? difficulty;

  /// Opponent result when they finish first.
  final int? opponentScore;
  final int? opponentTime;

  /// Flags set when the opponent finishes or leaves.
  final bool opponentCompleted;
  final bool opponentGameOver;
  final bool opponentLeft;
  final bool waitingForRematch;

  MultiplayerState({
    this.status = MultiplayerStatus.disconnected,
    this.gameId,
    this.errorMessage,
    this.availableGames = const [],
    this.puzzle,
    this.solution,
    this.difficulty,
    this.opponentScore,
    this.opponentTime,
    this.opponentCompleted = false,
    this.opponentGameOver = false,
    this.opponentLeft = false,
    this.waitingForRematch = false,
  });

  MultiplayerState copyWith({
    MultiplayerStatus? status,
    String? gameId,
    String? errorMessage,
    List<MultiplayerGame>? availableGames,
    List<List<int>>? puzzle,
    List<List<int>>? solution,
    String? difficulty,
    int? opponentScore,
    int? opponentTime,
    bool? opponentCompleted,
    bool? opponentGameOver,
    bool? opponentLeft,
    bool? waitingForRematch,
    bool clearError = false,
    bool clearGameId = false,
  }) {
    return MultiplayerState(
      status: status ?? this.status,
      gameId: clearGameId ? null : (gameId ?? this.gameId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      availableGames: availableGames ?? this.availableGames,
      puzzle: puzzle ?? this.puzzle,
      solution: solution ?? this.solution,
      difficulty: difficulty ?? this.difficulty,
      opponentScore: opponentScore ?? this.opponentScore,
      opponentTime: opponentTime ?? this.opponentTime,
      opponentCompleted: opponentCompleted ?? this.opponentCompleted,
      opponentGameOver: opponentGameOver ?? this.opponentGameOver,
      opponentLeft: opponentLeft ?? this.opponentLeft,
      waitingForRematch: waitingForRematch ?? this.waitingForRematch,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class MultiplayerNotifier extends StateNotifier<MultiplayerState> {
  final MultiplayerService _service = MultiplayerService();
  StreamSubscription? _eventSub;

  MultiplayerNotifier() : super(MultiplayerState());

  @override
  void dispose() {
    _eventSub?.cancel();
    _service.dispose();
    super.dispose();
  }

  // ---- Connection ----

  Future<void> connect() async {
    if (state.status != MultiplayerStatus.disconnected) return;
    state = state.copyWith(status: MultiplayerStatus.connecting, clearError: true);

    try {
      await _service.connect();
      state = state.copyWith(status: MultiplayerStatus.connected);
      _listenToEvents();
    } catch (e) {
      print('[MultiplayerNotifier] Connection error: $e');
      state = state.copyWith(
        status: MultiplayerStatus.disconnected,
        errorMessage: e.toString(),
      );
    }
  }

  void disconnect() {
    _eventSub?.cancel();
    _service.disconnect();
    state = MultiplayerState();
  }

  void _listenToEvents() {
    _eventSub?.cancel();
    _eventSub = _service.events.listen(_handleEvent);
  }

  void _handleEvent(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'game_created':
        state = state.copyWith(
          status: MultiplayerStatus.waitingForPlayer,
          gameId: msg['gameId'] as String?,
        );

      case 'game_list':
        final games = MultiplayerService.parseGameList(msg);
        state = state.copyWith(availableGames: games);

      case 'game_start':
        final puzzle = (msg['puzzle'] as List<dynamic>)
            .map((row) => (row as List<dynamic>).map((v) => v as int).toList())
            .toList();
        final solution = (msg['solution'] as List<dynamic>)
            .map((row) => (row as List<dynamic>).map((v) => v as int).toList())
            .toList();
        state = MultiplayerState(
          status: MultiplayerStatus.inGame,
          puzzle: puzzle,
          solution: solution,
          difficulty: msg['difficulty'] as String?,
          gameId: msg['gameId'] as String?,
        );

      case 'opponent_completed':
        state = state.copyWith(
          opponentCompleted: true,
          opponentScore: msg['score'] as int?,
          opponentTime: msg['time'] as int?,
        );

      case 'opponent_game_over':
        state = state.copyWith(opponentGameOver: true);

      case 'opponent_left':
        state = state.copyWith(opponentLeft: true);

      case 'rematch_waiting':
        state = state.copyWith(waitingForRematch: true);

      case 'error':
        state = state.copyWith(errorMessage: msg['message'] as String?);

      case 'disconnected':
        state = MultiplayerState();
    }
  }

  // ---- Actions ----

  void createGame({required String mode, required String difficulty}) {
    _service.createGame(mode: mode, difficulty: difficulty);
  }

  void listGames({required String mode}) {
    _service.listGames(mode: mode);
  }

  void joinGame({required String gameId}) {
    _service.joinGame(gameId: gameId);
  }

  void notifyCompleted({required int score, required int time}) {
    if (state.gameId != null) {
      _service.notifyCompleted(
        gameId: state.gameId!,
        score: score,
        time: time,
      );
    }
  }

  void notifyGameOver() {
    if (state.gameId != null) {
      _service.notifyGameOver(gameId: state.gameId!);
    }
  }

  void leaveGame() {
    if (state.gameId != null) {
      _service.leaveGame(gameId: state.gameId!);
    }
    state = state.copyWith(
      status: MultiplayerStatus.connected,
      clearGameId: true,
    );
  }

  void requestRematch() {
    if (state.gameId != null) {
      _service.requestRematch(gameId: state.gameId!);
    }
  }

  /// Resets the state back to connected (after a game ends).
  void resetToConnected() {
    state = MultiplayerState(status: MultiplayerStatus.connected);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final multiplayerProvider =
    StateNotifierProvider<MultiplayerNotifier, MultiplayerState>(
  (ref) => MultiplayerNotifier(),
);
