/// Sudoku multiplayer WebSocket server.
///
/// Run with: dart run bin/server.dart
/// Listens on 0.0.0.0:8080
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

// ---------------------------------------------------------------------------
// Puzzle generator (standalone, no Flutter dependency)
// ---------------------------------------------------------------------------

final _random = Random();

bool _isValidPlacement(List<List<int>> board, int row, int col, int num) {
  for (int c = 0; c < 9; c++) {
    if (c != col && board[row][c] == num) return false;
  }
  for (int r = 0; r < 9; r++) {
    if (r != row && board[r][col] == num) return false;
  }
  final boxRow = (row ~/ 3) * 3;
  final boxCol = (col ~/ 3) * 3;
  for (int r = boxRow; r < boxRow + 3; r++) {
    for (int c = boxCol; c < boxCol + 3; c++) {
      if (r != row && c != col && board[r][c] == num) return false;
    }
  }
  return true;
}

(int, int)? _findEmpty(List<List<int>> board) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] == 0) return (r, c);
    }
  }
  return null;
}

bool _fillBoard(List<List<int>> board) {
  final empty = _findEmpty(board);
  if (empty == null) return true;
  final (row, col) = empty;
  final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
  for (final num in numbers) {
    if (_isValidPlacement(board, row, col, num)) {
      board[row][col] = num;
      if (_fillBoard(board)) return true;
      board[row][col] = 0;
    }
  }
  return false;
}

int _countSolutions(List<List<int>> board, int maxCount, int found) {
  final empty = _findEmpty(board);
  if (empty == null) return found + 1;
  final (row, col) = empty;
  for (int num = 1; num <= 9; num++) {
    if (!_isValidPlacement(board, row, col, num)) continue;
    board[row][col] = num;
    found = _countSolutions(board, maxCount, found);
    board[row][col] = 0;
    if (found >= maxCount) return found;
  }
  return found;
}

bool _hasUniqueSolution(List<List<int>> board) {
  final copy = [for (final row in board) [...row]];
  return _countSolutions(copy, 2, 0) == 1;
}

Map<String, dynamic> generatePuzzle(String difficulty) {
  final board = List.generate(9, (_) => List.filled(9, 0));
  _fillBoard(board);
  final solution = [for (final row in board) [...row]];
  final puzzle = [for (final row in board) [...row]];

  int minClues, maxClues;
  switch (difficulty) {
    case 'easy':
      minClues = 38;
      maxClues = 45;
    case 'medium':
      minClues = 30;
      maxClues = 37;
    case 'hard':
      minClues = 25;
      maxClues = 29;
    case 'expert':
      minClues = 17;
      maxClues = 24;
    default:
      minClues = 38;
      maxClues = 45;
  }

  final targetClues = minClues + _random.nextInt(maxClues - minClues + 1);

  final positions = <(int, int)>[
    for (int r = 0; r < 9; r++)
      for (int c = 0; c < 9; c++) (r, c),
  ];
  for (int i = positions.length - 1; i > 0; i--) {
    final j = _random.nextInt(i + 1);
    final temp = positions[i];
    positions[i] = positions[j];
    positions[j] = temp;
  }

  var currentClues = 81;
  for (final (row, col) in positions) {
    if (currentClues <= targetClues) break;
    final saved = puzzle[row][col];
    if (saved == 0) continue;
    puzzle[row][col] = 0;
    if (_hasUniqueSolution(puzzle)) {
      currentClues--;
    } else {
      puzzle[row][col] = saved;
    }
  }

  return {
    'puzzle': puzzle,
    'solution': solution,
    'difficulty': difficulty,
  };
}

// ---------------------------------------------------------------------------
// Game room model
// ---------------------------------------------------------------------------

class PlayerConnection {
  final WebSocket socket;
  final String playerId;

  PlayerConnection(this.socket, this.playerId);
}

class GameRoom {
  final String gameId;
  final String mode;
  final String difficulty;
  final Map<String, dynamic> puzzleData;
  final DateTime createdAt;

