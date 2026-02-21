import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  // Map of all translations
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'ALINE SUDOKU',
      'newGame': 'New Game',
      'continue': 'Continue',
      'statistics': 'Statistics',
      'settings': 'Settings',
      'highScore': 'High Score',
      'selectDifficulty': 'Select Difficulty',
      'easy': 'Easy',
      'medium': 'Medium', 
      'hard': 'Hard',
      'expert': 'Expert',
      'easyDesc': '38-45 clues • Score ×1',
      'mediumDesc': '30-37 clues • Score ×1.5',
      'hardDesc': '25-29 clues • Score ×2',
      'expertDesc': '17-24 clues • Score ×3',
      'best': 'Best',
      'average': 'Average',
      'won': 'Won',
      'bestTime': 'Best',
      'undo': 'Undo',
      'erase': 'Erase',
      'notes': 'Notes',
      'hint': 'Hint',
      'mistakes': 'Mistakes',
      'score': 'Score',
      'time': 'Time',
      'difficulty': 'Difficulty',
      'paused': 'Paused',
      'resume': 'Resume',
      'exitGame': 'Exit game?',
      'exitGameMessage': 'Your progress will be saved.',
      'cancel': 'Cancel',
      'exit': 'Exit',
      'congratulations': 'Congratulations!',
      'puzzleSolved': 'You solved the puzzle!',
      'gameOver': 'Game Over',
      'tooManyMistakes': 'Too many mistakes',
      'playAgain': 'Play Again',
      'retry': 'Retry',
      'home': 'Home',
      // Statistics
      'played': 'Played',
      'winRate': 'Win Rate',
      'streak': 'Streak',
      'bestStreak': 'Best',
      'overall': 'Overall',
      'byDifficulty': 'By Difficulty',
      'resetStatistics': 'Reset Statistics',
      'resetConfirm': 'This will permanently erase all your statistics. Continue?',
      'reset': 'Reset',
      // Settings
      'appearance': 'Appearance',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'followSystemTheme': 'Follow System Theme',
      'accentColor': 'Accent Color',
      'gameplay': 'Gameplay',
      'soundEffects': 'Sound Effects',
      'hapticFeedback': 'Haptic Feedback',
      'showTimer': 'Show Timer',
      'mistakeLimit': 'Mistake Limit',
      'autoRemoveNotes': 'Auto-remove Notes',
      'highlightIdentical': 'Highlight Identical Numbers',
      'highlightConflicts': 'Highlight Conflicts',
      'language': 'Language',
      'english': 'English',
      'french': 'French',
      'wonGames': 'won',
      'generatingPuzzle': 'Generating puzzle…',
    },
    'fr': {
      'appTitle': 'ALINE SUDOKU',
      'newGame': 'Nouvelle Partie',
      'continue': 'Continuer',
      'statistics': 'Statistiques',
      'settings': 'Paramètres',
      'highScore': 'Meilleur Score',
      'selectDifficulty': 'Choisir la Difficulté',
      'easy': 'Facile',
      'medium': 'Moyen',
      'hard': 'Difficile',
      'expert': 'Expert',
      'easyDesc': '38-45 indices • Score ×1',
      'mediumDesc': '30-37 indices • Score ×1.5',
      'hardDesc': '25-29 indices • Score ×2',
      'expertDesc': '17-24 indices • Score ×3',
      'best': 'Meilleur',
      'average': 'Moyenne',
      'won': 'Gagné',
      'bestTime': 'Meilleur',
      'undo': 'Annuler',
      'erase': 'Effacer',
      'notes': 'Notes',
      'hint': 'Indice',
      'mistakes': 'Erreurs',
      'score': 'Score',
      'time': 'Temps',
      'difficulty': 'Difficulté',
      'paused': 'En Pause',
      'resume': 'Reprendre',
      'exitGame': 'Quitter la partie ?',
      'exitGameMessage': 'Votre progression sera sauvegardée.',
      'cancel': 'Annuler',
      'exit': 'Quitter',
      'congratulations': 'Félicitations !',
      'puzzleSolved': 'Vous avez résolu le puzzle !',
      'gameOver': 'Partie Terminée',
      'tooManyMistakes': 'Trop d\'erreurs',
      'playAgain': 'Rejouer',
      'retry': 'Réessayer',
      'home': 'Accueil',
      'played': 'Jouées',
      'winRate': 'Victoires',
      'streak': 'Série',
      'bestStreak': 'Record',
      'overall': 'Général',
      'byDifficulty': 'Par Difficulté',
      'resetStatistics': 'Réinitialiser les Statistiques',
      'resetConfirm': 'Cela effacera définitivement toutes vos statistiques. Continuer ?',
      'reset': 'Réinitialiser',
      'appearance': 'Apparence',
      'darkMode': 'Mode Sombre',
      'lightMode': 'Mode Clair',
      'followSystemTheme': 'Thème du Système',
      'accentColor': 'Couleur d\'Accent',
      'gameplay': 'Jeu',
      'soundEffects': 'Effets Sonores',
      'hapticFeedback': 'Retour Haptique',
      'showTimer': 'Afficher le Chrono',
      'mistakeLimit': 'Limite d\'Erreurs',
      'autoRemoveNotes': 'Suppr. Auto des Notes',
      'highlightIdentical': 'Surligner les Identiques',
      'highlightConflicts': 'Surligner les Conflits',
      'language': 'Langue',
      'english': 'Anglais',
      'french': 'Français',
      'wonGames': 'gagnées',
      'generatingPuzzle': 'Génération du puzzle…',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? key;
  }

  // Convenience getters for commonly used strings
  String get appTitle => get('appTitle');
  String get newGame => get('newGame');
  String get continueGame => get('continue');
  String get statistics => get('statistics');
  String get settings => get('settings');
  String get highScore => get('highScore');
  String get selectDifficulty => get('selectDifficulty');
  String get easy => get('easy');
  String get medium => get('medium');
  String get hard => get('hard');
  String get expert => get('expert');
  String get easyDesc => get('easyDesc');
  String get mediumDesc => get('mediumDesc');
  String get hardDesc => get('hardDesc');
  String get expertDesc => get('expertDesc');
  String get bestLabel => get('best');
  String get average => get('average');
  String get won => get('won');
  String get bestTime => get('bestTime');
  String get undo => get('undo');
  String get erase => get('erase');
  String get notes => get('notes');
  String get hint => get('hint');
  String get mistakes => get('mistakes');
  String get score => get('score');
  String get time => get('time');
  String get difficulty => get('difficulty');
  String get paused => get('paused');
  String get resume => get('resume');
  String get exitGame => get('exitGame');
  String get exitGameMessage => get('exitGameMessage');
  String get cancel => get('cancel');
  String get exit => get('exit');
  String get congratulations => get('congratulations');
  String get puzzleSolved => get('puzzleSolved');
  String get gameOver => get('gameOver');
  String get tooManyMistakes => get('tooManyMistakes');
  String get playAgain => get('playAgain');
  String get retry => get('retry');
  String get home => get('home');
  String get played => get('played');
  String get winRate => get('winRate');
  String get streak => get('streak');
  String get bestStreak => get('bestStreak');
  String get overall => get('overall');
  String get byDifficulty => get('byDifficulty');
  String get resetStatistics => get('resetStatistics');
  String get resetConfirm => get('resetConfirm');
  String get reset => get('reset');
  String get appearance => get('appearance');
  String get darkMode => get('darkMode');
  String get lightMode => get('lightMode');
  String get followSystemTheme => get('followSystemTheme');
  String get accentColor => get('accentColor');
  String get gameplay => get('gameplay');
  String get soundEffects => get('soundEffects');
  String get hapticFeedback => get('hapticFeedback');
  String get showTimer => get('showTimer');
  String get mistakeLimit => get('mistakeLimit');
  String get autoRemoveNotes => get('autoRemoveNotes');
  String get highlightIdentical => get('highlightIdentical');
  String get highlightConflicts => get('highlightConflicts');
  String get language => get('language');
  String get english => get('english');
  String get french => get('french');
  String get wonGames => get('wonGames');
  String get generatingPuzzle => get('generatingPuzzle');

  String difficultyName(String key) {
    switch (key) {
      case 'Easy': return easy;
      case 'Medium': return medium;
      case 'Hard': return hard;
      case 'Expert': return expert;
      default: return key;
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
