import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sudoku_app/models/settings.dart';
import 'package:sudoku_app/utils/constants.dart';

class StorageService {
  static const String _settingsBox = 'settings';
  static const String _gameBox = 'game';
  static const String _statsBox = 'statistics';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_gameBox);
    await Hive.openBox(_statsBox);
  }

  // Settings
  static Future<void> saveSettings(AppSettings settings) async {
    final box = Hive.box(_settingsBox);
    await box.put(AppConstants.settingsKey, jsonEncode(settings.toJson()));
  }

  static AppSettings loadSettings() {
    final box = Hive.box(_settingsBox);
    final json = box.get(AppConstants.settingsKey);
    if (json != null) {
      return AppSettings.fromJson(jsonDecode(json));
    }
    return AppSettings();
  }

  // Statistics
  static Future<void> saveStatistics(GameStatistics stats) async {
    final box = Hive.box(_statsBox);
    await box.put(AppConstants.statisticsKey, jsonEncode(stats.toJson()));
  }

  static GameStatistics loadStatistics() {
    final box = Hive.box(_statsBox);
    final json = box.get(AppConstants.statisticsKey);
    if (json != null) {
      return GameStatistics.fromJson(jsonDecode(json));
    }
    return GameStatistics();
  }

  // Saved Game (store as JSON map with board state, game state, etc.)
  static Future<void> saveGame({
    required List<List<int>> boardValues,
    required List<List<int>> solution,
    required List<List<Set<int>>> notes,
    required List<List<bool>> givenCells,
    required String difficulty,
    required int mistakes,
    required int hintsUsed,
    required int elapsedSeconds,
  }) async {
    final box = Hive.box(_gameBox);
    final data = {
      'boardValues': boardValues.map((r) => r.toList()).toList(),
      'solution': solution.map((r) => r.toList()).toList(),
      'notes': notes.map((r) => r.map((s) => s.toList()).toList()).toList(),
      'givenCells': givenCells.map((r) => r.toList()).toList(),
      'difficulty': difficulty,
      'mistakes': mistakes,
      'hintsUsed': hintsUsed,
      'elapsedSeconds': elapsedSeconds,
    };
    await box.put(AppConstants.savedGameKey, jsonEncode(data));
  }

  static Map<String, dynamic>? loadSavedGame() {
    final box = Hive.box(_gameBox);
    final json = box.get(AppConstants.savedGameKey);
    if (json != null) {
      return jsonDecode(json);
    }
    return null;
  }

  static Future<void> deleteSavedGame() async {
    final box = Hive.box(_gameBox);
    await box.delete(AppConstants.savedGameKey);
  }

  static bool hasSavedGame() {
    final box = Hive.box(_gameBox);
    return box.containsKey(AppConstants.savedGameKey);
  }
}
