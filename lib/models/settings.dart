class AppSettings {
  final bool isDarkMode;
  final bool followSystem;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool showTimer;
  final int mistakeLimit; // 3, 5, or -1 for unlimited
  final bool autoRemoveNotes;
  final bool highlightIdentical;
  final bool highlightConflicts;
  final int accentColorIndex;
  final String locale; // 'en' or 'fr'

  AppSettings({
    this.isDarkMode = false,
    this.followSystem = true,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.showTimer = true,
    this.mistakeLimit = 3,
    this.autoRemoveNotes = true,
    this.highlightIdentical = true,
    this.highlightConflicts = true,
    this.accentColorIndex = 0,
    this.locale = 'en',
  });

  AppSettings copyWith({
    bool? isDarkMode,
    bool? followSystem,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? showTimer,
    int? mistakeLimit,
    bool? autoRemoveNotes,
    bool? highlightIdentical,
    bool? highlightConflicts,
    int? accentColorIndex,
    String? locale,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      followSystem: followSystem ?? this.followSystem,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      showTimer: showTimer ?? this.showTimer,
      mistakeLimit: mistakeLimit ?? this.mistakeLimit,
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      highlightIdentical: highlightIdentical ?? this.highlightIdentical,
      highlightConflicts: highlightConflicts ?? this.highlightConflicts,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'followSystem': followSystem,
        'soundEnabled': soundEnabled,
        'hapticEnabled': hapticEnabled,
        'showTimer': showTimer,
        'mistakeLimit': mistakeLimit,
        'autoRemoveNotes': autoRemoveNotes,
        'highlightIdentical': highlightIdentical,
        'highlightConflicts': highlightConflicts,
        'accentColorIndex': accentColorIndex,
        'locale': locale,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      followSystem: json['followSystem'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      hapticEnabled: json['hapticEnabled'] ?? true,
      showTimer: json['showTimer'] ?? true,
      mistakeLimit: json['mistakeLimit'] ?? 3,
      autoRemoveNotes: json['autoRemoveNotes'] ?? true,
      highlightIdentical: json['highlightIdentical'] ?? true,
      highlightConflicts: json['highlightConflicts'] ?? true,
      accentColorIndex: json['accentColorIndex'] ?? 0,
      locale: json['locale'] ?? 'en',
    );
  }
}

class GameStatistics {
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int bestStreak;
  final Map<String, int> bestTimes; // difficulty -> seconds
  final Map<String, int> totalTimes;
  final Map<String, int> gamesPerDifficulty;
  final Map<String, int> winsPerDifficulty;
  final int totalMistakes;
  final int totalHintsUsed;
  final int highScore;

  GameStatistics({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    Map<String, int>? bestTimes,
    Map<String, int>? totalTimes,
    Map<String, int>? gamesPerDifficulty,
    Map<String, int>? winsPerDifficulty,
    this.totalMistakes = 0,
    this.totalHintsUsed = 0,
    this.highScore = 0,
  })  : bestTimes = bestTimes ?? {},
        totalTimes = totalTimes ?? {},
        gamesPerDifficulty = gamesPerDifficulty ?? {},
        winsPerDifficulty = winsPerDifficulty ?? {};

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;

  int? bestTimeForDifficulty(String difficulty) => bestTimes[difficulty];

  int averageTimeForDifficulty(String difficulty) {
    final total = totalTimes[difficulty] ?? 0;
    final games = winsPerDifficulty[difficulty] ?? 0;
    return games > 0 ? total ~/ games : 0;
  }

  GameStatistics copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? currentStreak,
    int? bestStreak,
    Map<String, int>? bestTimes,
    Map<String, int>? totalTimes,
    Map<String, int>? gamesPerDifficulty,
    Map<String, int>? winsPerDifficulty,
    int? totalMistakes,
    int? totalHintsUsed,
    int? highScore,
  }) {
    return GameStatistics(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bestTimes: bestTimes ?? Map.from(this.bestTimes),
      totalTimes: totalTimes ?? Map.from(this.totalTimes),
      gamesPerDifficulty:
          gamesPerDifficulty ?? Map.from(this.gamesPerDifficulty),
      winsPerDifficulty:
          winsPerDifficulty ?? Map.from(this.winsPerDifficulty),
      totalMistakes: totalMistakes ?? this.totalMistakes,
      totalHintsUsed: totalHintsUsed ?? this.totalHintsUsed,
      highScore: highScore ?? this.highScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'bestTimes': bestTimes,
        'totalTimes': totalTimes,
        'gamesPerDifficulty': gamesPerDifficulty,
        'winsPerDifficulty': winsPerDifficulty,
        'totalMistakes': totalMistakes,
        'totalHintsUsed': totalHintsUsed,
        'highScore': highScore,
      };

  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      bestTimes: Map<String, int>.from(json['bestTimes'] ?? {}),
      totalTimes: Map<String, int>.from(json['totalTimes'] ?? {}),
      gamesPerDifficulty:
          Map<String, int>.from(json['gamesPerDifficulty'] ?? {}),
      winsPerDifficulty:
          Map<String, int>.from(json['winsPerDifficulty'] ?? {}),
      totalMistakes: json['totalMistakes'] ?? 0,
      totalHintsUsed: json['totalHintsUsed'] ?? 0,
      highScore: json['highScore'] ?? 0,
    );
  }
}
