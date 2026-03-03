import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sudoku_app/models/multiplayer_game.dart';

/// WebSocket client for the Sudoku multiplayer server.
///
/// Change [defaultUrl] to your server's LAN IP when testing on a device.
class MultiplayerService {
  static const String defaultUrl = 'ws://192.168.1.156:8080';

  WebSocket? _socket;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of all incoming server events.
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isConnected => _socket != null;

  /// Connects to the multiplayer server.
  Future<void> connect({String url = defaultUrl}) async {
    if (_socket != null) return;

    print('[MultiplayerService] Connecting to $url ...');

    _socket = await WebSocket.connect(url)
        .timeout(const Duration(seconds: 5));

    print('[MultiplayerService] Connected!');

    _socket!.listen(
      (data) {
        if (data is String) {
          try {
            final msg = jsonDecode(data) as Map<String, dynamic>;
            _eventController.add(msg);
          } catch (_) {}
        }
      },
      onDone: () {
        _socket = null;
        _eventController.add({'type': 'disconnected'});
      },
      onError: (error) {
        _eventController.add({'type': 'error', 'message': error.toString()});
      },
    );
  }

  /// Disconnects from the server.
  void disconnect() {
    _socket?.close();
    _socket = null;
  }

  void _send(Map<String, dynamic> message) {
    _socket?.add(jsonEncode(message));
  }

  /// Creates a new game room.
  void createGame({required String mode, required String difficulty}) {
    _send({
      'type': 'create_game',
      'mode': mode,
      'difficulty': difficulty,
    });
  }

  /// Requests the list of available games for a mode.
  void listGames({required String mode}) {
    _send({
      'type': 'list_games',
      'mode': mode,
    });
  }

  /// Joins an existing game.
  void joinGame({required String gameId}) {
    _send({
      'type': 'join_game',
      'gameId': gameId,
    });
  }

  /// Notifies the server that the player completed the puzzle.
  void notifyCompleted({
    required String gameId,
    required int score,
    required int time,
  }) {
    _send({
      'type': 'game_completed',
      'gameId': gameId,
      'score': score,
      'time': time,
    });
  }

  /// Notifies the server that the player lost (game over).
  void notifyGameOver({required String gameId}) {
    _send({
      'type': 'game_over',
      'gameId': gameId,
    });
  }

  /// Leaves the current game.
  void leaveGame({required String gameId}) {
    _send({
      'type': 'leave_game',
      'gameId': gameId,
    });
  }

  /// Requests a rematch in the current game room.
  void requestRematch({required String gameId}) {
    _send({
      'type': 'rematch',
      'gameId': gameId,
    });
  }

  /// Parses a game_list response into model objects.
  static List<MultiplayerGame> parseGameList(Map<String, dynamic> msg) {
    final games = msg['games'] as List<dynamic>? ?? [];
    return games
        .map((g) => MultiplayerGame.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
