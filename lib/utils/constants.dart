class AppConstants {
  static const String appName = 'Sudoku';
  static const int gridSize = 9;
  static const int boxSize = 3;
  static const int totalCells = 81;
  static const int baseScore = 10000;
  static const int mistakePenalty = 100;
  static const int hintPenalty = 150;
  static const int defaultMaxMistakes = 3;
  static const int defaultMaxHints = 3;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const String settingsKey = 'app_settings';
  static const String statisticsKey = 'game_statistics';
  static const String savedGameKey = 'saved_game';
}
