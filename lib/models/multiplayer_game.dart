/// Data model for a multiplayer game room (used in lobby listing).
class MultiplayerGame {
  final String gameId;
  final String mode;
  final String difficulty;
  final String createdAt;

  MultiplayerGame({
    required this.gameId,
    required this.mode,
    required this.difficulty,
    required this.createdAt,
  });

  factory MultiplayerGame.fromJson(Map<String, dynamic> json) {
    return MultiplayerGame(
      gameId: json['gameId'] as String,
      mode: json['mode'] as String,
      difficulty: json['difficulty'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