  PlayerConnection? host;
  PlayerConnection? guest;

  String? winnerId;
  bool isFinished = false;
  final Set<String> rematchRequested = {};

  GameRoom({
    required this.gameId,
    required this.mode,
    required this.difficulty,
    required this.puzzleData,
  }) : createdAt = DateTime.now();

  bool get isFull => host != null && guest != null;
  bool get isWaiting => host != null && guest == null && !isFinished;

  Map<String, dynamic> toListEntry() => {
        'gameId': gameId,
        'mode': mode,
        'difficulty': difficulty,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ---------------------------------------------------------------------------
// Server
// ---------------------------------------------------------------------------

final Map<String, GameRoom> _rooms = {};
int _nextId = 1;

String _generateGameId() => 'game_${_nextId++}';

void _send(WebSocket socket, Map<String, dynamic> message) {
  try {
    socket.add(jsonEncode(message));
  } catch (_) {}
}

void _handleConnection(WebSocket socket) {
  final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  String? currentGameId;

  print('[$playerId] connected');

  socket.listen(
    (data) {
      if (data is! String) return;

      late final Map<String, dynamic> msg;
      try {
        msg = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return;
      }

      final type = msg['type'] as String?;
      if (type == null) return;

      switch (type) {
        // ---------------- Create Game ----------------
        case 'create_game':
          final mode = msg['mode'] as String? ?? 'battle';
          final difficulty = msg['difficulty'] as String? ?? 'easy';

          print('[$playerId] creating $mode game ($difficulty)');

          final puzzleData = generatePuzzle(difficulty);
          final gameId = _generateGameId();

          final room = GameRoom(
            gameId: gameId,
            mode: mode,
            difficulty: difficulty,
            puzzleData: puzzleData,
          );
          room.host = PlayerConnection(socket, playerId);
          _rooms[gameId] = room;
          currentGameId = gameId;

          _send(socket, {
            'type': 'game_created',
            'gameId': gameId,
          });

        // ---------------- List Games ----------------
        case 'list_games':
          final mode = msg['mode'] as String? ?? 'battle';
          final games = _rooms.values
              .where((r) => r.mode == mode && r.isWaiting)
              .map((r) => r.toListEntry())
              .toList();

          _send(socket, {
            'type': 'game_list',
            'games': games,
          });

        // ---------------- Join Game ----------------
        case 'join_game':
          final gameId = msg['gameId'] as String?;
          if (gameId == null) {
            _send(socket, {'type': 'error', 'message': 'Missing gameId'});
            break;
          }

          final room = _rooms[gameId];
          if (room == null) {
            _send(socket, {'type': 'error', 'message': 'Game not found'});
            break;
          }
          if (room.isFull) {
            _send(socket, {'type': 'error', 'message': 'Game is full'});
            break;
          }
          if (room.isFinished) {
            _send(socket, {'type': 'error', 'message': 'Game already finished'});
            break;
          }

          room.guest = PlayerConnection(socket, playerId);
          currentGameId = gameId;

          print('[$playerId] joined game $gameId');

          // Send game_start to both players with the puzzle
          final startMsg = {
            'type': 'game_start',
            'gameId': gameId,
            'puzzle': room.puzzleData['puzzle'],
            'solution': room.puzzleData['solution'],
            'difficulty': room.difficulty,
          };

          _send(room.host!.socket, startMsg);
          _send(room.guest!.socket, startMsg);

        // -------------- Game Completed ---------------
        case 'game_completed':
          final gameId = msg['gameId'] as String?;
          if (gameId == null) break;

          final room = _rooms[gameId];
          if (room == null || room.isFinished) break;

          final score = msg['score'] as int? ?? 0;
          final time = msg['time'] as int? ?? 0;

          room.isFinished = true;
          room.winnerId = playerId;

          print('[$playerId] completed game $gameId (score: $score, time: $time)');

          // Notify the opponent
          final opponent = room.host?.playerId == playerId
              ? room.guest
              : room.host;

          if (opponent != null) {
            _send(opponent.socket, {
              'type': 'opponent_completed',
              'score': score,
              'time': time,
            });
          }

        // -------------- Game Over (lost) ---------------
        case 'game_over':
          final gameId = msg['gameId'] as String?;
          if (gameId == null) break;

          final room = _rooms[gameId];
          if (room == null || room.isFinished) break;

          print('[$playerId] game over in $gameId');

          // Notify the opponent that this player lost
          final opponent = room.host?.playerId == playerId
              ? room.guest
              : room.host;

          if (opponent != null) {
            _send(opponent.socket, {
              'type': 'opponent_game_over',
            });
          }

        // -------------- Rematch ---------------
        case 'rematch':
          final gameId = msg['gameId'] as String?;
          if (gameId == null) break;

          final room = _rooms[gameId];
          if (room == null) break;

          room.rematchRequested.add(playerId);
          print('[$playerId] requested rematch in $gameId (${room.rematchRequested.length}/2)');

          // Tell the requester they are waiting
          _send(socket, {'type': 'rematch_waiting'});

          // If both players want a rematch, start a new game in the same room
          if (room.rematchRequested.length >= 2 &&
              room.host != null &&
              room.guest != null) {
            final newPuzzle = generatePuzzle(room.difficulty);
            room.rematchRequested.clear();
            room.isFinished = false;
            room.winnerId = null;
            // Update puzzle data in-place (puzzleData is final Map, replace entries)
            room.puzzleData
              ..['puzzle'] = newPuzzle['puzzle']
              ..['solution'] = newPuzzle['solution'];

            final startMsg = {
              'type': 'game_start',
              'gameId': gameId,
              'puzzle': newPuzzle['puzzle'],
              'solution': newPuzzle['solution'],
              'difficulty': room.difficulty,
            };

            print('[Server] Rematch starting in $gameId');
            _send(room.host!.socket, startMsg);
            _send(room.guest!.socket, startMsg);
          }

        // -------------- Leave Game ---------------
        case 'leave_game':
          final gameId = msg['gameId'] as String?;
          if (gameId == null) break;

          final room = _rooms[gameId];
          if (room == null) break;

          print('[$playerId] left game $gameId');

          // Notify opponent
          final opponent = room.host?.playerId == playerId
              ? room.guest
              : room.host;

          if (opponent != null) {
            _send(opponent.socket, {
              'type': 'opponent_left',
            });
          }

          // Clean up room if not finished
          if (!room.isFinished) {
            room.isFinished = true;
          }
          currentGameId = null;
      }
    },
    onDone: () {
      print('[$playerId] disconnected');

      // Handle disconnect: notify opponent if in a game
      if (currentGameId != null) {
        final room = _rooms[currentGameId];
        if (room != null && !room.isFinished) {
          room.isFinished = true;
          final opponent = room.host?.playerId == playerId
              ? room.guest
              : room.host;
          if (opponent != null) {
            _send(opponent.socket, {'type': 'opponent_left'});
          }
        }
      }

      // Clean up empty waiting rooms created by this player
      _rooms.removeWhere((id, r) =>
          r.host?.playerId == playerId && r.guest == null && !r.isFinished);
    },
    onError: (error) {
      print('[$playerId] error: $error');
    },
  );
}

Future<void> main() async {
  final server = await HttpServer.bind('0.0.0.0', 8080);
  print('Sudoku multiplayer server running on ws://0.0.0.0:8080');

  await for (final request in server) {
    print('Incoming request from ${request.connectionInfo?.remoteAddress.address}:'
        '${request.connectionInfo?.remotePort}'
        ' ${request.method} ${request.uri}'
        ' isUpgrade=${WebSocketTransformer.isUpgradeRequest(request)}');
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        print('  -> WebSocket upgraded OK');
        _handleConnection(socket);
      } catch (e) {
        print('  -> WebSocket upgrade FAILED: $e');
      }
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('WebSocket connections only')
        ..close();
    }
  }
}
